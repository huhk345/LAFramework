//
//  LANetworkingManager.h
//  Pods
//
//  Created by LakeR on 16/7/5.
//
//

#import <Foundation/Foundation.h>


@interface LANetworkingManager : NSObject

+ (instancetype)sharedInstance;

+ (instancetype)new __attribute__((unavailable));

- (instancetype)init __attribute__((unavailable));


@property (nonatomic, strong) NSURL *baseURL;
@property (nonatomic, strong) NSURLSessionConfiguration *sessionConfiguration;

@end
