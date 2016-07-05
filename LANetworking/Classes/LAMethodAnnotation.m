//
//  LAMethodAnnotation.m
//  Pods
//
//  Created by LakeR on 16/7/3.
//
//

#import "LAMethodAnnotation.h"
#import "NSInvocation+LAUtils.h"
#import "LAReformater.h"
#import "LAParameterResult.h"

static NSString* const KEY_PARAMETERS = @"parameterNames";
static NSString* const KEY_REFORMATTER = @"reformaterName";
static NSString* const KEY_ANNOTATIONS = @"annotations";

static NSString* const KEY_ANNOTATION_CACHE  = @"Cache";
static NSString* const KEY_ANNOTATION_HEADER = @"Headers";

#define HTTP_METHODS        @[@"PUT",@"GET",@"POST",@"DELETE",@"PATCH"]
#define HTTP_BODY_TYPES     @[@"FormData",@"FormUrlEncode",@"FormRaw"]

@implementation LAMethodAnnotation

-(instancetype)initWithDictionary:(NSDictionary *)dic{
    if (self = [self init]) {
        self.parameterNames = dic[KEY_PARAMETERS];
        self.reformatterName = dic[KEY_REFORMATTER];
        
        //parse annotatison
        [self parseAnnotations:dic[KEY_ANNOTATIONS]];
    }
    return self;
}


#pragma mark - parse annotations
-(void)parseAnnotations:(NSDictionary *)annotations{
    for(NSString *key in [annotations allKeys]){
        if ([key isEqualToString:KEY_ANNOTATION_CACHE]) {
            self.cacheTime = [self parseCacheTime:annotations[key]];
        }else if([key isEqualToString:KEY_ANNOTATION_HEADER]){
            self.header = annotations[key];
        }else if([HTTP_METHODS containsObject:key]){
            self.httpMethod = key;
            self.path = annotations[key];
        }else if([HTTP_BODY_TYPES indexOfObject:key] != NSNotFound){
            self.bodyFormType = @([HTTP_BODY_TYPES indexOfObject:key]);
        }
    }
}


-(NSNumber *)parseCacheTime:(NSString *)cacheTime{
    NSRange searchedRange = NSMakeRange(0, [cacheTime length]);
    NSString *pattern = @"[0-9]+";
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern: pattern options:0 error:nil];
    NSArray* matches = [regex matchesInString:cacheTime options:0 range: searchedRange];
    if(matches.lastObject){
        NSUInteger secondes = [[cacheTime substringWithRange:[matches.lastObject range]] integerValue];
        NSString *unit = [cacheTime substringFromIndex:[matches.lastObject range].location + [matches.lastObject range].length];
        if([unit containsString:@"D"] || [unit containsString:@"d"]){
            return @(secondes * 3600 * 24);
        }
        else if([unit containsString:@"H"] || [unit containsString:@"h"]){
            return @(secondes * 3600);
        }
        else if([unit containsString:@"M"] || [unit containsString:@"m"]){
            return @(secondes * 60);
        }
    }
    return nil;
    
}

#pragma mark - replace path annoatation values
- (LAParameterResult<NSString *> *)parameterizedString:(NSString*)string
                    forInvocation:(NSInvocation*)invocation
                            error:(NSError**)error{
    NSMutableSet* consumedParameters = [[NSMutableSet alloc] init];
    NSMutableString* paramedString = string.mutableCopy;
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:@"\\{:([a-zA-Z0-9_]+)\\}"
                                                                           options:0
                                                                             error:error];
    
    if (error && *error) {
        return nil;
    }
    
    NSArray *matches = [regex matchesInString:string
                                      options:0
                                        range:NSMakeRange(0, [string length])];
    
    for (NSInteger i = matches.count - 1; i >= 0; i--) {
        NSTextCheckingResult* match = matches[i];
        NSRange nameRange = [match rangeAtIndex:1];
        NSString* paramName = [string substringWithRange:nameRange];
        NSUInteger paramIdx = [self.parameterNames indexOfObject:paramName];
        
        // TODO: this should probably be allowed, in case some URL randomly contains "{not_a_param}"
        NSAssert(paramIdx != NSNotFound, @"Unknown substitution variable in path: %@", paramName);
        
        NSString* paramValue = [self stringValueForParameterAtIndex:paramIdx
                                                     withInvocation:invocation
                                                              error:error];
        if (error && *error) {
            return nil;
        }
        paramValue = [paramValue stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]];
        
        [paramedString replaceCharactersInRange:match.range withString:paramValue];
        [consumedParameters addObject:paramName];
    }
    return [[LAParameterResult alloc] initWithResult:paramedString consumedParameters:consumedParameters];
}


#pragma mark - replace header annoatation values
- (LAParameterResult<NSDictionary*>*)parameterizedHeadersForInvocation:(NSInvocation*)invocation
                                                                 error:(NSError**)error{
    NSMutableDictionary* result = [[NSMutableDictionary alloc] init];
    NSMutableSet* consumedParameters = [[NSMutableSet alloc] init];
    
    for (NSString* key in self.header) {
        NSString* headerValue = self.header[key];
        LAParameterResult<NSString*>* valueResult = [self parameterizedString:headerValue
                                                                forInvocation:invocation
                                                                        error:error];
        result[key] = valueResult.result;
        [consumedParameters unionSet:valueResult.consumedParameters];
    }
    
    return [[LAParameterResult alloc] initWithResult:result consumedParameters:consumedParameters];
}


#pragma mark - replace body annoatation values
- (LAParameterResult<NSDictionary*>*)parameterizedBodyForInvocation:(NSInvocation*)invocation
                                                         withKeySet:(NSSet<NSString *> *)keySet
                                                              error:(NSError**)error{
    NSMutableDictionary* result = [[NSMutableDictionary alloc] init];
    NSMutableSet* consumedParameters = [[NSMutableSet alloc] init];
    
    for (NSString* key in keySet) {
        result[key] = [self ObjectValueForParameterAtIndex:[self.parameterNames indexOfObject:key]
                                            withInvocation:invocation
                                                     error:error];
    }
    
    return [[LAParameterResult alloc] initWithResult:result consumedParameters:consumedParameters];
}




- (NSString*)stringValueForParameterAtIndex:(NSUInteger)index
                             withInvocation:(NSInvocation*)invocation
                                      error:(NSError**)error{
    return [invocation stringValueForParameterAtIndex:index error:&error];
}



- (NSString*)ObjectValueForParameterAtIndex:(NSUInteger)index
                             withInvocation:(NSInvocation*)invocation
                                      error:(NSError**)error{
    return [invocation objectValueForParameterAtIndex:index error:&error];
}


@end
