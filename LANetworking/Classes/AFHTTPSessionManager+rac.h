//
//  AFHTTPSessionManager+rac.h
//  Pods
//
//  Created by 胡恒恺 on 16/7/1.
//
//

#import <AFNetworking/AFNetworking.h>

@class RACSignal;

@interface AFHTTPSessionManager (rac)

-(RACSignal *)sendRequest:(NSURLRequest *)request;

@end
