//
//  GitHubService.h
//  LAFramework
//
//  Created by LakeR on 16/7/3.
//  Copyright © 2016年 LakeR. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <LAFramework/LAWebService.h>

@protocol GitHubService < LAWebService>



@GET("/users/{:user}/repos")
@Cache("1D")
- (LANSignal(GithubRepo))listRepos:(NSString*)user;


@GET("/repos/{:owner}/{:repo}")
@Headers({"Token":"AABB-CCDD-EE"})
- (LANSignal(void))listRepository:(NSString *)owner repo:(Part("repo") NSString *)arg;


@GET("/users/{:user}/repos")
@Headers({"Token":"{:token}"})
@Cache("1D")
- (LANSignal(GithubRepo))listRepos:(NSString*)user token:(NSString *)token;



@POST("/testPost")
@FormRaw
- (LANSignal(void))postRecord:(Part("rawData") NSArray *)array;

@end
