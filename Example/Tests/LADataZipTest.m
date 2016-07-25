//
//  LADataZipTest.m
//  LAFramework
//
//  Created by LakeR on 16/7/25.
//  Copyright © 2016年 LakeR inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NSData+Compression.h"

@interface LADataZipTest : XCTestCase

@end

@implementation LADataZipTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testDataZlib {
    NSString *testString = @"test string!";
    NSData *zlibData = [[testString dataUsingEncoding:NSUTF8StringEncoding] zlibDeflate];
    XCTAssertTrue([zlibData length] > 0);
    NSData *unZipData = [zlibData zlibInflate];
    XCTAssertTrue([unZipData length] > 0);
    XCTAssertTrue([[[NSString alloc] initWithData:unZipData encoding:NSUTF8StringEncoding] isEqualToString:@"test string!"]);
}


- (void)testDataGzip {
    NSString *testString = @"test string!";
    NSData *zlibData = [[testString dataUsingEncoding:NSUTF8StringEncoding] gzipDeflate];
    XCTAssertTrue([zlibData length] > 0);
    NSData *unZipData = [zlibData gzipInflate];
    XCTAssertTrue([unZipData length] > 0);
    XCTAssertTrue([[[NSString alloc] initWithData:unZipData encoding:NSUTF8StringEncoding] isEqualToString:@"test string!"]);
}

@end
