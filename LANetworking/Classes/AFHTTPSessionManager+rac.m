//
//  AFHTTPSessionManager+rac.m
//  Pods
//
//  Created by LakeR on 16/7/1.
//
//

#import "AFHTTPSessionManager+rac.h"
#import "LAURLResponse.h"
#import "LANetworkingManager.h"
@implementation AFHTTPSessionManager (rac)


-(RACSignal *)rac_sendRequest:(NSURLRequest *)request{
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        DLogDebug(@"\n==================================\n\nRequest Start: \n\n %@\n\n==================================",request.URL);
        NSURLSessionDataTask *dataTask;
        dataTask = [self dataTaskWithRequest:request
                           completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
                               NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                               NSData *responseData = (NSData *)responseObject;
                               NSString *responseString = nil;
                               if (responseData.length > 0) {
                                   responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
                               }
                               DLogDebug(@"\n==================================\nrequest %@\n code : %ld\nresponse:%@\n==================================",request.URL,(long)httpResponse.statusCode,responseString);
                               if (!error) {
                                   BOOL sendNextFlag = YES;
                                   LAURLResponse *response = [[LAURLResponse alloc] initWithRequest:request
                                                                                           response:httpResponse
                                                                                       responseData:responseData];
                                   if([LANetworkingManager sharedInstance].handler != nil){
                                        sendNextFlag = ![LANetworkingManager sharedInstance].handler(response);
                                   }
                                   if(sendNextFlag){
                                       [subscriber sendNext:response];
                                   }
                                   [subscriber sendCompleted];
                               }
                               else{
                                   [subscriber sendError:error];
                                   
                               }
            
        }];
        [dataTask resume];
        return [RACDisposable disposableWithBlock:^{
            [dataTask cancel];
        }];
    }];
}


//-(RACSignal *)rac_downloadRequest:(NSURLRequest *)request{
//    RACSignal *singal =nil;
//    
//    
//    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
//        DDLogDebug(@"\n==================================\n\nRequest Start: \n\n \(request.URL)\n\n==================================");
//        NSURLSessionDataTask *dataTask;
//        [self downloadTaskWithRequest:request progress:nil destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
//            <#code#>
//        } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
//            
//        }];
////        dataTask = [self dataTaskWithRequest:request
////                           completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
////                               NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
////                               NSData *responseData = (NSData *)responseObject;
////                               NSString *responseString = nil;
////                               if (responseData.length > 0) {
////                                   responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
////                               }
////                               DLogDebug(@"request \(request.URL)\n code : \(httpResponse?.statusCode)\nresponse:\(responseString)");
////                               if (error) {
////                                   [subscriber sendNext:[[LAURLResponse alloc] initWithRequest:request
////                                                                                      response:httpResponse
////                                                                                  responseData:responseData]];
////                               }
////                               else{
////                                   [subscriber sendNext:[[LAURLResponse alloc] initWithRequest:request
////                                                                                      response:httpResponse
////                                                                                  responseData:responseData
////                                                                                         error:error]];
////                                   [subscriber sendCompleted];
////                               }
////                               
////                           }];
//        [dataTask resume];
//        return [RACDisposable disposableWithBlock:^{
//            [dataTask cancel];
//        }];
//    }];
//}

@end
