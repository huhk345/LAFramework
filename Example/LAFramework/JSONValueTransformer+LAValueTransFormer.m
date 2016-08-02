//
//  JSONValueTransformer+LAValueTransFormer.m
//  LAFramework
//
//  Created by LakeR on 16/8/2.
//  Copyright © 2016年 LakeR inc. All rights reserved.
//

#import "JSONValueTransformer+LAValueTransFormer.h"

@implementation JSONValueTransformer (LAValueTransFormer)

- (NSDate *)LADateFromNSString:(NSString *)string{
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateFormat = @"yyyy/MM/dd:HH/mm/ss";
    return [formatter dateFromString:string];
}

- (NSString *)JSONObjectFromLADate:(NSDate *)date{
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateFormat = @"yyyy/MM/dd:HH/mm/ss";
    return [formatter stringFromDate:date];
}



@end
