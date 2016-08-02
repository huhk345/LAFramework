//
//  LAPropertyAnnotation.m
//  Pods
//
//  Created by LakeR on 16/8/1.
//
//

#import "LAPropertyAnnotation.h"

@implementation LAPropertyAnnotation


-(instancetype)initWithDictionary:(NSDictionary *)dic{
    self = [super init];
    if (self) {
        self.property = dic[@"JsonMap"];
        self.ignore = [dic[@"JsonIgnore"] boolValue];
        self.reformatter = dic[@"JsonFormat"];
        self.typeReference = dic[@"JsonTypeReference"];
    }
    return self;
}

@end
