//
//  LAURLResponse.m
//  Pods
//
//  Created by LakeR on 16/7/1.
//
//

#import "LAURLResponse.h"
#import "LAJsonKit.h"
#import "LAReformatter.h"

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
                responseData:(id)responseData{
    if (self = [self init]) {
        _request = request;
        _responseData = responseData;
        _responseObject = [[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding] toObject];
        _isCache = YES;
    }
    return self;
}

-(void)reformatterObject:(Class)reformatter{
    if([_responseObject isKindOfClass:[NSArray class]]){
        NSMutableArray *result = [NSMutableArray array];
        for (id item in _responseObject) {
            id reformatterItem = [reformatter new];
            [reformatterItem convertFromDictionary:item];
            [result addObject:reformatterItem];
        }
        _responseObject = result;
    }
    else if([_responseObject isKindOfClass:[NSDictionary class]]){
        _responseObject = [reformatter new];
        [_responseObject convertFromDictionary:self.responseObject];
    }
}

@end
