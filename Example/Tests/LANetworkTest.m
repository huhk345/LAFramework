//
//  LANetworkTest.m
//  LAFramework
//
//  Created by LakeR on 16/7/6.
//  Copyright © 2016年 LakeR inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <LAFramework/LANetworkingBuilder.h>
#import "GitHubService.h"
#import "LAURLResponse.h"
#import "ReactiveCocoa.h"
#import "AFHTTPSessionManager+rac.h"
#import "Aspects.h"
#import "LAProtocalImpl.h"

@interface LANetworkTest : XCTestCase

@end

@implementation LANetworkTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testBuildURL {
    LAProtocalImpl<GitHubService> *service = [[LANetworkingBuilder initBuilderWithBlock:^(LANetworkingBuilder *builder) {
        builder.baseURL = [NSURL URLWithString:@"https://api.github.com"];
    }] create:@protocol(GitHubService)];
    assert([service listRepos:@"huhk345"] != nil);
    //check url replace
    assert([[service.request.URL absoluteString] isEqualToString:@"https://api.github.com/users/huhk345/repos"]);
    //check cache annotation
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    NSInteger result = (NSInteger)[service performSelector:@selector(methodCacheTime:) withObject:[[service valueForKey:@"annotation"] valueForKey:@"listRepos:"]];
    assert(result == 3600 * 24);
#pragma clang diagnostic pop

}





@end
