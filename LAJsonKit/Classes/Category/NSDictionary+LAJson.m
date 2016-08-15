//
//  NSDictionary+LAJson.m
//  Pods
//
//  Created by LakeR on 16/6/29.
//
//

#import "NSDictionary+LAJson.h"

@implementation NSDictionary (LAJson)

//TODO: convert custom Object to Dictionary in NSDictionary
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
