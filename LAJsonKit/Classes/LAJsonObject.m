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
#import <objc/message.h>

static const NSString * kClassPropertiesKey = @"kClassPropertiesKey";
static const NSString * kMapperObjectKey = @"kMapperObjectKey";

static const NSString * JsonErrorDomain = @"com.laker.LAFramework.LAJsonKit";
static const NSString * kJsonErrorReason = @"reason";
static const NSString * kJsonErrorName = @"name";

#pragma mark - class static variables
static NSArray* allowedJSONTypes = nil;
static NSArray* allowedPrimitiveTypes = nil;
static NSArray* containerTypes = nil;
static NSDictionary *primitivesNames = nil;
static JSONValueTransformer* valueTransformer = nil;

typedef NS_ENUM(int, kJSONModelErrorTypes){
    kJSONErrorConvertToDictionary,
    kJSONErrorUnsupportType,
    kJsonErrorUnsupportValue,
    kJsonErrorCanNotTransformValue,
    kJsonErrorMissmatchType,
};


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

- (instancetype)initWithDictionary:(NSDictionary *)dic error:(NSError *__autoreleasing *)error{

    if(self = [super init]){
        if (![dic isKindOfClass:[NSDictionary class]]) {
            *error = [NSError errorWithDomain:JsonErrorDomain
                                         code:kJsonErrorUnsupportValue
                                     userInfo:@{kJsonErrorReason:@"import object is not dictionary!"}];
            return nil;
        }
        if(![self __importDictionary:dic error:error]){
            return nil;
        }
    }
    return self;
}




#pragma mark - LAReformatter delegate methods
-(void)convertFromDictionary:(NSDictionary *)dic{
    if ([dic isKindOfClass:[NSDictionary class]]) {
        NSError *error;
        @try{
            if(![self __importDictionary:dic error:&error]){
                DLogError(@"convert dictionary to object error!");
            }
        }
        @catch (NSException *exception) {
            DLogError(@"json convert error %@",exception);
        }

    }else{
        DLogError(@"import object is not dictionary!");
    }

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
        *error = [[NSError alloc] initWithDomain:JsonErrorDomain
                                            code:kJSONErrorConvertToDictionary
                                        userInfo:@{kJsonErrorName:exception.name,
                                                   kJsonErrorReason:exception.reason}];
    }
    return result;
}





