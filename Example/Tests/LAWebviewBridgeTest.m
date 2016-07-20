//
//  LAWebviewBridgeTest.m
//  LAFramework
//
//  Created by LakeR on 16/7/15.
//  Copyright © 2016年 LakeR inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "LACache.h"

@interface LAWebviewBridgeTest : XCTestCase

@end

@implementation LAWebviewBridgeTest

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
}


- (void)testPerformanceExample {
    // This is an example of a performance test case.
    NSArray *urls = @[@"http://www.apple.com/",
                     @"http://www.apple.com/ac/globalnav/2.0/en_US/scripts/ac-globalnav.built.js",
                     @"http://www.apple.com/ac/globalfooter/2.0/en_US/scripts/ac-globalfooter.built.js",
                     @"http://images.apple.com/v/home/cr/built/scripts/head.built.js",
                     @"http://www.apple.com/metrics/ac-analytics/1.1/scripts/ac-analytics.js",
                     @"http://www.apple.com/metrics/ac-analytics/1.1/scripts/auto-init.js",
                     @"http://images.apple.com/v/home/cr/built/scripts/main.built.js"];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\w+\\s*\\.jb_\\w+\\s*\(([^)]*)\\)" options:0 error:nil];
    //first load data to memory
    for (NSString *url in urls) {
        [[PFKeyValueCache shareInstance] objectForKey:url];
    }
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
        for (NSString *url in urls) {
            NSData *data = (NSData *)[[PFKeyValueCache shareInstance] objectForKey:url];
            NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            string = [regex stringByReplacingMatchesInString:string options:0 range:NSMakeRange(0, string.length) withTemplate:@""];
            data = [string dataUsingEncoding:NSUTF8StringEncoding];
        }
    }];
}

@end
