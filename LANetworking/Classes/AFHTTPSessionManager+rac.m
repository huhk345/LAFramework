//
//  AFHTTPSessionManager+rac.m
//  Pods
//
//  Created by 胡恒恺 on 16/7/1.
//
//

#import "AFHTTPSessionManager+rac.h"
#import "LAURLResponse.h"

@implementation AFHTTPSessionManager (rac)


-(RACSignal *)sendRequest:(NSURLRequest *)request{
    RACSignal *singal =nil;

    
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        DDLogDebug(@"\n==================================\n\nRequest Start: \n\n \(request.URL)\n\n==================================");
        NSURLSessionDataTask *dataTask;
        dataTask = [self dataTaskWithRequest:request
                           completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
                               NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                               NSData *responseData = (NSData *)responseObject;
                               NSString *responseString = nil;
                               if (responseData.length > 0) {
                                   responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
                               }
                               DLogDebug(@"request \(request.URL)\n code : \(httpResponse?.statusCode)\nresponse:\(responseString)");
                               if (error) {
                                   [subscriber sendNext:[[LAURLResponse alloc] initWithRequest:request
                                                                                      response:httpResponse
                                                                                  responseData:responseData]];
                               }
                               else{
                                   [subscriber sendNext:[[LAURLResponse alloc] initWithRequest:request
                                                                                      response:httpResponse
                                                                                  responseData:responseData
                                                                                         error:error]];
                                   [subscriber sendCompleted];
                               }
            
        }];
        [dataTask resume];
        return [RACDisposable disposableWithBlock:^{
            [dataTask cancel];
        }];
    }];
    
}

@end
