//
//  AFHTTPSessionManager+rac.m
//  Pods
//
//  Created by 胡恒恺 on 16/7/1.
//
//

#import "AFHTTPSessionManager+rac.h"
//#import <ReactiveCocoa/ReactiveCocoa.h>

@implementation AFHTTPSessionManager (rac)


-(RACSignal *)sendRequest:(NSURLRequest *)request{
    
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        DDLogDebug(@"\n==================================\n\nRequest Start: \n\n \(request.URL)\n\n==================================");
        return [RACDisposable disposableWithBlock:^{
            
        }];
    }];
    
}

//public func sendRequest(request : NSURLRequest!) -> RACSignal {
//    let subject : RACReplaySubject = RACReplaySubject.init(capacity: 5)
//    DDLogDebug("\n==================================\n\nRequest Start: \n\n \(request.URL)\n\n==================================")
//    var dataTask : NSURLSessionDataTask
//    dataTask = self.dataTaskWithRequest(request, completionHandler: { (response, responseObject, error) in
//        let httpResponse : NSHTTPURLResponse? = response as? NSHTTPURLResponse
//        let responseData : NSData? = responseObject as? NSData
//        var responseString : NSString?
//        
//        if responseData?.length > 0 {
//            responseString = NSString(data: responseData!, encoding: NSUTF8StringEncoding)
//        }
//        
//        DDLogDebug("request \(request.URL)\n code : \(httpResponse?.statusCode)\nresponse:\(responseString)")
//        if error != nil{
//            subject.sendNext(LAURLResponse(status : httpResponse?.statusCode,
//                                           request : request,
//                                           responseData :responseData,
//                                           error: error))
//        }
//        else {
//            subject.sendNext(LAURLResponse(status : httpResponse?.statusCode,
//                                           request : request,
//                                           responseData :responseData))
//            subject.sendCompleted()
//        }
//    })
//    dataTask.resume()
//    return subject
//}



@end
