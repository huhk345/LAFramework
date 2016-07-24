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
#import "UIDevice+Hardware.h"
#import "LAProcessor.h"

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

#pragma mark - Device Test

- (void)testPlatform{
#if TARGET_IPHONE_SIMULATOR
    XCTAssertTrue([[[UIDevice currentDevice] platform] containsString:@"x86"]);
#else
    XCTAssertTrue( [[UIDevice currentDevice] platform] != nil && ![[[UIDevice currentDevice] platform] containsString:@"x86"]);
#endif
}

- (void)testModel{
   XCTAssertTrue([[UIDevice currentDevice] hwmodel] != nil);
}


- (void)testPlatformType{
#if TARGET_IPHONE_SIMULATOR
    XCTAssertTrue([[UIDevice currentDevice] platformType] == UIDeviceSimulatoriPhone);
#else
    XCTAssertTrue([[UIDevice currentDevice] platformType] >=  UIDevice1GiPhone && [[UIDevice currentDevice] platformType] < UIDeviceUnknowniPhone);
#endif
}


- (void)testPlatformTypeString{
#if TARGET_IPHONE_SIMULATOR
    XCTAssertTrue([[[UIDevice currentDevice] platformString] isEqualToString:@"iPhone Simulator"]);
#else
    XCTAssertTrue(![[[UIDevice currentDevice] platformString] isEqualToString:@"iPhone Simulator"] &&
                  ![[[UIDevice currentDevice] platformString] isEqualToString:IOS_FAMILY_UNKNOWN_DEVICE]);
#endif
}


- (void)testMacAddress{
    XCTAssertTrue([[UIDevice currentDevice] macaddress] != nil);
}


- (void)testHasRetinaDisplay{
    XCTAssertTrue([[UIDevice currentDevice] hasRetinaDisplay]);
}


- (void)testDeviceFamily{
#if TARGET_IPHONE_SIMULATOR
    XCTAssertTrue([[UIDevice currentDevice] deviceFamily] == UIDeviceFamilyUnknown);
#else
    XCTAssertTrue([[UIDevice currentDevice] deviceFamily] == UIDeviceFamilyiPhone);
#endif
}

- (void)testDeviceId{
    XCTAssertTrue([[[UIDevice currentDevice] deviceId] length] != 0);
}

#pragma mark - Processor

- (void)testProcessorNumber{
    XCTAssertTrue([LAProcessor processorsNumber] > 0);
}


- (void)testActiveProcessorsNumber{
    XCTAssertTrue([LAProcessor activeProcessorsNumber] > 0);
}

- (void)testCpuUsageForApp{
    XCTAssertTrue([LAProcessor cpuUsageForApp] > 0);
}

- (void)testActiveProcesses{
    XCTAssertTrue([[LAProcessor activeProcesses] count] > 0);
}

- (void)testNumberOfActiveProcesses{
    XCTAssertTrue([LAProcessor numberOfActiveProcesses] > 0);
}

@end
