//
//  LAURLResponse.m
//  Pods
//
//  Created by 胡恒恺 on 16/7/1.
//
//

#import "LAURLResponse.h"

@implementation LAURLResponse

-(instancetype)initWithStatus:(NSUInteger)status
                      request:(NSURLRequest *)request
                     response:(NSHTTPURLResponse *)response{
    return [self initWithStatus:status request:request response:response error:nil];
}

-(instancetype)initWithStatus:(NSUInteger)status
                      request:(NSURLRequest *)request
                     response:(NSHTTPURLResponse *)response
                        error:(NSError *)error{
    if (self = [self init]) {
        _status = status;
        _request = request;
        _responseHeader = response.allHeaderFields;
//        _responseData = response
    }
    return self;
}

-(instancetype)initWithResponseObject:(id)responseObject{
    return nil;
}

@end
