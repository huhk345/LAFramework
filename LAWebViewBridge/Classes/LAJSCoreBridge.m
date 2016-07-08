//
//  LAJSCoreBridge.m
//  Pods
//
//  Created by LakeR on 16/7/8.
//
//

#import "LAJSCoreBridge.h"
#import <JavaScriptCore/JavaScriptCore.h>
#import <ObjC/Runtime.h>

@interface LAJSCoreBridge()

@property (nonatomic,strong) JSContext *jsContext;

@end


@implementation LAJSCoreBridge

-(instancetype) initWithWebview:(UIWebView *)webView{
    if (self = [self init]) {
        _jsContext = [webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
        NSParameterAssert(_jsContext);
        [self registNativeMethods];
    }
    return self;
}


-(void)registNativeMethods{
    
    
    
    _jsContext[@"nativeLog"] =  ^(JSValue *logLevel, NSString *message){
        switch ([formatJSToOC(logLevel) intValue]) {
            case DDLogFlagError:
                DLogError(@"[JS] %@",message);
                break;
            case DDLogFlagWarning:
                DLogWarn(@"[JS] %@",message);
                break;
            case DDLogFlagInfo:
                DLogInfo(@"[JS] %@",message);
                break;
            case DDLogFlagDebug:
                DLogDebug(@"[JS] %@",message);
                break;
            case DDLogFlagVerbose:
                DLogVerbose(@"[JS] %@",message);
                break;
            default:
                DLogError(@"[JS] undefined log level!");
                break;
        }
    };
    
    
    _jsContext[@"callInstanceMethod"] = ^id(JSValue *instance, NSString *selectorName, JSValue *arguments){
        return callSelector(instance, nil, selectorName, arguments);
    };
    
    
    _jsContext[@"callClassMethod"] = ^id(NSString *className, NSString *selectorName, JSValue *arguments){
        return callSelector(nil, className, selectorName, arguments);
    };
    
    
    _jsContext[@"getProperty"] = ^id(NSString *className, NSString *selectorName, JSValue *arguments){
        return callSelector(nil, className, selectorName, arguments);
    };
    
    
    _jsContext[@"setProperty"] = ^id(NSString *className, NSString *selectorName, JSValue *arguments){
        return callSelector(nil, className, selectorName, arguments);
    };
    
}








#pragma mark - help methods
static id callSelector(JSValue *instance, NSString *className, NSString *selectorName, JSValue *arguments){
    if(instance && !className) {
        
    }
    else if(!instance && className){
        
    }
    
}


static id formatJSToOC(JSValue *jsval)
{
    id obj = [jsval toObject];
    if (!obj || [obj isKindOfClass:[NSNull class]]) return nil;
    
    if ([obj isKindOfClass:[NSArray class]]) {
        NSMutableArray *newArr = [[NSMutableArray alloc] init];
        for (int i = 0; i < [(NSArray*)obj count]; i ++) {
            [newArr addObject:formatJSToOC(jsval[i])];
        }
        return newArr;
    }
    if ([obj isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *newDict = [[NSMutableDictionary alloc] init];
        for (NSString *key in [obj allKeys]) {
            [newDict setObject:formatJSToOC(jsval[key]) forKey:key];
        }
        return newDict;
    }
    return obj;
}




@end
