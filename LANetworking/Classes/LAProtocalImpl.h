//
//  LAProtocalImpl.h
//  Pods
//
//  Created by LakeR on 16/7/2.
//
//

#import <Foundation/Foundation.h>

@interface LAProtocalImpl : NSObject


@property(nonatomic,strong) Protocol* protocol;
@property(nonatomic,strong) NSDictionary* annotation;


@property(nonatomic,strong) NSURL *baseURL;
@property(nonatomic,strong) NSDictionary *defaultHeaders;
@property(nonatomic,assign) NSUInteger bodyFormType;
@property(nonatomic,assign) NSUInteger cacheTime;

@property(nonatomic,strong) NSURLSessionConfiguration *sessionConfiguration;

@end
