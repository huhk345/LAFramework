//
//  LANetworkingManager.h
//  Pods
//
//  Created by LakeR on 16/7/5.
//
//

#import <Foundation/Foundation.h>
#import "LAURLResponse.h"


@interface LANetworkingManager : NSObject
    
@property (nonatomic,copy) BOOL (^handler)(LAURLResponse *response);

+ (instancetype)sharedInstance;

+ (instancetype)new __attribute__((unavailable));

- (instancetype)init __attribute__((unavailable));


@property (nonatomic, strong) NSURL *baseURL;
@property (nonatomic, strong) NSURLSessionConfiguration *sessionConfiguration;

@end
