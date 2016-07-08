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
#import "LAJSCoreBridge.h"

@interface LAViewController ()

@property (nonatomic,weak) UIWebView *webView;
@property (nonatomic,strong) LAJSCoreBridge *bridge;

@end

@implementation LAViewController

- (void)viewDidLoad{
    [super viewDidLoad];
    UIWebView *webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:webView];
    self.webView = webView;
    self.bridge = [[LAJSCoreBridge alloc] initWithWebview:webView];
    
    NSString* htmlPath = [[NSBundle mainBundle] pathForResource:@"ExampleApp" ofType:@"html"];
    NSString* appHtml = [NSString stringWithContentsOfFile:htmlPath encoding:NSUTF8StringEncoding error:nil];
    NSURL *baseURL = [NSURL fileURLWithPath:htmlPath];
    [webView loadHTMLString:appHtml baseURL:baseURL];
    
    
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
