//
//  NSArray+LAJson.m
//  Pods
//
//  Created by 胡恒恺 on 16/6/29.
//
//

#import "NSArray+LAJson.h"

@implementation NSArray (LAJson)

- (NSString *)jsonString{
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self options:NSJSONWritingPrettyPrinted error:&error];
    if (!error) {
        return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    DLogError("Convert to  json String error : %@",error);
    return nil;
}


@end
