//
//  NSInvocation+LAUtils.m
//  Pods
//
//  Created by LakeR on 16/7/5.
//  Copyright © 2016年 LakeR inc. All rights reserved.
//

#import "NSInvocation+LAUtils.h"
#import "NSArray+LAJson.h"
#import "NSDate+ISO8601.h"
#import "LAReformatter.h"

@implementation NSInvocation (LAUtils)



- (NSObject*)objectValueForParameterAtIndex:(NSUInteger)index error:(NSError **)error{
    // must increment past the first 2 implicit parameters
    index += 2;
    const char* type = [self.methodSignature getArgumentTypeAtIndex:index];
    NSObject *returnValue = nil;
    switch (type[0]) {
    #define LA_TYPEENCODE_CASE(_typeString, _type) \
    case _typeString: {                              \
        _type tempResultSet; \
        [self getArgument:&tempResultSet atIndex:index];\
        returnValue = @(tempResultSet); \
        break; \
    }
        LA_TYPEENCODE_CASE('s', short)
        LA_TYPEENCODE_CASE('S', unsigned short)
        LA_TYPEENCODE_CASE('i', int)
        LA_TYPEENCODE_CASE('I', unsigned int)
        LA_TYPEENCODE_CASE('l', long)
        LA_TYPEENCODE_CASE('L', unsigned long)
        LA_TYPEENCODE_CASE('q', long long)
        LA_TYPEENCODE_CASE('Q', unsigned long long)
        LA_TYPEENCODE_CASE('f', float)
        LA_TYPEENCODE_CASE('d', double)
        LA_TYPEENCODE_CASE('B', BOOL)
        case '*':{
            char *tempResultValue;
            [self getArgument:&tempResultValue atIndex:index];
            returnValue = [[NSString alloc] initWithUTF8String:tempResultValue];
            break;
        }
        case 'c':{
            char tempReulstValue;
            [self getArgument:&tempReulstValue atIndex:index];
            returnValue = [NSString stringWithFormat:@"%c",tempReulstValue];
            break;
        }
        case 'C':{
            unsigned char tempReulstValue;
            [self getArgument:&tempReulstValue atIndex:index];
            returnValue = [NSString stringWithFormat:@"%c",tempReulstValue];
            break;
        }
        case '@':{
            id tempReulstValue;
            [self getArgument:&tempReulstValue atIndex:index];
            if([tempReulstValue isKindOfClass:[NSDate class]]){
                returnValue = [tempReulstValue ISO8601StringUTC];
            }else if([tempReulstValue isKindOfClass:[NSNull class]] || [tempReulstValue isKindOfClass:[NSString class]]){
                returnValue = tempReulstValue;
            }else if([tempReulstValue conformsToProtocol:@protocol(LAObjectConvert)]){
                if([tempReulstValue respondsToSelector:@selector(convertToDictionary:)]){
                    returnValue = [tempReulstValue convertToDictionary:error];
                    if(error){
                        break;
                    }
                }else if([tempReulstValue respondsToSelector:@selector(convertToString:)]){
                    returnValue = [tempReulstValue convertToString:error];
                    if(error){
                        break;
                    }
                }else{
                    NSAssert(NO, @"unsupport object! please impl LAObjectConvert protocol!");
                }
            }
            break;
        }
        default:{
            NSAssert(NO, @"unsupport paramter type encode");
        }
        
    }
    if(returnValue == nil){
        returnValue = [NSNull null];
    }
    return returnValue;
}

- (NSString*)stringValueForParameterAtIndex:(NSUInteger)index error:(NSError **)error{
    id object = [self objectValueForParameterAtIndex:index error:error];
    NSString *returnVaule = nil;
    if([object isKindOfClass:[NSArray class]] || [object isKindOfClass:[NSDictionary class]] || [object isKindOfClass:[NSSet class]]){
        returnVaule = [object jsonString];
    }
    else if([object isKindOfClass:[NSNull class]]){
        returnVaule = @"";
    }
    else if([object isKindOfClass:[NSString class]]){
        returnVaule = object;
    }
    else{
        returnVaule = [NSString stringWithFormat:@"%@",returnVaule];
    }
    return returnVaule;
}
@end
