//
//  LAJsonTest.m
//  LAFramework
//
//  Created by LakeR on 16/7/27.
//  Copyright © 2016年 LakeR inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "GithubRepo.h"

@interface LAJsonTest : XCTestCase

@end

@implementation LAJsonTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    GithubRepo *repo = [[GithubRepo alloc] init];
    [repo convertToDictionary:nil];
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
