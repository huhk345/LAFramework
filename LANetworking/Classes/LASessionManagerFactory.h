//
//  LASessionManagerFactory.h
//  Pods
//
//  Created by LakeR on 16/7/5.
//
//

#import <Foundation/Foundation.h>

@class AFHTTPSessionManager;
@interface LASessionManagerFactory : NSObject

//return cached sessionManager
+(AFHTTPSessionManager *)managerWithService:(NSString *)service
                                    baseURL:(NSURL *)baseURL
                       sessionConfiguration:(NSURLSessionConfiguration *)configuration;

@end
