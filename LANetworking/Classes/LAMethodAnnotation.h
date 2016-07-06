//
//  LAMethodAnnotation.h
//  Pods
//
//  Created by LakeR on 16/7/3.
//
//

#import <Foundation/Foundation.h>

@class LAParameterResult;

@interface LAMethodAnnotation : NSObject
@property (nonatomic,copy) NSString *httpMethod;
@property (nonatomic,strong) NSDictionary *header;
@property (nonatomic,copy) NSString *path;
@property (nonatomic,strong) NSArray *parameterNames;

@property (nonatomic,copy) NSString *reformatterName;
@property (nonatomic,strong) NSNumber *cacheTime;
@property (nonatomic,strong) NSNumber *bodyFormType;

@property (nonatomic,strong) NSURL *finalURL;
@property (nonatomic,strong) NSDictionary *finalParameter;


-(instancetype)initWithDictionary:(NSDictionary *)dic;

- (LAParameterResult *)parameterizedString:(NSString*)string
                             forInvocation:(NSInvocation*)invocation
                                     error:(NSError**)error;


- (LAParameterResult *)parameterizedHeadersForInvocation:(NSInvocation*)invocation
                                                   error:(NSError**)error;


- (LAParameterResult *)parameterizedBodyForInvocation:(NSInvocation*)invocation
                                           withKeySet:(NSSet<NSString *> *)keySet
                                                error:(NSError**)error;

@end
