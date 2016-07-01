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


-(instancetype)initWithStatus:(NSUInteger)status
                      request:(NSURLRequest *)request
                     response:(NSHTTPURLResponse *)response;

-(instancetype)initWithStatus:(NSUInteger)status
                      request:(NSURLRequest *)request
                     response:(NSHTTPURLResponse *)response
                        error:(NSError *)error;

-(instancetype)initWithResponseObject:(id)responseObject;


@end
NS_ASSUME_NONNULL_END