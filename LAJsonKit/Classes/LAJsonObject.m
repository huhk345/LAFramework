//
//  LAJsonObject.m
//  Pods
//
//  Created by LakeR on 16/7/26.
//
//

#import "LAJsonObject.h"
#import "NSDictionary+LAJson.h"
#import "JSONModelClassProperty.h"
#import "LAPropertyAnnotation.h"
#import "JSONValueTransformer.h"
#import <objc/Runtime.h>

static const NSString * kClassPropertiesKey = @"kClassPropertiesKey";
static const NSString * kMapperObjectKey = @"kMapperObjectKey";


#pragma mark - class static variables
static NSArray* allowedJSONTypes = nil;
static NSArray* allowedPrimitiveTypes = nil;
static NSArray* containerTypes = nil;
static NSDictionary *primitivesNames = nil;
static JSONValueTransformer* valueTransformer = nil;

@implementation LAJsonObject

+(void)load
{
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        // initialize all class static objects,
        // which are common for ALL JSONModel subclasses
        
        @autoreleasepool {
            allowedJSONTypes = @[
                                 [NSString class], [NSNumber class], [NSDecimalNumber class], [NSArray class], [NSDictionary class], [NSNull class], [NSSet class], //immutable JSON classes
                                 [NSMutableString class], [NSMutableArray class], [NSMutableDictionary class], [NSMutableSet set] //mutable JSON classes
                                 ];
            containerTypes = @[[NSArray class], [NSDictionary class], [NSSet class],[NSMutableArray class], [NSMutableDictionary class], [NSMutableSet set] ];
            
            
            allowedPrimitiveTypes = @[
                                      @"BOOL", @"float", @"int", @"long", @"double", @"short",
                                      //and some famous aliases
                                      @"NSInteger", @"NSUInteger",
                                      @"Block"
                                      ];
            
            
            primitivesNames = @{@"f":@"float", @"i":@"int", @"d":@"double", @"l":@"long", @"c":@"BOOL", @"s":@"short", @"q":@"long",
                                 //and some famous aliases of primitive types
                                 // BOOL is now "B" on iOS __LP64 builds
                                 @"I":@"NSInteger", @"Q":@"NSUInteger", @"B":@"BOOL",
                                 
                                 @"@?":@"Block"};
            
            valueTransformer = [[JSONValueTransformer alloc] init];
        }
    });
}




#pragma mark - LAReformatter delegate methods
-(void)convertFromDictionary:(NSDictionary *)dictionary{
    
}



#pragma mark - LAObjectConverter delegate methods
-(NSString *)convertToString:(NSError **)error{
    NSDictionary *dic = [self convertToDictionary:error];
    if (!error) {
        return [dic jsonString];
    }
    return nil;
}


-(NSDictionary *)convertToDictionary:(NSError **)error{
    NSDictionary *result = nil;
    @try {
        result = [self toDictionaryWithKeys:nil];
    } @catch (NSException *exception) {
        *error = [[NSError alloc] initWithDomain:exception.name code:-1 userInfo:exception.userInfo];
    }
    return result;
}





