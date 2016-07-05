//
//  NSInvocation+LAUtils.h
//  Pods
//
//  Created by LakeR on 16/7/5.
//  Copyright © 2016年 LakeR inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSInvocation (LAUtils)

- (NSObject*)objectValueForParameterAtIndex:(NSUInteger)index error:(NSError **)error;

- (NSString*)stringValueForParameterAtIndex:(NSUInteger)index error:(NSError **)error;

@end
