//
//  NSArray+LAJson.m
//  Pods
//
//  Created by LakeR on 16/6/29.
//
//

#import "NSArray+LAJson.h"
#import "LAReformatter.h"

@implementation NSArray (LAJson)

//TODO: convert custom Object to Dictionary in NSArray
- (NSString *)jsonString{
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[self __toDictionary] options:NSJSONWritingPrettyPrinted error:&error];
    if (!error) {
        return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    DLogError("Convert to  json String error : %@",error);
    return nil;
}


- (id)__toDictionary{
    NSMutableArray *array = [NSMutableArray array];
    for (id object in self) {
        if([object isKindOfClass:[NSString class]] || [object isKindOfClass:[NSNumber class]]){
            [array addObject:object];
        }else if([object respondsToSelector:@selector(__toDictionary)]){
            id value = [object __toDictionary];
            if(!value){
                DLogError(@"can not convert %@ to dictionary!",object);
                return nil;
            }
            [array addObject:value];
        }else if([object respondsToSelector:@selector(convertToDictionary:)]){
            NSError *error = nil;
            id value = [object convertToDictionary:&error];
            if(value == nil || error){
                DLogError(@"can not convert %@ to dictionary! \n error : %@ ",object,error);
                return nil;
            }
            [array addObject:value];
        }else {
            DLogError(@"array contains unsupport value %@",object);
            return nil;
        }
    }
    return array;
}


@end
