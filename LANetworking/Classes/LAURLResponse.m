//
//  LAURLResponse.m
//  Pods
//
//  Created by 胡恒恺 on 16/7/1.
//
//

#import "LAURLResponse.h"
#import "NSString+LAJson.h"

@implementation LAURLResponse

-(instancetype)initWithRequest:(NSURLRequest *)request
                      response:(NSHTTPURLResponse *)response
                  responseData:(NSData *)responseData{
    return [self initWithRequest:request response:response responseData:responseData error:nil];
}

-(instancetype)initWithRequest:(NSURLRequest *)request
                      response:(NSHTTPURLResponse *)response
                  responseData:(NSData *)responseData
                        error:(NSError *)error{
    if (self = [self init]) {
        _request = request;
        _responseHeader = response.allHeaderFields;
        _status = response.statusCode;
        _responseData = responseData;
        _responseObject = [[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding] toObject];
        _isCache = NO;
    }
    return self;
}

-(instancetype)initWithRequest:(NSURLRequest *)request
                responseObject:(id)responseObject{
    if (self = [self init]) {
        _request = request;
        _responseObject = responseObject;
        _isCache = YES;
    }
    return self;
}

@end
