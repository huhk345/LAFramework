# LAFramework

![CI Status](https://img.shields.io/travis/huhk345/LAFramework.svg?branch=master&style=flat)
![codecov.io](https://codecov.io/github/huhk345/LAFramework/branch/master/graphs/badge.svg)

Base framework for iOS, inspired by Retrofit、Restless、JSPatch、Weex ...

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Installation

LAFramework is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'LAFramework' , :git => 'git@github.com:huhk345/LAFramework.git’

post_install do |installer|
    require File.expand_path('runscript.rb', './Pods/LAFramework/LAFramework')
    RunScriptConfigurator::post_install(installer)
end
```

## Introduction

###LANetworking###

Just define a protocol that inherits from `LAWebService`.

```objective-c
@GET("/users/{:user}/repos")
@Cache("1D")
- (LANSignal(GithubRepo))listRepos:(NSString*)user;


@GET("/repos/{:owner}/{:repo}")
@Headers({"Token":"AABB-CCDD-EE"})
- (LANSignal(void))listRepository:(NSString *)owner repo:(Part("repo") NSString *)arg;
```


The `LANetworkingBuilder` class generates an implementation of the `GitHubService` protocol.

```objective-c
id<GitHubService> service = [[LANetworkingBuilder initBuilderWithBlock:^(LANetworkingBuilder *builder) {
    builder.baseURL = [NSURL URLWithString:@"https://api.github.com"];
}] create:@protocol(GitHubService)];
```

Each `RACSignal` returned from the created `GitHubService` can make an asynchronous HTTP request to the remote webserver.

```objective-c
[[service listRepos:@"huhk345"] subscribeNext:^(LAURLResponse *response) {
    NSLog(@"reponse %@",response.responseObject);
}];


[[service listRepository:@"huhk345" repo:@"LAFramework"] subscribeNext:^(LAURLResponse *response) {
    NSLog(@"reponse %@",response.responseObject);
}];
```

###LAJsonKit###
Create a new Objective-C class for your data model and make it inherit the LAJsonObject class.
Declare properties in your header file with the name of the JSON keys:

```objective-c
@interface GithubRepo : LAJsonObject

@property (nonatomic,copy) NSString *archive_url;
@property (nonatomic,copy) NSString *assignees_url;

@end
```

Use annotations to modify the property
```objective-c
#undef  __CLASS__
#define __CLASS__ LAJsonTestObject

@interface LAJsonTestObject : LAJsonObject

@property (nonatomic,copy) NSString *aString;

@JsonMap("aMapString")
@property (nonatomic,copy) NSString *mapProperty;

@JsonIgnore
@property (nonatomic,copy) NSString *ignore;

@property (nonatomic,strong) NSDate *aDate;

@JsonFormat("LADate")
@JsonMap("aDate2")
@property (nonatomic,strong) NSDate *aDateTow;

@JsonTypeReference("GithubRepo")
@property (nonatomic,strong) NSArray *repos;

@property (nonatomic,assign) NSInteger aInteger;

@end
```

Custom data transformers
```objective-c
@implementation JSONValueTransformer (LAValueTransFormer)

- (NSDate *)LADateFromNSString:(NSString *)string{
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateFormat = @"yyyy/MM/dd:HH/mm/ss";
    return [formatter dateFromString:string];
}

- (NSString *)JSONObjectFromLADate:(NSDate *)date{
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateFormat = @"yyyy/MM/dd:HH/mm/ss";
    return [formatter stringFromDate:date];
}
@end
```


## Author

LakeR,njlaker@gmail.com	

## License

LAFramework is available under the MIT license. See the LICENSE file for more info.
