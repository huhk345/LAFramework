//
//  LAParameterResult.h
//  Pods
//
//  Created by 胡恒恺 on 16/7/4.
//  Copyright © 2016年 LakeR inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LAParameterResult<T> : NSObject

@property (nonatomic,strong) T result;
@property (nonatomic,strong) NSSet<NSString *> *consumedParameters;

-(instancetype)initWithResult:(T)result consumedParameters:(NSSet<NSString *> *)consumedParameters;

@end
