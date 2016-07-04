//
//  GitHubService.h
//  LAFramework
//
//  Created by LakeR on 16/7/3.
//  Copyright © 2016年 胡恒恺. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <LAFramework/LAWebService.h>

@protocol GitHubService <LAWebService>


GET("/path/someting")
- (LANSignal(NSString))fetchSomeThing:(NSString *)aa;
@end
