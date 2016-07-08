//
//  ALDisk.h
//  ALSystem
//
//  Created by Andrea Mario Lufino on 19/07/13.
//  Copyright (c) 2013 Andrea Mario Lufino. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/*!
 * Check total and free disk space
 */
@interface LADisk : NSObject

/*!
 The total disk space in bytes
 @return CGFloat represents the total disk space in bytes
 */
+ (CGFloat)totalDiskSpaceInBytes;

/*!
 The free disk space in bytes
 @return CGFloat represents the free disk space in bytes
 */
+ (CGFloat)freeDiskSpaceInBytes;

/*!
 The used disk space in bytes
 @return CGFloat represents the used disk space in bytes
 */
+ (CGFloat)usedDiskSpaceInBytes;

@end