#pragma mark - JSON private methods
//exports the model as a dictionary of JSON compliant objects
-(NSDictionary*)toDictionaryWithKeys:(NSArray*)propertyNames{
    NSArray* properties = [self __properties__];
    NSMutableDictionary* tempDictionary = [NSMutableDictionary dictionaryWithCapacity:properties.count];
    
    id value;
    
    //loop over all properties
    for (JSONModelClassProperty* p in properties) {
        
        //skip if unwanted
        if (propertyNames != nil && ![propertyNames containsObject:p.name])
            continue;
        
        //fetch key and value
        NSString* keyPath = [self __mapString:p.name];
        value = [self valueForKey: p.name];
        
        //JMLog(@"toDictionary[%@]->[%@] = '%@'", p.name, keyPath, value);
        
        if ([keyPath rangeOfString:@"."].location != NSNotFound) {
            //there are sub-keys, introduce dictionaries for them
            [self __createDictionariesForKeyPath:keyPath inDictionary:&tempDictionary];
        }
        
        //check for custom getter
        if ([self __customGetValue:&value forProperty:p]) {
            //custom getter, all done
            [tempDictionary setValue:value forKeyPath:keyPath];
            continue;
        }
        
        //export nil when they are not optional values as JSON null, so that the structure of the exported data
        //is still valid if it's to be imported as a model again
        if (isNull(value)) {
            if (value == nil && objc_getAssociatedObject(self.class, &kMapperObjectKey)[[NSString stringWithFormat:@"__Class__%@", NSStringFromClass([self class])]]){
                [tempDictionary removeObjectForKey:keyPath];
            }
            else{
                [tempDictionary setValue:[NSNull null] forKeyPath:keyPath];
            }
            continue;
        }
        
        LAPropertyAnnotation *annotation = objc_getAssociatedObject(self.class, &kMapperObjectKey)[p.name];
        
        //check if the property is another model
        if ([value isKindOfClass:[LAJsonObject class]]) {
            
            //recurse models
            value = [(LAJsonObject*)value convertToDictionary:nil];
            [tempDictionary setValue:value forKeyPath: keyPath];
            
            //for clarity
            continue;
            
        } else {
            // 1) check for built-in transformation
            if (annotation.reformatter && p.type && [containerTypes containsObject:p.type]) {
                value = [self __reverseTransform:value
                               withTypeReference:annotation.typeReference];
            }
            
            // 2) check for standard types OR 2.1) primitives
            if (p.structName==nil && (p.isStandardJSONType || p.type==nil)) {
                
                //generic get value
                [tempDictionary setValue:value forKeyPath: keyPath];
                
                continue;
            }

            
            // 3) try to apply a value transformer
            //create selector from the property's class name
            NSString* selectorName = [NSString stringWithFormat:@"%@From%@:", @"JSONObject", p.type?p.type:p.structName];
            if ([annotation.reformatter length]) {
                selectorName = annotation.reformatter;
            }
            SEL selector = NSSelectorFromString(selectorName);
            
            BOOL foundCustomTransformer = NO;
            if ([valueTransformer respondsToSelector:selector]) {
                foundCustomTransformer = YES;
            } else {
                //try for hidden transformer
                selectorName = [NSString stringWithFormat:@"__%@",selectorName];
                selector = NSSelectorFromString(selectorName);
                if ([valueTransformer respondsToSelector:selector]) {
                    foundCustomTransformer = YES;
                }
            }
            
            //check if there's a transformer declared
            if (foundCustomTransformer) {
                
                //it's OK, believe me...
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                value = [valueTransformer performSelector:selector withObject:value];
#pragma clang diagnostic pop
                
                [tempDictionary setValue:value forKeyPath: keyPath];
                
            } else {
                
                //in this case most probably a custom property was defined in a model
                //but no default reverse transformer for it
                @throw [NSException exceptionWithName:@"Value transformer not found"
                                               reason:[NSString stringWithFormat:@"[JSONValueTransformer %@] not found", selectorName]
                                             userInfo:nil];
                return nil;
            }
        }
    }
    
    return [tempDictionary copy];
}


//returns a list of the model's properties
-(NSArray*)__properties__{
    //fetch the associated object
    NSDictionary* classProperties = objc_getAssociatedObject(self.class, &kClassPropertiesKey);
    if (classProperties) return [classProperties allValues];
    
    //if here, the class needs to inspect itself
    [self __setup__];
    
    //return the property list
    classProperties = objc_getAssociatedObject(self.class, &kClassPropertiesKey);
    return [classProperties allValues];
}


-(void)__setup__{
    //if first instance of this model, generate the property list
    if (!objc_getAssociatedObject(self.class, &kClassPropertiesKey)) {
        [self __inspectProperties];
    }
    
    //if there's a custom key mapper, store it in the associated object
    NSDictionary *mapper = [self __propertiesAnnotations];
    if ( mapper && !objc_getAssociatedObject(self.class, &kMapperObjectKey) ) {
        objc_setAssociatedObject(
                                 self.class,
                                 &kMapperObjectKey,
                                 mapper,
                                 OBJC_ASSOCIATION_RETAIN // This is atomic
                                 );
    }
}


