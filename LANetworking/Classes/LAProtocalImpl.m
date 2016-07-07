//
//  LAProtocalImpl.m
//  Pods
//
//  Created by LakeR on 16/7/2.
//
//

#import "LAProtocalImpl.h"
#import <ObjC/runtime.h>
#import "LAMethodAnnotation.h"
#import "LAParameterResult.h"
#import "AFNetworking.h"
#import "LASessionManagerFactory.h"
#import "LANetworkingBuilder.h"
#import "AFHTTPSessionManager+rac.h"
#import "LAJsonKit.h"
#import "LAURLResponse.h"
#import "LAReformatter.h"
#import "LACache.h"

@implementation LAProtocalImpl


#pragma mark - invocatin hooking methods
- (void)forwardInvocation:(NSInvocation *)anInvocation {
    struct objc_method_description desc = protocol_getMethodDescription(self.protocol, anInvocation.selector, YES, YES);
    
    if (desc.name == NULL && desc.types == NULL) {
        [super forwardInvocation:anInvocation];
    } else {
        [self handleInvocation:anInvocation];
    }
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    struct objc_method_description desc = protocol_getMethodDescription(self.protocol, aSelector, YES, YES);
    
    if (desc.name == NULL && desc.types == NULL) {
        return [super respondsToSelector:aSelector];
    } else {
        return YES;
    }
}

- (void)handleInvocation:( NSInvocation*)invocation{
    [invocation retainArguments];
    
    // get method description
    NSString* sig = NSStringFromSelector(invocation.selector);
    LAMethodAnnotation* methodAnnotation = self.annotation[sig];
    
    NSParameterAssert(methodAnnotation.httpMethod);
    NSParameterAssert(methodAnnotation.path);
    //parse annotations
    NSError *error = nil;
    LAParameterResult<NSString *> *pathResult = [methodAnnotation parameterizedString:methodAnnotation.path
                                                                        forInvocation:invocation
                                                                                error:&error];
    
    LAParameterResult<NSDictionary *> *headerResult = [methodAnnotation parameterizedHeadersForInvocation:invocation
                                                                                                    error:&error];
    
    
    NSMutableSet *bodyKeys = [[NSMutableSet alloc] initWithArray:methodAnnotation.parameterNames];
    [bodyKeys minusSet:pathResult.consumedParameters];
    [bodyKeys minusSet:headerResult.consumedParameters];
    LAParameterResult<NSDictionary *> *parameterResult =
                                                [methodAnnotation parameterizedBodyForInvocation:invocation
                                                                                      withKeySet:bodyKeys
                                                                                           error:&error];
    
    if(error){
        DLogError(@"construct http request failed : %@",error);
        id result = nil;
        [invocation setReturnValue:&result];
        return;
    }
    
    
    
    AFHTTPSessionManager *manager = [LASessionManagerFactory managerWithService:NSStringFromClass([self class])
                                                                        baseURL:self.baseURL
                                                           sessionConfiguration:self.sessionConfiguration];
    [self.defaultHeaders enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [manager.requestSerializer setValue:obj forHTTPHeaderField:key];
    }];
    NSMutableURLRequest *request = [self generateRequest:manager.requestSerializer
                                                    path:pathResult.result
                                                  header:headerResult.result
                                              parameters:parameterResult.result
                                              annotation:methodAnnotation
                                                   error:&error];
    if(error){
        DLogError(@"bulid http request failed :%@",error);
        id result = nil;
        [invocation setReturnValue:&result];
        return;
    }
    
    
    RACSignal *requestSignal = nil;
    if([request.HTTPMethod isEqualToString:@"GET"] && [self methodCacheTime:methodAnnotation] > 0){
        id cachedData = [[PFKeyValueCache shareInstance] objectForKey:[request.URL absoluteString]
                                                               maxAge:[self methodCacheTime:methodAnnotation]];
        if (cachedData) {
            requestSignal = [RACSignal return:[[LAURLResponse alloc]
                                               initWithRequest:request responseData:cachedData]];
        }
    }
    
    if(!requestSignal){
        requestSignal = [manager rac_sendRequest:request];
    }
    
    @weakify(self)
    RACSignal *signal = [requestSignal doNext:^(LAURLResponse *value) {
        @strongify(self)
        if(!value.error){
            //cache response if need
            if(!value.isCache &&
               [value.request.HTTPMethod isEqualToString:@"GET"] &&
               [self methodCacheTime:methodAnnotation] > 0){
                [[PFKeyValueCache shareInstance] setObject:value.responseData
                                                    forKey:[value.request.URL absoluteString]];
            }
            //reformatter object
            if([methodAnnotation.reformatterName length] > 0 ){
                Class reformatter = NSClassFromString(methodAnnotation.reformatterName);
                if(reformatter && [reformatter conformsToProtocol:@protocol(LAReformatter)]){
                    [value reformatterObject:reformatter];
                }
            }
        }
    }];
    [invocation setReturnValue:&signal];
}

