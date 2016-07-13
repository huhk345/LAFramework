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

@interface LAViewController ()<LAJSCoreBridgeDelegate,UIWebViewDelegate>

@property (nonatomic,weak) UIWebView *webView;
@property (nonatomic,strong) LAJSCoreBridge *bridge;
@property (nonatomic,strong) UIButton *button;
@property (nonatomic,strong) NSDate* date;

@end

@implementation LAViewController

- (void)viewDidLoad{
    [super viewDidLoad];
    UIWebView *webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:webView];
    self.webView = webView;
    self.bridge = [[LAJSCoreBridge alloc] initWithWebview:webView delegate:self];
    
    NSString* htmlPath = [[NSBundle mainBundle] pathForResource:@"ExampleApp" ofType:@"html"];
    NSString* appHtml = [NSString stringWithContentsOfFile:htmlPath encoding:NSUTF8StringEncoding error:nil];
    NSURL *baseURL = [NSURL fileURLWithPath:htmlPath];
//    [webView loadHTMLString:appHtml baseURL:baseURL];
    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.sina.com.cn"]]];
    webView.delegate = self;
    self.button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    [self.view addSubview:self.button];
    self.button.backgroundColor = [UIColor redColor];
    [self.button setTitle:@"aa" forState:UIControlStateNormal];
    NSLog(@"%@",self.button.titleLabel.text);
//    [self.button titleForState:UIControlStateNormal];
    
    self.date = [NSDate date];
    
    
    
    
}


- (void)webViewDidFinishLoad:(UIWebView *)webView{
    NSLog(@"%f",[[NSDate date] timeIntervalSinceDate:self.date]);
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
