//
//  LAParameterResult.m
//  Pods
//
//  Created by 胡恒恺 on 16/7/4.
//  Copyright © 2016年 LakeR inc. All rights reserved.
//

#import "LAParameterResult.h"

@implementation LAParameterResult

-(instancetype)initWithResult:(id)result consumedParameters:(NSSet<NSString *> *)consumedParameters{
    self = [self init];
    if (self) {
        self.result = result;
        self.consumedParameters = consumedParameters;
    }
    return self;
}

@end
