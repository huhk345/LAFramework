//
//  LAURLResponse.h
//  Pods
//
//  Created by LakeR on 16/7/1.
//
//

#import <Foundation/Foundation.h>


@protocol LAReformatter;

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
                         error:(nullable NSError *)error;

-(instancetype)initWithRequest:(NSURLRequest *)request
                  responseData:(id)responseData;


-(void)reformatterObject:(Class)reformatter;


@end
NS_ASSUME_NONNULL_END