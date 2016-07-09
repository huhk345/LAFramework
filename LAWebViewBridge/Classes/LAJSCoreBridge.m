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
@property (nonatomic,weak) id delegate;

@end


@implementation LAJSCoreBridge

-(instancetype) initWithWebview:(UIWebView *)webView{
    return [self initWithWebview:webView delegate:nil];
}


-(instancetype)initWithWebview:(UIWebView *)webView delegate:(id<LAJSCoreBridgeDelegate>)delegate{
    if (self = [self init]) {
        _jsContext = [webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
        NSParameterAssert(_jsContext);
        self.delegate = delegate;
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
    
    
    _jsContext[@"dispatch_async_main"] = ^void(JSValue *function){
        dispatch_async(dispatch_get_main_queue(), ^{
            [function callWithArguments:nil];
        });
    };
    
    _jsContext[@"dispatch_sync_main"] = ^void(JSValue *function){
        dispatch_sync(dispatch_get_main_queue(), ^{
            [function callWithArguments:nil];
        });
    };
    
    _jsContext[@"dispatch_async_global_queue"] = ^void(JSValue *function){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [function callWithArguments:nil];
        });
    };
    
    
    @weakify(self)
    _jsContext[@"getProperty"] = ^id(NSString *propertyName){
        @strongify(self)
        if([self.delegate respondsToSelector:@selector(getProperty:)]){
            return [self.delegate getProperty:propertyName];
        }else{
            return [self.delegate valueForKey:propertyName];
        }
    };
    
    
    _jsContext[@"setProperty"] = ^(NSString *propertyName,JSValue *propertyValue){
        @strongify(self)
        
        if([self.delegate respondsToSelector:@selector(setProperty:value:)]){
            [self.delegate setProperty:propertyName value:formatJSToOC(propertyValue)];
        }else{
            [self.delegate setValue:formatJSToOC(propertyValue) forKey:propertyName];
        }
    };
    
    
    _jsContext.exceptionHandler = ^(JSContext *con, JSValue *exception) {
        DLogError(@"[JS] %@",exception);
    };
}








#pragma mark - help methods
static id callSelector(JSValue *instance, NSString *className, NSString *selectorName, JSValue *jsArguments){
    if(instance && !className) {
       
        NSString *selectorString = [selectorName stringByReplacingOccurrencesOfString:@"_" withString:@":"];
        NSMethodSignature *methodSignature = [[formatJSToOC(instance) class] instanceMethodSignatureForSelector:NSSelectorFromString(selectorString)];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
        [invocation setTarget:[instance toObject]];
        [invocation setSelector:NSSelectorFromString(selectorString)];
        NSArray *arguments = [jsArguments toArray];
        for(int i = 0;i < [arguments count]; i++){
            const char *encode = [methodSignature getArgumentTypeAtIndex:i+2];
            switch (encode[0]) {
                #define LA_TYPEENCODE_CASE(_typeString, _type)              \
                    case _typeString: {                                     \
                    _type tempValue;                                        \
                    NSNumber *value = arguments[i];                         \
                    if([value isKindOfClass:[NSNumber class]]){             \
                        tempValue = (_type)[value doubleValue];             \
                        [invocation setArgument:&tempValue atIndex:i+2];    \
                    }                                                       \
                    else {                                                  \
                        DLogError(@"can not convert number");               \
                    }                                                       \
                    break;                                                  \
                }
                    
                    
                LA_TYPEENCODE_CASE('s', short)
                LA_TYPEENCODE_CASE('S', unsigned short)
                LA_TYPEENCODE_CASE('i', int)
                LA_TYPEENCODE_CASE('I', unsigned int)
                LA_TYPEENCODE_CASE('l', long)
                LA_TYPEENCODE_CASE('L', unsigned long)
                LA_TYPEENCODE_CASE('q', long long)
                LA_TYPEENCODE_CASE('Q', unsigned long long)
                LA_TYPEENCODE_CASE('f', float)
                LA_TYPEENCODE_CASE('d', double)
                LA_TYPEENCODE_CASE('B', BOOL)
                case '*':{
                    NSString *value = arguments[i];
                    char *tempResultValue = [value UTF8String];
                    [invocation setArgument:&tempResultValue atIndex:i+2];
                    break;
                }
                case 'c':
                case 'C':{
                    NSString *value = arguments[i];
                    char *tempResultValue = [value UTF8String];
                    [invocation setArgument:&tempResultValue[0] atIndex:i+2];
                    break;
                }
                case '@':{
                    id tempReulstValue = arguments[i];
                    if([tempReulstValue isKindOfClass:[NSNull class]]){
                        tempReulstValue = nil;
                    }
                    [invocation setArgument:&tempReulstValue atIndex:i+2];
                    break;
                }
                default:{
                    DLogError(@"unsupport value type");
                }
            }
        }
        [invocation invoke];
    }
    else if(!instance && className){
        
    }
    return nil;
    
    
}








static id formatJSToOC(JSValue *jsval){
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
