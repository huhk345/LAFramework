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
#import <LAFramework/LAURLResponse.h>
#import "ReactiveCocoa.h"
#import "AFHTTPSessionManager+rac.h"
#import "LAprotocolImpl.h"
#import "GithubRepo.h"
#import "LACache.h"
#import "OHHTTPStubs.h"
#import "OHPathHelpers.h"

@interface LANetworkTest : XCTestCase

@end

@implementation LANetworkTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
//    [[PFKeyValueCache shareInstance] removeAllObjects];
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.host isEqualToString:@"api.github.com"];
    } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
        if ([request.URL.path isEqualToString:@"/users/huhk345/repos"]) {
            NSString* fixture = OHPathForFile(@"repos.geojson", self.class);
            return [OHHTTPStubsResponse responseWithFileAtPath:fixture
                                                    statusCode:200
                                                       headers:@{@"Content-Type":@"application/json"}];
        } else if([request.URL.path isEqualToString:@"/repos/huhk345/LAFramework"]){
            NSString* fixture = OHPathForFile(@"repoDetail.geojson", self.class);
            return [OHHTTPStubsResponse responseWithFileAtPath:fixture
                                                    statusCode:200
                                                       headers:@{@"Content-Type":@"application/json"}];
        } else if([request.URL.path isEqualToString:@"/testPost"]){
            return [OHHTTPStubsResponse responseWithData:[@"{\"message\":0}" dataUsingEncoding:NSUTF8StringEncoding]
                                                  statusCode:200
                                                     headers:@{@"Content-Type":@"application/json"}];

        }
        else {
            NSError* error = [NSError errorWithDomain:NSURLErrorDomain code:kCFURLErrorBadURL userInfo:nil];
            return [OHHTTPStubsResponse responseWithError:error];
        }
        
    }];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testBuildURL {
    LAprotocolImpl<GitHubService> *service = [[LANetworkingBuilder initBuilderWithBlock:^(LANetworkingBuilder *builder) {
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
    LAprotocolImpl<GitHubService> *service = [[LANetworkingBuilder initBuilderWithBlock:^(LANetworkingBuilder *builder) {
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
    LAprotocolImpl<GitHubService> *service = [[LANetworkingBuilder initBuilderWithBlock:^(LANetworkingBuilder *builder) {
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
    LAprotocolImpl<GitHubService> *service = [[LANetworkingBuilder initBuilderWithBlock:^(LANetworkingBuilder *builder) {
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


- (void)testPostRawData{
    GithubRepo *repo1 = [[GithubRepo alloc] init];
    repo1.archive_url = @"archive_url1";
    
    GithubRepo *repo2 = [[GithubRepo alloc] init];
    repo2.archive_url = @"archive_url2";
    repo2.assignees_url = @"assignees_url2";
    NSArray *array = @[repo1,repo2];
    
    LAprotocolImpl<GitHubService> *service = [[LANetworkingBuilder initBuilderWithBlock:^(LANetworkingBuilder *builder) {
        builder.baseURL = [NSURL URLWithString:@"https://api.github.com"];
    }] create:@protocol(GitHubService)];
    
    XCTestExpectation *callBackExpectation = [self expectationWithDescription:@"callback"];
    [[service postRecord:array] subscribeNext:^(LAURLResponse *response) {
        XCTAssertTrue([[response.responseObject valueForKey:@"message"] integerValue] == 0);
        [callBackExpectation fulfill];
    } error:^(NSError *error) {
        
    }];
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError *error) {
        if (error) {
            NSLog(@"%@", error);
        }
    }];

}




@end
