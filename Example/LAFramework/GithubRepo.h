//
//  GithubRepo.h
//  LAFramework
//
//  Created by LakeR on 16/7/6.
//  Copyright © 2016年 LakeR inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LAJsonObject.h"

@JsonIncludeNonNull
@interface GithubRepo : LAJsonObject

@property (nonatomic,copy) NSString *archive_url;

@property (nonatomic,copy) NSString *assignees_url;

@end
