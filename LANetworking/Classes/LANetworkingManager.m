//
//  LANetworkingManager.m
//  Pods
//
//  Created by LakeR on 16/7/5.
//
//

#import "LANetworkingManager.h"
#import "AFNetworking.h"

@interface LANetworkingManager()

@property (nonatomic, strong) AFHTTPSessionManager *sessionManager;

@end

@implementation LANetworkingManager

#pragma mark - life cycle
+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    static LANetworkingManager *sharedInstance = nil;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[LANetworkingManager alloc] _init];
    });
    return sharedInstance;
}


- (instancetype)_init{
    self = [super init];
    return self;
}


#pragma mark - getters and setters
- (AFHTTPSessionManager *)sessionManager
{
    @synchronized (self.class) {
        if (_sessionManager == nil) {
            _sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:self.baseURL
                                                       sessionConfiguration:self.sessionConfiguration];
            _sessionManager.requestSerializer = [AFHTTPRequestSerializer serializer];
            _sessionManager.responseSerializer = [AFHTTPResponseSerializer serializer];
            _sessionManager.securityPolicy.allowInvalidCertificates = YES;
            _sessionManager.securityPolicy.validatesDomainName = NO;
        }
        return _sessionManager;
    }
}

@end