#pragma mark - request generate methods
//TODO: download file and backgournd upload file
-(NSMutableURLRequest *)generateRequest:(AFHTTPRequestSerializer *)requestSerializer
                                   path:(NSString *)path
                                 header:(NSDictionary *)header
                             parameters:(NSDictionary *)parameters
                             annotation:(LAMethodAnnotation *)methodAnnotation
                                  error:(NSError **)error{
    
#define SET_HEAD_TO_REQUEST(flag)  if(*error){ \
                                        DLogError(@"generate http request failed : %@",*error); \
                                        return nil;\
                                    }\
                                    [header enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {\
                                        if (![key isEqualToString:@"Content-Type"] || flag) {\
                                            [request setValue:obj forHTTPHeaderField:key];\
                                        }\
                                    }]
    
    
    NSMutableURLRequest *request;
    if ([methodAnnotation.httpMethod isEqualToString:@"GET"] ||
        [methodAnnotation.httpMethod isEqualToString:@"DELETE"] ||
        [methodAnnotation.httpMethod isEqualToString:@"HEAD"]) {
        request = [requestSerializer requestWithMethod:methodAnnotation.httpMethod
                                             URLString:[[NSURL URLWithString:path relativeToURL:self.baseURL] absoluteString]
                                            parameters:parameters
                                                 error:error];
        SET_HEAD_TO_REQUEST(NO);
    }
    else {
        switch (methodAnnotation.bodyFormType ? [methodAnnotation.bodyFormType integerValue] : self.bodyFormType) {
            case LAFormData:{
                request = [self generateFormDataRequest:requestSerializer
                                                   path:path
                                             parameters:parameters
                                             annotation:methodAnnotation
                                                  error:error];
                SET_HEAD_TO_REQUEST(NO);
                break;
            }
            case LAFormUrlencode:{
                request = [requestSerializer requestWithMethod:methodAnnotation.httpMethod
                                                     URLString:[[NSURL URLWithString:path relativeToURL:self.baseURL] absoluteString]
                                                    parameters:parameters
                                                         error:error];
                SET_HEAD_TO_REQUEST(NO);
                break;
            }
            case LAFormRaw:{
                request = [self generateRawDataRequest:requestSerializer
                                                  path:path
                                            parameters:parameters
                                            annotation:methodAnnotation
                                                 error:error];
                SET_HEAD_TO_REQUEST(YES);
                break;
            }
            default:
                break;
        }
    }
    return request;
    
    
}


-(NSMutableURLRequest *)generateRawDataRequest:(AFHTTPRequestSerializer *)requestSerializer
                                           path:(NSString *)path
                                     parameters:(NSDictionary *)parameters
                                     annotation:(LAMethodAnnotation *)methodAnnotation
                                          error:(NSError **)error{
    NSMutableURLRequest *mutableRequest = [requestSerializer requestWithMethod:methodAnnotation.httpMethod
                                                                     URLString:[[NSURL URLWithString:path relativeToURL:self.baseURL] absoluteString]
                                                                    parameters:nil
                                                                         error:error];
    mutableRequest.HTTPBody = [[parameters jsonString] dataUsingEncoding:NSUTF8StringEncoding];
    return mutableRequest;
}




-(NSMutableURLRequest *)generateFormDataRequest:(AFHTTPRequestSerializer *)requestSerializer
                                           path:(NSString *)path
                                     parameters:(NSDictionary *)parameters
                                     annotation:(LAMethodAnnotation *)methodAnnotation
                                          error:(NSError **)error{
    return [requestSerializer multipartFormRequestWithMethod:methodAnnotation.httpMethod
                                                   URLString:[[NSURL URLWithString:path relativeToURL:self.baseURL] absoluteString]
                                                  parameters:nil
                                   constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
                                       for(NSString *key in [parameters allKeys]){
                                           if([parameters[key] isKindOfClass:[NSString class]]){
                                               [formData appendPartWithFormData:[parameters[key] dataUsingEncoding:NSUTF8StringEncoding]
                                                                           name:key];
                                           }else if([parameters[key] isKindOfClass:[NSNull class]]){
                                               [formData appendPartWithFormData:[NSData data]
                                                                           name:key];
                                           }else if([parameters[key] isKindOfClass:[NSURL class]]){
                                               NSURL *url = parameters[key];
                                               if([url isFileURL] && [[NSFileManager defaultManager] isExecutableFileAtPath:[url path]]){
                                                   [formData appendPartWithFileURL:url
                                                                              name:key
                                                                          fileName:[[url path] lastPathComponent]
                                                                          mimeType:[[self class] mimeTypeForFileAtPath:[url path]]
                                                                             error:error];
                                               }else{
                                                   [formData appendPartWithFormData:[[url absoluteString]dataUsingEncoding:NSUTF8StringEncoding]
                                                                               name:key];
                                               }
                                           }else if([parameters[key] isKindOfClass:[NSArray class]] ||
                                                    [parameters[key] isKindOfClass:[NSDictionary class]] ||
                                                    [parameters[key] isKindOfClass:[NSSet class]]){
                                               [formData appendPartWithFormData:[[parameters[key] jsonString] dataUsingEncoding:NSUTF8StringEncoding]
                                                                           name:key];
                                           }
                                           
                                       }
                                       
                                   }
                                                       error:error];
}





#pragma mark - help functions
+ (NSString*) mimeTypeForFileAtPath: (NSString *) path {
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        return nil;
    }
    // Borrowed from http://stackoverflow.com/questions/5996797/determine-mime-type-of-nsdata-loaded-from-a-file
    // itself, derived from  http://stackoverflow.com/questions/2439020/wheres-the-iphone-mime-type-database
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)[path pathExtension], NULL);
    CFStringRef mimeType = UTTypeCopyPreferredTagWithClass (UTI, kUTTagClassMIMEType);
    CFRelease(UTI);
    if (!mimeType) {
        return @"application/octet-stream";
    }
    return (__bridge_transfer NSString *)mimeType;
}


-(NSUInteger)methodCacheTime:(LAMethodAnnotation *)methodAnnotation{
    NSUInteger cacheTime = self.cacheTime;
    if (methodAnnotation.cacheTime) {
        cacheTime = [methodAnnotation.cacheTime integerValue];
    }
    return cacheTime;
}

@end