#pragma mark - JSON private methods
-(BOOL)__importDictionary:(NSDictionary*)dict error:(NSError**)err{
    //loop over the incoming keys and set self's properties
    for (JSONModelClassProperty* property in [self __properties__]) {
        LAPropertyAnnotation *annotation = objc_getAssociatedObject(self.class, &kMapperObjectKey)[property.name];
        
        //convert key name to model keys, if a mapper is provided
        NSString* jsonKeyPath = [self __mapString:property.name];
        //JMLog(@"keyPath: %@", jsonKeyPath);
        
        //general check for data type compliance
        id jsonValue;
        @try {
            jsonValue = [dict valueForKeyPath:jsonKeyPath];
        }
        @catch (NSException *exception) {
            jsonValue = dict[jsonKeyPath];
        }
        
        //check for Optional properties
        if (isNull(jsonValue)) {
            //skip this property, continue with next property
            continue;
        }
        
        Class jsonValueClass = [jsonValue class];
        BOOL isValueOfAllowedType = NO;
        
        for (Class allowedType in allowedJSONTypes) {
            if ( [jsonValueClass isSubclassOfClass: allowedType] ) {
                isValueOfAllowedType = YES;
                break;
            }
        }
        
        if (isValueOfAllowedType==NO) {
            //type not allowed
            DLogError(@"Type %@ is not allowed in JSON.", NSStringFromClass(jsonValueClass));
            
            if (err) {
                NSString* msg = [NSString stringWithFormat:@"Type %@ is not allowed in JSON.", NSStringFromClass(jsonValueClass)];
                *err  = [[NSError alloc] initWithDomain:JsonErrorDomain
                                                   code:kJSONErrorUnsupportType
                                               userInfo:@{kJsonErrorName:property.name,
                                                          kJsonErrorReason:msg}];
            }
            return NO;
        }
        
        //check if there's matching property in the model
        if (property) {
            
            // check for custom setter, than the model doesn't need to do any guessing
            // how to read the property's value from JSON
            if ([self __customSetValue:jsonValue forProperty:property]) {
                //skip to next JSON key
                continue;
            };
            
            // 0) handle primitives
            if (property.type == nil && property.structName==nil) {
                
                //generic setter
                if (jsonValue != [self valueForKey:property.name]) {
                    [self setValue:jsonValue forKey: property.name];
                }
                
                //skip directly to the next key
                continue;
            }
            
            // 0.5) handle nils
            if (isNull(jsonValue)) {
                if ([self valueForKey:property.name] != nil) {
                    [self setValue:nil forKey: property.name];
                }
                continue;
            }
            
            
            // 1) check if property is itself a JSONModel
            if ([property.type isSubclassOfClass:[LAJsonObject class]]) {
                
                //initialize the property's model, store it
                NSError* initErr = nil;
                id value = [[property.type alloc] initWithDictionary: jsonValue error:&initErr];
                
                if (!value) {
                    *err = initErr;
                    return NO;
                }
                if (![value isEqual:[self valueForKey:property.name]]) {
                    [self setValue:value forKey: property.name];
                }
                
                //for clarity, does the same without continue
                continue;
                
            } else {
                
                // 2) check if there's a protocol to the property
                //  ) might or not be the case there's a built in transform for it
                if ([annotation.typeReference length] > 0) {
                    
                    jsonValue = [self __transform:jsonValue
                                 forTypeReference:annotation.typeReference
                                     withProperty:property
                                            error:err];
                    if (!jsonValue) {
                        if ((err != nil) && (*err == nil)) {
                            NSString* msg = [NSString stringWithFormat:@"Failed to transform value, but no error was set during transformation. (%@)", property];
                            *err = [[NSError alloc] initWithDomain:JsonErrorDomain
                                                              code:kJsonErrorCanNotTransformValue
                                                          userInfo:@{kJsonErrorReason:msg}];
                        }
                        return NO;
                    }
                }
                
                // 3.1) handle matching standard JSON types
                if (property.isStandardJSONType && [jsonValue isKindOfClass: property.type]) {
                    
                    //mutable properties
                    if (property.isMutable) {
                        jsonValue = [jsonValue mutableCopy];
                    }
                    
                    //set the property value
                    if (![jsonValue isEqual:[self valueForKey:property.name]]) {
                        [self setValue:jsonValue forKey: property.name];
                    }
                    continue;
                }
                
                // 3.3) handle values to transform
                if (
                    (![jsonValue isKindOfClass:property.type] && !isNull(jsonValue))
                    ||
                    //the property is mutable
                    property.isMutable
                    ||
                    //custom struct property
                    property.structName
                    ) {
                    
                    // searched around the web how to do this better
                    // but did not find any solution, maybe that's the best idea? (hardly)
                    Class sourceClass = [JSONValueTransformer classByResolvingClusterClasses:[jsonValue class]];
                    
                    //JMLog(@"to type: [%@] from type: [%@] transformer: [%@]", p.type, sourceClass, selectorName);
                    
                    //build a method selector for the property and json object classes
                    NSString* selectorName = [NSString stringWithFormat:@"%@From%@:",
                                              (property.structName? property.structName : property.type), //target name
                                              sourceClass]; //source name
                    if ([annotation.reformatter length]) {
                        selectorName = [NSString stringWithFormat:@"%@From%@:", annotation.reformatter, NSStringFromClass(sourceClass)];
                    }
                    SEL selector = NSSelectorFromString(selectorName);
                    
                    //check for custom transformer
                    BOOL foundCustomTransformer = NO;
                    if ([valueTransformer respondsToSelector:selector]) {
                        foundCustomTransformer = YES;
                    } else {
                        //try for hidden custom transformer
                        selectorName = [NSString stringWithFormat:@"__%@",selectorName];
                        selector = NSSelectorFromString(selectorName);
                        if ([valueTransformer respondsToSelector:selector]) {
                            foundCustomTransformer = YES;
                        }
                    }
                    
                    //check if there's a transformer with that name
                    if (foundCustomTransformer) {
                        
                        //it's OK, believe me...
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                        //transform the value
                        jsonValue = [valueTransformer performSelector:selector withObject:jsonValue];
#pragma clang diagnostic pop
                        
                        if (![jsonValue isEqual:[self valueForKey:property.name]]) {
                            [self setValue:jsonValue forKey: property.name];
                        }
                        
                    } else {
                        
                        // it's not a JSON data type, and there's no transformer for it
                        // if property type is not supported - that's a programmer mistake -> exception
                        @throw [NSException exceptionWithName:@"Type not allowed"
                                                       reason:[NSString stringWithFormat:@"%@ type not supported for %@.%@", property.type, [self class], property.name]
                                                     userInfo:nil];
                        return NO;
                    }
                    
                } else {
                    // 3.4) handle "all other" cases (if any)
                    if (![jsonValue isEqual:[self valueForKey:property.name]]) {
                        [self setValue:jsonValue forKey: property.name];
                    }
                }
            }
        }
    }
    
    return YES;
}




