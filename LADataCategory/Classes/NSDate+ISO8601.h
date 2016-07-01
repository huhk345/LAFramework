//
//  NSDate+ISO8601.h
//  Pods
//
//  Created by 胡恒恺 on 16/6/29.
//
//

#import <Foundation/Foundation.h>

@interface NSDate (ISO8601)

+ (instancetype)dateWithISO8601String:(NSString *)iso8601string;

- (NSString *)ISO8601String;
- (NSString *)ISO8601StringUTC;

@end
