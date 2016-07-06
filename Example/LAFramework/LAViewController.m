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
#import "ReactiveCocoa.h"
#import "LAURLResponse.h"


@interface LAViewController ()

@property (nonatomic,strong) id<GitHubService> service;

@end

@implementation LAViewController

- (void)viewDidLoad{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
