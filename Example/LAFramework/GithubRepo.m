//
//  GithubRepo.m
//  LAFramework
//
//  Created by LakeR on 16/7/6.
//  Copyright © 2016年 LakeR inc. All rights reserved.
//

#import "GithubRepo.h"

@implementation GithubRepo

-(void)convertToObject:(NSDictionary *)dictionary{
    self.archive_url = dictionary[@"archive_url"];
    self.assignees_url = dictionary[@"assignees_url"];
}

@end
