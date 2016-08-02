//
//  LAJsonTestObject.h
//  LAFramework
//
//  Created by LakeR on 16/8/2.
//  Copyright © 2016年 LakeR inc. All rights reserved.
//


#import "LAJsonObject.h"

#undef  __CLASS__
#define __CLASS__ LAJsonTestObject

@interface LAJsonTestObject : LAJsonObject

@property (nonatomic,copy) NSString *aString;

@JsonMap("aMapString")
@property (nonatomic,copy) NSString *mapProperty;

@JsonIgnore
@property (nonatomic,copy) NSString *ignore;

@JsonFormat("LADate")
@property (nonatomic,strong) NSDate *aDate;

@JsonFormat("LADate")
@JsonMap("aDate2")
@property (nonatomic,strong) NSDate *aDateTow;

@JsonTypeReference("GithubRepo")
@property (nonatomic,strong) NSArray *repos;

@property (nonatomic,assign) NSInteger aInteger;



@end