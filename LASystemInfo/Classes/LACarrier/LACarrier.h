//
//  ALCarrier.h
//  ALSystem
//
//  Created by Andrea Mario Lufino on 21/07/13.
//  Copyright (c) 2013 Andrea Mario Lufino. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 * This class provides method to get info about the carrier
 */
@interface LACarrier : NSObject

/*!
 The carrier name
 @return NSString represents the carrier name
 */
+ (NSString *)carrierName;


+ (NSString *)cellularInfo;

@end
