//
//  JSONValueTransformer+LAValueTransFormer.h
//  LAFramework
//
//  Created by LakeR on 16/8/2.
//  Copyright © 2016年 LakeR inc. All rights reserved.
//

#import "JSONValueTransformer.h"

@interface JSONValueTransformer (LAValueTransFormer)

- (NSDate *)LADateFromNSString:(NSString *)string;

- (NSString *)JSONObjectFromLADate:(NSDate *)date;

@end
