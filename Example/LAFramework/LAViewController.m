//
//  LAViewController.m
//  LAFramework
//
//  Created by LakeR on 07/01/2016.
//  Copyright (c) 2016 LakeR. All rights reserved.
//

#import "LAViewController.h"
#import <LAFramework/PFKeyValueCache.h>
#import "GitHubService.h"
#import <LAFramework/LANetworkingBuilder.h>
//#import <ReactiveCocoa/ReactiveCocoa.h>

@interface LAViewController ()


@end

@implementation LAViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [PFKeyValueCache shareInstance];
    
    id<GitHubService> service = [[LANetworkingBuilder initBuilderWithBlock:^(LANetworkingBuilder *builder) {
        builder.baseURL = [NSURL URLWithString:@"https://api.github.com"];
    }] create:@protocol(GitHubService)];
    [service fetchSomeThing:@"a" test:@"vvv" file:@"b"] ;
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