-(NSDictionary *)__propertiesAnnotations{
    NSURL* url = [[NSBundle mainBundle] URLForResource:NSStringFromClass([self class]) withExtension:@"lajson"];
    if (url != nil) {
        NSDictionary* jsonDict = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfURL:url] options:0 error:nil];
        NSMutableDictionary* result = [[NSMutableDictionary alloc] init];
        
        for (NSString* key in jsonDict) {
            result[key] = [[LAPropertyAnnotation alloc] initWithDictionary:jsonDict[key]];
        }
        return result;

    }else{
        return nil;
    }
}

//inspects the class, get's a list of the class properties
-(void)__inspectProperties
{
    //JMLog(@"Inspect class: %@", [self class]);
    
    NSMutableDictionary* propertyIndex = [NSMutableDictionary dictionary];
    
    //temp variables for the loops
    Class class = [self class];
    NSScanner* scanner = nil;
    NSString* propertyType = nil;
    
    // inspect inherited properties up to the JSONModel class
    while (class != [LAJsonObject class]) {
        //JMLog(@"inspecting: %@", NSStringFromClass(class));
        
        unsigned int propertyCount;
        objc_property_t *properties = class_copyPropertyList(class, &propertyCount);
        
        //loop over the class properties
        for (unsigned int i = 0; i < propertyCount; i++) {
            
            JSONModelClassProperty* p = [[JSONModelClassProperty alloc] init];
            
            //get property name
            objc_property_t property = properties[i];
            const char *propertyName = property_getName(property);
            p.name = @(propertyName);
            
            //JMLog(@"property: %@", p.name);
            
            //get property attributes
            const char *attrs = property_getAttributes(property);
            NSString* propertyAttributes = @(attrs);
            NSArray* attributeItems = [propertyAttributes componentsSeparatedByString:@","];
            
            //ignore read-only properties
            if ([attributeItems containsObject:@"R"]) {
                continue; //to next property
            }
            
            //check for 64b BOOLs
            if ([propertyAttributes hasPrefix:@"Tc,"]) {
                //mask BOOLs as structs so they can have custom converters
                p.structName = @"BOOL";
            }
            
            scanner = [NSScanner scannerWithString: propertyAttributes];
            
            //JMLog(@"attr: %@", [NSString stringWithCString:attrs encoding:NSUTF8StringEncoding]);
            [scanner scanUpToString:@"T" intoString: nil];
            [scanner scanString:@"T" intoString:nil];
            
            //check if the property is an instance of a class
            if ([scanner scanString:@"@\"" intoString: &propertyType]) {
                
                [scanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"\"<"]
                                        intoString:&propertyType];
                
                //JMLog(@"type: %@", propertyClassName);
                p.type = NSClassFromString(propertyType);
                p.isMutable = ([propertyType rangeOfString:@"Mutable"].location != NSNotFound);
                p.isStandardJSONType = [allowedJSONTypes containsObject:p.type];
                
            }
            //check if the property is a structure
            else if ([scanner scanString:@"{" intoString: &propertyType]) {
                [scanner scanCharactersFromSet:[NSCharacterSet alphanumericCharacterSet]
                                    intoString:&propertyType];
                
                p.isStandardJSONType = NO;
                p.structName = propertyType;
                
            }
            else {
                
                //the property contains a primitive data type
                [scanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@","]
                                        intoString:&propertyType];
                
                //get the full name of the primitive type
                propertyType = primitivesNames[propertyType];
                
                if (![allowedPrimitiveTypes containsObject:propertyType]) {
                    
                    //type not allowed - programmer mistaken -> exception
                    @throw [NSException exceptionWithName:@"JSONModelProperty type not allowed"
                                                   reason:[NSString stringWithFormat:@"Property type of %@.%@ is not supported by JSONModel.", self.class, p.name]
                                                 userInfo:nil];
                }
                
            }
            
            NSString *nsPropertyName = @(propertyName);
            
            //few cases where JSONModel will ignore properties automatically
            if ([propertyType isEqualToString:@"Block"]) {
                p = nil;
            }
            
            //add the property object to the temp index
            if (p && ![propertyIndex objectForKey:p.name]) {
                [propertyIndex setValue:p forKey:p.name];
            }
        }
        
        free(properties);
        
        //ascend to the super of the class
        //(will do that until it reaches the root class - JSONModel)
        class = [class superclass];
    }
    
    //finally store the property index in the static property index
    objc_setAssociatedObject(
                             self.class,
                             &kClassPropertiesKey,
                             [propertyIndex copy],
                             OBJC_ASSOCIATION_RETAIN // This is atomic
                             );
}


