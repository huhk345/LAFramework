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
#import "LAProtocalImpl.h"
#import "GithubRepo.h"
#import "LACache.h"

@interface LANetworkTest : XCTestCase

@end

@implementation LANetworkTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
//    [[PFKeyValueCache shareInstance] removeAllObjects];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testBuildURL {
    LAProtocalImpl<GitHubService> *service = [[LANetworkingBuilder initBuilderWithBlock:^(LANetworkingBuilder *builder) {
        builder.baseURL = [NSURL URLWithString:@"https://api.github.com"];
    }] create:@protocol(GitHubService)];
    RACSignal *signal = [service listRepos:@"huhk345"];
    XCTAssertTrue(signal != nil);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    NSInteger result = (NSInteger)[service performSelector:@selector(methodCacheTime:) withObject:[[service valueForKey:@"annotation"] valueForKey:@"listRepos:"]];
    XCTAssertTrue(result == 3600 * 24);
#pragma clang diagnostic pop
    
    XCTestExpectation *callBackExpectation = [self expectationWithDescription:@"callback"];
    
    [signal subscribeNext:^(LAURLResponse *response) {
        XCTAssertTrue([[response.request.URL absoluteString] isEqualToString:@"https://api.github.com/users/huhk345/repos"]);
        XCTAssertTrue([[response.responseObject lastObject] isKindOfClass:[GithubRepo class]]);
        [callBackExpectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:5 handler:^(NSError *error) {
        if (error) {
            NSLog(@"%@", error);
        }
    }];
}


- (void)testRequestCachedData {
    LAProtocalImpl<GitHubService> *service = [[LANetworkingBuilder initBuilderWithBlock:^(LANetworkingBuilder *builder) {
        builder.baseURL = [NSURL URLWithString:@"https://api.github.com"];
    }] create:@protocol(GitHubService)];
    RACSignal *signal = [service listRepos:@"huhk345"];
    XCTAssertTrue(signal != nil);
    XCTestExpectation *callBackExpectation = [self expectationWithDescription:@"callback"];
    
    [signal subscribeNext:^(LAURLResponse *response) {
        XCTAssertTrue(response.isCache);
        [callBackExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError *error) {
        if (error) {
            NSLog(@"%@", error);
        }
    }];
}


- (void)testBuildURLAndHeader {
    LAProtocalImpl<GitHubService> *service = [[LANetworkingBuilder initBuilderWithBlock:^(LANetworkingBuilder *builder) {
        builder.baseURL = [NSURL URLWithString:@"https://api.github.com"];
    }] create:@protocol(GitHubService)];
    RACSignal *signal = [service listRepository:@"huhk345" repo:@"LAFramework"];
    XCTAssertTrue(signal != nil);
    
    XCTestExpectation *callBackExpectation = [self expectationWithDescription:@"callback"];
    
    [signal subscribeNext:^(LAURLResponse *response) {
        XCTAssertTrue([[response.request.URL absoluteString] isEqualToString:@"https://api.github.com/repos/huhk345/LAFramework"]);
        XCTAssertTrue([response.request.allHTTPHeaderFields[@"Token"] isEqualToString:@"AABB-CCDD-EE"]);
        XCTAssertTrue([response.responseObject isKindOfClass:[NSDictionary class]]);
        [callBackExpectation fulfill];
    }];
    
    
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
        if (error) {
            NSLog(@"%@", error);
        }
    }];
}


- (void)testBuildHeader {
    LAProtocalImpl<GitHubService> *service = [[LANetworkingBuilder initBuilderWithBlock:^(LANetworkingBuilder *builder) {
        builder.baseURL = [NSURL URLWithString:@"https://api.github.com"];
    }] create:@protocol(GitHubService)];
    RACSignal *signal = [service listRepos:@"huhk345" token:@"LAFramework"];
    XCTAssertTrue(signal != nil);
    
    XCTestExpectation *callBackExpectation = [self expectationWithDescription:@"callback"];
    
    [signal subscribeNext:^(LAURLResponse *response) {
        XCTAssertTrue([[response.request.URL absoluteString] isEqualToString:@"https://api.github.com/users/huhk345/repos"]);
        XCTAssertTrue([[response.responseObject lastObject] isKindOfClass:[GithubRepo class]]);
        XCTAssertTrue([response.request.allHTTPHeaderFields[@"Token"] isEqualToString:@"LAFramework"]);
        [callBackExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError *error) {
        if (error) {
            NSLog(@"%@", error);
        }
    }];
}





@end
