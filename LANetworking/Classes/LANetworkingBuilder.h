//
//  LANetworkingManager.h
//  Pods
//
//  Created by LakeR on 16/7/3.
//
//

#import <Foundation/Foundation.h>


typedef enum {
    LAFormData,
    LAFormUrlencode,
    LAFormRaw,
}LAHttpBodyFormType;


@interface LANetworkingBuilder : NSObject

@property(nonatomic,strong) NSURL *baseURL;

@property(nonatomic,strong) NSDictionary *header;

@property(nonatomic,assign) NSUInteger cacheTime;

@property(nonatomic,assign) LAHttpBodyFormType bodyFormType;

+ (instancetype)initBuilderWithBlock:(void(^)(LANetworkingBuilder* builder))block;

- (id)create:(Protocol *)protocol;

@end