-(NSString*)__mapString:(NSString*)key{
    NSDictionary *mapper = objc_getAssociatedObject(self.class, &kMapperObjectKey);
    LAPropertyAnnotation *annotation = mapper[key];
    if([annotation.property length] > 0)
        return annotation.property;
    return key;
}


-(BOOL)__customGetValue:(id<NSObject>*)value forProperty:(JSONModelClassProperty*)property{
    if (property.getterType == kNotInspected) {
        //check for a custom property getter method
        NSString* ucfirstName = [property.name stringByReplacingCharactersInRange: NSMakeRange(0,1)
                                                                       withString: [[property.name substringToIndex:1] uppercaseString]];
        NSString* selectorName = [NSString stringWithFormat:@"JSONObjectFor%@", ucfirstName];
        
        SEL customPropertyGetter = NSSelectorFromString(selectorName);
        if (![self respondsToSelector: customPropertyGetter]) {
            property.getterType = kNo;
            return NO;
        }
        
        property.getterType = kCustom;
        property.customGetter = customPropertyGetter;
        
    }
    
    if (property.getterType==kCustom) {
        //call the custom getter
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        *value = [self performSelector:property.customGetter];
#pragma clang diagnostic pop
        return YES;
    }
    
    return NO;
}

//built-in reverse transformations (export to JSON compliant objects)
-(id)__reverseTransform:(id)value
      withTypeReference:(NSString *)typeReference{
    
    
    Class protocolClass = NSClassFromString(typeReference);
    if (!protocolClass) return value;

    //if the protocol is actually a JSONModel class
    if ([protocolClass isSubclassOfClass: [LAJsonObject class]]) {
        //check if should export list of dictionaries
        if ([value isKindOfClass:[NSArray class]] || [value isKindOfClass:[NSSet class]]) {
            NSMutableArray* tempArray = [NSMutableArray arrayWithCapacity: [(NSArray*)value count] ];
            for (id model in value) {
                if([model conformsToProtocol:@protocol(LAObjectConverter)]){
                    if ([model respondsToSelector:@selector(convertToDictionary:)]) {
                        [tempArray addObject: [model convertToDictionary:nil]];
                    }
                    else{
                        [tempArray addObject: model];
                    }
                }else if([containerTypes containsObject:[model class]]){
                    [tempArray addObject:[self __reverseTransform:model withTypeReference:typeReference]];
                }
            }
            return [tempArray copy];
        }
        
        //check if should export dictionary of dictionaries
        if ([value isKindOfClass:[NSDictionary class]]) {
            NSMutableDictionary* res = [NSMutableDictionary dictionary];
            for (NSString* key in [(NSDictionary*)value allKeys]) {
                id model = value[key];
                if ([model conformsToProtocol:@protocol(LAObjectConverter)]) {
                    [res setValue: [model convertToDictionary:nil] forKey: key];
                }
                else{
                    [res setValue:[self __reverseTransform:model withTypeReference:typeReference] forKey:key];
                }

            }
            return [NSDictionary dictionaryWithDictionary:res];
        }
    }
    
    return value;
}



#pragma mark - persistance
-(void)__createDictionariesForKeyPath:(NSString*)keyPath inDictionary:(NSMutableDictionary**)dict{
    //find if there's a dot left in the keyPath
    NSUInteger dotLocation = [keyPath rangeOfString:@"."].location;
    if (dotLocation==NSNotFound) return;
    
    //inspect next level
    NSString* nextHierarchyLevelKeyName = [keyPath substringToIndex: dotLocation];
    NSDictionary* nextLevelDictionary = (*dict)[nextHierarchyLevelKeyName];
    
    if (nextLevelDictionary==nil) {
        //create non-existing next level here
        nextLevelDictionary = [NSMutableDictionary dictionary];
    }
    
    //recurse levels
    [self __createDictionariesForKeyPath:[keyPath substringFromIndex: dotLocation+1]
                            inDictionary:&nextLevelDictionary ];
    
    //create the hierarchy level
    [*dict setValue:nextLevelDictionary  forKeyPath: nextHierarchyLevelKeyName];
}


@end
