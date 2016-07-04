//
//  LAURLResponse.h
//  Pods
//
//  Created by 胡恒恺 on 16/7/1.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@interface LAURLResponse : NSObject

@property (nonatomic,readonly,strong,nullable) NSURLRequest *request;

@property (nonatomic,readonly,assign) NSUInteger status;
@property (nonatomic,readonly,strong,nullable) NSDictionary *responseHeader;

@property (nonatomic,readonly,strong,nullable) id responseObject;
@property (nonatomic,readonly,strong,nullable) NSData *responseData;
@property (nonatomic,readonly,strong,nullable) NSError *error;


@property (nonatomic,readonly,assign) BOOL isCache;


-(instancetype)initWithRequest:(NSURLRequest *)request
                      response:(NSHTTPURLResponse *)response
                  responseData:(NSData *)responseData;

-(instancetype)initWithRequest:(NSURLRequest *)request
                      response:(NSHTTPURLResponse *)response
                  responseData:(NSData *)responseData
                         error:(NSError *)error;

-(instancetype)initWithRequest:(NSURLRequest *)request
                responseObject:(id)responseObject;

@end
NS_ASSUME_NONNULL_END