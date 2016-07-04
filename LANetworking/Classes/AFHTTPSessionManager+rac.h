//
//  AFHTTPSessionManager+rac.h
//  Pods
//
//  Created by LakeR on 16/7/1.
//
//

#import <AFNetworking/AFNetworking.h>

@class RACSignal;

@interface AFHTTPSessionManager (rac)

-(RACSignal *)rac_sendRequest:(NSURLRequest *)request;

@end
