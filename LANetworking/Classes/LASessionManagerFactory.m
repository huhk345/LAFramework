//
//  LASessionManagerFactory.m
//  Pods
//
//  Created by LakeR on 16/7/5.
//
//

#import "LASessionManagerFactory.h"
#import "AFNetworking.h"
static NSMutableDictionary *managerStore;


@implementation LASessionManagerFactory

+(void)load{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        managerStore = [NSMutableDictionary dictionary];
    });
}


+(AFHTTPSessionManager *)managerWithService:(NSString *)service
                                    baseURL:(NSURL *)baseURL
                       sessionConfiguration:(NSURLSessionConfiguration *)configuration{
    @synchronized (self) {
        AFHTTPSessionManager *manager = managerStore[service];
        if (!manager) {
            manager = [[AFHTTPSessionManager alloc] initWithBaseURL:baseURL sessionConfiguration:configuration];
            manager.responseSerializer = [AFHTTPResponseSerializer serializer];
            manager.securityPolicy.allowInvalidCertificates = YES;
            manager.securityPolicy.validatesDomainName = NO;
            managerStore[service] = manager;
        }
        return manager;
    }
}

@end
