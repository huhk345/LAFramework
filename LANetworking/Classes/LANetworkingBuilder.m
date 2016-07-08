//
//  LANetworkingManager.m
//  Pods
//
//  Created by LakeR on 16/7/3.
//
//

#import "LANetworkingBuilder.h"
#import <ObjC/runtime.h>
#import "LAProtocalImpl.h"
#import "LAMethodAnnotation.h"



@implementation LANetworkingBuilder

+ (instancetype)initBuilderWithBlock:(void(^)(LANetworkingBuilder* builder))block{
    NSParameterAssert(block);
    
    LANetworkingBuilder* builder = [[LANetworkingBuilder alloc] init];
    builder.bodyFormType = LAFormData;
    builder.sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    block(builder);
    NSParameterAssert(builder.baseURL);
    return builder;
}





-(id)create:(Protocol *)protocol{
    Class cls = [self classImplForProtocol:protocol];
    LAProtocalImpl* obj = [[cls alloc] init];
    obj.protocol = protocol;
    obj.annotation = [self methodAnnotationForProtocol:protocol];
    obj.defaultHeaders = self.header;
    obj.cacheTime = self.cacheTime;
    obj.baseURL = self.baseURL;
    obj.bodyFormType = self.bodyFormType;
    return obj;
}




- (Class)classImplForProtocol:(Protocol*)protocol{
    NSString* protocolName = NSStringFromProtocol(protocol);
    NSString* className = [protocolName stringByAppendingString:@"_Impl"];
    Class cls = nil;
    
    // make sure we only create the class once
    @synchronized(self.class) {
        cls = NSClassFromString(className);
        
        if (cls == nil) {
            cls = objc_allocateClassPair([LAProtocalImpl class], [className UTF8String], 0);
            class_addProtocol(cls, protocol);
            objc_registerClassPair(cls);
        }
    }
    
    return cls;
}




- (NSDictionary*)methodAnnotationForProtocol:(Protocol*)protocol {
    NSURL* url = [[NSBundle mainBundle] URLForResource:NSStringFromProtocol(protocol) withExtension:@"laproto"];
    NSAssert(url != nil, @"couldn't find proto file");
    NSDictionary* jsonDict = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfURL:url] options:0 error:nil];
    NSMutableDictionary* result = [[NSMutableDictionary alloc] init];
    
    for (NSString* key in jsonDict) {
        result[key] = [[LAMethodAnnotation alloc] initWithDictionary:jsonDict[key]];
    }
    
    return result;
}
@end
