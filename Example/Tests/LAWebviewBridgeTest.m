//
//  LAWebviewBridgeTest.m
//  LAFramework
//
//  Created by LakeR on 16/7/15.
//  Copyright © 2016年 LakeR inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "LACache.h"
#import "LAWebViewBridge.h"

@interface LAWebviewBridgeTest : XCTestCase<LAJSCoreBridgeDelegate>

@property (nonatomic,strong) UIButton *button;

@end

@implementation LAWebviewBridgeTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.button = [[UIButton alloc] initWithFrame:CGRectZero];
    [self.button setTitle:@"test1" forState:UIControlStateNormal];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testJSCoreBridgeCreate {
    UIWebView *webView = [[UIWebView alloc] initWithFrame:CGRectZero];
    LAJSCoreBridge *bridge = [[LAJSCoreBridge alloc] initWithWebview:webView];
    XCTAssertTrue(bridge != nil);
}

- (void)testJSStringReplace{
    UIWebView *webView = [[UIWebView alloc] initWithFrame:CGRectZero];
    LAJSCoreBridge *bridge = [[LAJSCoreBridge alloc] initWithWebview:webView delegate:self];
    XCTAssertTrue(bridge != nil);
    NSString* htmlPath = [[NSBundle bundleForClass:self.class] pathForResource:@"ExampleApp" ofType:@"html"];
    NSString* appHtml = [NSString stringWithContentsOfFile:htmlPath encoding:NSUTF8StringEncoding error:nil];
    [webView loadHTMLString:appHtml baseURL:nil];
    XCTestExpectation *callBackExpectation = [self expectationWithDescription:@"callback"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [callBackExpectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:1 handler:^(NSError * _Nullable error) {
        XCTAssertTrue([[self.button titleForState:UIControlStateNormal] isEqualToString:@"jsButton"]);
    }];
}


- (void)testSetProperty{
    self.button = nil;
    UIWebView *webView = [[UIWebView alloc] initWithFrame:CGRectZero];
    LAJSCoreBridge *bridge = [[LAJSCoreBridge alloc] initWithWebview:webView delegate:self];
    XCTAssertTrue(bridge != nil);
    NSString* htmlPath = [[NSBundle bundleForClass:self.class] pathForResource:@"SetpropertyTest" ofType:@"html"];
    NSString* appHtml = [NSString stringWithContentsOfFile:htmlPath encoding:NSUTF8StringEncoding error:nil];
    [webView loadHTMLString:appHtml baseURL:nil];
    XCTestExpectation *callBackExpectation = [self expectationWithDescription:@"callback"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [callBackExpectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:1 handler:^(NSError * _Nullable error) {
        XCTAssertTrue(self.button != nil);
    }];
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
