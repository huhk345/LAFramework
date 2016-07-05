//
//  NSSet+LAJson.m
//  Pods
//
//  Created by LakeR on 16/7/5.
//
//

#import "NSSet+LAJson.h"

@implementation NSSet (LAJson)

//TODO: convert custom Object to Dictionary in NSSet
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
