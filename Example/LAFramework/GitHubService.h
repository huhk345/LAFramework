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


@GET("/path/{:file}/something")
@FormData
@Headers({"Accept": "someThing", "User-Agent": "Sample-App"})
@Cache("1D")
- (LANSignal(NSString))fetchSomeThing:(Part("aaa") NSString *)aa
                                 test:(NSArray *)file
                                 file:(Part("bbb") NSString *)bb;


@end
