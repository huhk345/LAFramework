//
//  LASystemInfoTest.m
//  LAFramework
//
//  Created by LakeR on 16/7/22.
//  Copyright © 2016年 LakeR inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "LABattery.h"
#import "LACarrier.h"
#import "LADisk.h"
#import "LAMemory.h"

@interface LASystemInfoTest : XCTestCase

@end

@implementation LASystemInfoTest

- (void)setUp {
    [super setUp];
    [UIDevice currentDevice].batteryMonitoringEnabled = YES;
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

#pragma mark - battery test
- (void)testBatteryLevel{
#if TARGET_IPHONE_SIMULATOR
    XCTAssertTrue([LABattery batteryLevel] == -1);
#else
    XCTAssertFalse([LABattery LABattery] != -1);
#endif
}


- (void)testBatteryFullCharged{
#if TARGET_IPHONE_SIMULATOR
    XCTAssertFalse([LABattery batteryFullCharged]);
#else
    XCTAssertTrue([LABattery batteryFullCharged] == ([LABattery LABattery] == 100.0f));
#endif
}

- (void)testInCharge{
#if TARGET_IPHONE_SIMULATOR
    XCTAssertFalse([LABattery inCharge]);
#else
    XCTAssertTrue([LABattery inCharge]);
#endif
}

- (void)testDevicePluggedIntoPower{
#if TARGET_IPHONE_SIMULATOR
    XCTAssertFalse([LABattery devicePluggedIntoPower]);
#else
    XCTAssertTrue([LABattery devicePluggedIntoPower] || [LABattery batteryFullCharged]);
#endif
}

- (void)testBatteryState{
#if TARGET_IPHONE_SIMULATOR
    XCTAssertTrue([LABattery batteryState] == UIDeviceBatteryStateUnknown);
#else
    XCTAssertTrue([LABattery batteryState] != UIDeviceBatteryStateUnknown);
#endif
}

#pragma mark - Carrier test
- (void)testCarrierName{
#if TARGET_IPHONE_SIMULATOR
    XCTAssertTrue([LACarrier carrierName] == nil);
#else
    XCTAssertTrue([LACarrier carrierName] != nil);
#endif
}


- (void)testCellularInfo{
#if TARGET_IPHONE_SIMULATOR
    XCTAssertTrue([[LACarrier cellularInfo] isEqualToString:@""]);
#else
    XCTAssertFalse([[LACarrier cellularInfo] isEqualToString:@""]);
#endif
}




#pragma mark - Dist test
- (void)testTotalDiskSpaceInBytes{
    XCTAssertTrue([LADisk totalDiskSpaceInBytes] > 0);
}


- (void)testFreeDiskSpaceInBytes{
    XCTAssertTrue([LADisk freeDiskSpaceInBytes] > 0);
}

- (void)testUsedDiskSpaceInBytes{
    XCTAssertTrue([LADisk usedDiskSpaceInBytes] > 0);
}


#pragma mark - Memory test
- (void)testTotalMemory{
    XCTAssertTrue([LAMemory totalMemory] > 0);
}

- (void)testFreeMemory{
    XCTAssertTrue([LAMemory freeMemory] > 0);
}

- (void)testUsedMemory{
    XCTAssertTrue([LAMemory usedMemory] > 0);
}

- (void)testActiveMemory{
    XCTAssertTrue([LAMemory activeMemory] > 0);
}

- (void)testWiredMemory{
    XCTAssertTrue([LAMemory wiredMemory] > 0);
}

- (void)testInactiveMemory{
    XCTAssertTrue([LAMemory inactiveMemory] > 0);
}



@end
