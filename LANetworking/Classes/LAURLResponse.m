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
    
}

-(instancetype)initWithResponseObject:(id)responseObject{
    
}

@end
