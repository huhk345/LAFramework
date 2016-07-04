//
//  LAViewController.m
//  LAFramework
//
//  Created by 胡恒恺 on 07/01/2016.
//  Copyright (c) 2016 胡恒恺. All rights reserved.
//

#import "LAViewController.h"
#import <LAFramework/PFKeyValueCache.h>
#import "GitHubService.h"

@interface LAViewController ()


@end

@implementation LAViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [PFKeyValueCache shareInstance];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
