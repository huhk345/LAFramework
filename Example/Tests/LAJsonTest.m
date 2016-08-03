//
//  LAJsonTest.m
//  LAFramework
//
//  Created by LakeR on 16/7/27.
//  Copyright © 2016年 LakeR inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "GithubRepo.h"
#import "LAJsonTestObject.h"

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

- (void)testNilObject {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    GithubRepo *repo = [[GithubRepo alloc] init];
    NSDictionary *dic = [repo convertToDictionary:nil];
    XCTAssert([dic count] == 2);
}


- (void)testNilObjectWithOneProperty {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    GithubRepo *repo = [[GithubRepo alloc] init];
    repo.archive_url = @"testString";
    NSDictionary *dic = [repo convertToDictionary:nil];
    XCTAssert([dic count] == 2);
    XCTAssert([dic[@"archive_url"] isEqualToString:@"testString"]);
    XCTAssert([dic[@"assignees_url"] isKindOfClass:[NSNull class]]);
}


- (void)testComplexNilObject{
    LAJsonTestObject *object = [[LAJsonTestObject alloc] init];
    NSDictionary *dic = [object convertToDictionary:nil];
    XCTAssert([dic count] == 0);
}


- (void)testComplexObject{
    LAJsonTestObject *object = [[LAJsonTestObject alloc] init];
    object.aString = @"aString";
    object.mapProperty = @"mapString";
    object.ignore = @"ignore";
    object.aDate = [NSDate date];
    object.aDateTow = [NSDate date];
    object.aInteger = 1;
    
    NSDictionary *dic = [object convertToDictionary:nil];
    XCTAssert([dic count] == 5);
    XCTAssert([dic[@"aString"] isEqualToString:@"aString"]);
    XCTAssert([dic[@"aMapString"] isEqualToString:@"mapString"]);
    XCTAssert(dic[@"ignore"] == nil);
    XCTAssert([dic[@"aDate"] length] > 0);
    XCTAssert([dic[@"aDate2"] length] > 0);
    XCTAssert([dic[@"aInteger"] intValue] == 1);
    
}



- (void)testArrayObject{
    LAJsonTestObject *object = [[LAJsonTestObject alloc] init];
    object.aString = @"aString";
    object.mapProperty = @"mapString";
    object.ignore = @"ignore";
    object.aDate = [NSDate date];
    object.aDateTow = [NSDate date];
    object.aInteger = 1;
    
    GithubRepo *repo1 = [[GithubRepo alloc] init];
    repo1.archive_url = @"archive_url1";
    
    GithubRepo *repo2 = [[GithubRepo alloc] init];
    repo2.archive_url = @"archive_url2";
    repo2.assignees_url = @"assignees_url2";
    object.repos = @[repo1,repo2];
    
    
    NSDictionary *dic = [object convertToDictionary:nil];
    XCTAssert([dic count] == 6);
    XCTAssert([dic[@"aString"] isEqualToString:@"aString"]);
    XCTAssert([dic[@"aMapString"] isEqualToString:@"mapString"]);
    XCTAssert(dic[@"ignore"] == nil);
    XCTAssert([dic[@"aDate"] length] > 0);
    XCTAssert([dic[@"aDate2"] length] > 0);
    XCTAssert([dic[@"aInteger"] intValue] == 1);
    
    XCTAssert([dic[@"repos"] isKindOfClass:[NSArray class]]);
    XCTAssert([dic[@"repos"] count] == object.repos.count);
    
    XCTAssert([dic[@"repos"][1][@"archive_url"] isEqualToString:@"archive_url2"]);
    XCTAssert([dic[@"repos"][1][@"assignees_url"] isEqualToString:@"assignees_url2"]);

    
}


@end
