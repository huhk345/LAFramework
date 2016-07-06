//
//  GitHubService.h
//  LAFramework
//
//  Created by LakeR on 16/7/3.
//  Copyright © 2016年 LakeR. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <LAFramework/LAWebService.h>

@protocol GitHubService <LAWebService>



@GET("/users/{:user}/repos")
@Cache("1D")
- (LANSignal(GithubRepo))listRepos:(NSString*)user;


@end
