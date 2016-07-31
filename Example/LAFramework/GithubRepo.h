//
//  GithubRepo.h
//  LAFramework
//
//  Created by LakeR on 16/7/6.
//  Copyright © 2016年 LakeR inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LAJsonObject.h"



#undef  __CLASS__
#define __CLASS__ GithubRepo

@JsonIncludeNonNull
@interface GithubRepo : LAJsonObject{
    

    NSUInteger aInteger;
}

@JsonMap("atest")
@JsonFormat("yyyy-mm-dd")
@property (nonatomic,copy) NSString *archive_url;


@JsonMap("bbb")
@property (nonatomic,copy) NSString<NSObject> *assignees_url;


@property (nonatomic,copy) int (^IntBlock)();

@JsonIgnore
@property (nonatomic,assign) NSInteger integerValue;


@property (nonatomic,copy) UIColor *color;
@end
