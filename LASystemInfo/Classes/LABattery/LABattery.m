//
//  ALBattery.m
//  ALSystem
//
//  Created by Andrea Mario Lufino on 18/07/13.
//  Copyright (c) 2013 Andrea Mario Lufino. All rights reserved.
//

#import "LABattery.h"
#import <sys/utsname.h>

@interface LABattery ()

+ (UIDevice *)device;

@end

@implementation LABattery

#pragma mark - UIDevice

+ (UIDevice *)device {
    [UIDevice currentDevice].batteryMonitoringEnabled = YES;
    return [UIDevice currentDevice];
}

#pragma mark - Battery methods

+ (BOOL)batteryFullCharged {
    if ([self batteryLevel] == 100.00) {
        return YES;
    } else {
        return NO;
    }
}

+ (BOOL)inCharge {
    if ([self device].batteryState == UIDeviceBatteryStateCharging ||
        [self device].batteryState == UIDeviceBatteryStateFull) {
        return YES;
    } else {
        return NO;
    }
}

+ (BOOL)devicePluggedIntoPower {
    if ([self device].batteryState == UIDeviceBatteryStateUnplugged || [self device].batteryState == UIDeviceBatteryStateUnknown) {
        return NO;
    } else {
        return YES;
    }
}

+ (UIDeviceBatteryState)batteryState {
    return [self device].batteryState;
}

+ (CGFloat)batteryLevel {
    CGFloat batteryLevel = 0.0f;
    CGFloat batteryCharge = [self device].batteryLevel;
    if (batteryCharge > 0.0f)
        batteryLevel = batteryCharge * 100;
    else
        // Unable to find battery level
        return -1;
    
    return batteryLevel;
}


@end
