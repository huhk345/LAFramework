//
//  ALBattery.h
//  ALSystem
//
//  Created by Andrea Mario Lufino on 18/07/13.
//  Copyright (c) 2013 Andrea Mario Lufino. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
/*!
 * This class is useful to retrieve informations about the battery status
 */

@interface LABattery : NSObject

/*!
 ----------------------------
 /// @name Methods
 ----------------------------
 */

/*!
 Check if the battery is fully charged
 @return YES if the battery is fully charged, NO if it isn't
 */
+ (BOOL)batteryFullCharged;

/*!
 Check if the battery is charging
 @return YES if the battery is charging, NO if it isn't
 */
+ (BOOL)inCharge;

/*!
 Check if the device is plugged into power
 @return YES if the device is plugged into power, NO if it isn't
 */
+ (BOOL)devicePluggedIntoPower;

/*!
 The battery state of the device
 @return UIDeviceBatteryState value which represent the current status of the battery
 */
+ (UIDeviceBatteryState)batteryState;

/*!
 Retrieve the battery level of the battery
 @return A CGFloat value which represents the current battery level
 */
+ (CGFloat)batteryLevel;
@end