//exports the model as a dictionary of JSON compliant objects
-(NSDictionary*)toDictionaryWithKeys:(NSArray*)propertyNames{
    NSArray* properties = [self __properties__];
    NSMutableDictionary* tempDictionary = [NSMutableDictionary dictionaryWithCapacity:properties.count];
    
    id value;
    
    //loop over all properties
    for (JSONModelClassProperty* p in properties) {
        
        
        LAPropertyAnnotation *annotation = objc_getAssociatedObject(self.class, &kMapperObjectKey)[p.name];
        
        //skip if unwanted
        if (propertyNames != nil && ![propertyNames containsObject:p.name] || annotation.ignore)
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
            if (value == nil && objc_getAssociatedObject(self.class, &kMapperObjectKey)[[NSString stringWithFormat:@"__Class__%@", NSStringFromClass([self class])]] == nil){
                [tempDictionary removeObjectForKey:keyPath];
            }
            else{
                [tempDictionary setValue:[NSNull null] forKeyPath:keyPath];
            }
            continue;
        }
        
        //check if the property is another model
        if ([value isKindOfClass:[LAJsonObject class]]) {
            
            //recurse models
            value = [(LAJsonObject*)value convertToDictionary:nil];
            [tempDictionary setValue:value forKeyPath: keyPath];
            
            //for clarity
            continue;
            
        } else {
            // 1) check for built-in transformation
            if (annotation.typeReference && p.type && [containerTypes containsObject:p.type]) {
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
                selectorName = [NSString stringWithFormat:@"%@From%@:", @"JSONObject", annotation.reformatter];
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
    @synchronized (self.class) {
        NSDictionary* classProperties = objc_getAssociatedObject(self.class, &kClassPropertiesKey);
        if (classProperties) return [classProperties allValues];
        
        //if here, the class needs to inspect itself
        [self __setup__];
        
        //return the property list
        classProperties = objc_getAssociatedObject(self.class, &kClassPropertiesKey);
        return [classProperties allValues];
    }

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


#pragma mark - custom transformations
-(BOOL)__customSetValue:(id<NSObject>)value forProperty:(JSONModelClassProperty*)property{
    if (!property.customSetters)
        property.customSetters = [NSMutableDictionary new];
    
    NSString *className = NSStringFromClass([JSONValueTransformer classByResolvingClusterClasses:[value class]]);
    
    if (!property.customSetters[className]) {
        //check for a custom property setter method
        NSString* ucfirstName = [property.name stringByReplacingCharactersInRange:NSMakeRange(0,1)
                                                                       withString:[[property.name substringToIndex:1] uppercaseString]];
        NSString* selectorName = [NSString stringWithFormat:@"set%@With%@:", ucfirstName, className];
        
        SEL customPropertySetter = NSSelectorFromString(selectorName);
        
        //check if there's a custom selector like this
        if (![self respondsToSelector: customPropertySetter]) {
            property.customSetters[className] = [NSNull null];
            return NO;
        }
        
        //cache the custom setter selector
        property.customSetters[className] = selectorName;
    }
    
    if (property.customSetters[className] != [NSNull null]) {
        //call the custom setter
        //https://github.com/steipete
        SEL selector = NSSelectorFromString(property.customSetters[className]);
        ((void (*) (id, SEL, id))objc_msgSend)(self, selector, value);
        return YES;
    }
    
    return NO;
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



#pragma mark - built-in transformer methods
//few built-in transformations
-(id)__transform:(id)value
forTypeReference:(NSString *)typeReference
    withProperty:(JSONModelClassProperty *)property
           error:(NSError**)err{
    Class targetClass = NSClassFromString(typeReference);
    if (!targetClass) {
        
        //no other protocols on arrays and dictionaries
        //except JSONModel classes
        if ([value isKindOfClass:[NSArray class]]) {
            @throw [NSException exceptionWithName:@"Bad property typereference declaration"
                                           reason:[NSString stringWithFormat:@"<%@> is not allowed LAJsonObject typereference, and not a LAJsonObject class.", typeReference]
                                         userInfo:nil];
        }
        return value;
    }
    
    //if the protocol is actually a JSONModel class
    if ([targetClass isSubclassOfClass:[LAJsonObject class]]) {
        
        //check if it's a list of models
        if ([property.type isSubclassOfClass:[NSArray class]]) {
            
            // Expecting an array, make sure 'value' is an array
            if(![[value class] isSubclassOfClass:[NSArray class]]){
                NSString* mismatch = [NSString stringWithFormat:@"Property '%@' is declared as NSArray<%@>* but the corresponding JSON value is not a JSON Array.", property.name, typeReference];
                *err = [NSError errorWithDomain:JsonErrorDomain
                                           code:kJsonErrorMissmatchType
                                       userInfo:@{kJsonErrorReason:mismatch}];
                return nil;
            }
            
            //one shot conversion
        
            NSMutableArray *array = [NSMutableArray array];
            for (id object in value) {
                id jsonObject = [[targetClass alloc] initWithDictionary:object error:err];
                if (jsonObject) {
                    [array addObject:jsonObject];
                }else{
                    break;
                }
            }
            if(*err){
                return nil;
            }
            value = [NSArray arrayWithArray:array];
        }
        
        //check if it's a dictionary of models
        if ([property.type isSubclassOfClass:[NSDictionary class]]) {
            
            // Expecting a dictionary, make sure 'value' is a dictionary
            if(![[value class] isSubclassOfClass:[NSDictionary class]]){
                NSString* mismatch = [NSString stringWithFormat:@"Property '%@' is declared as NSDictionary<%@>* but the corresponding JSON value is not a JSON Object.", property.name, typeReference];
                *err = [NSError errorWithDomain:JsonErrorDomain
                                           code:kJsonErrorMissmatchType
                                       userInfo:@{kJsonErrorReason:mismatch}];
                return nil;
            }
            
            NSMutableDictionary* res = [NSMutableDictionary dictionary];
            
            for (NSString* key in [value allKeys]) {
                id jsonObject = [[targetClass alloc] initWithDictionary:value[key] error:err];
                if (jsonObject != nil){
                    [res setValue:jsonObject forKey:key];
                }else{
                    break;
                }
               
            }
            if(*err){
                return nil;
            }
            value = [NSDictionary dictionaryWithDictionary:res];
        }
    }
    
    return value;
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
