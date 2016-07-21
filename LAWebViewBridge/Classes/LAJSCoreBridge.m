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


static NSString * patchString = @"          "
"           var OCClass = function(clsNames) {"
"               var tempObject = {};"
"               tempObject['OCObject'] = clsNames;"
"               tempObject['OCClass'] = true;"
"               return tempObject;"
"           };"
"           var _customMethods = {"
"               __callNative : function(methodName) {"
"                   var instance = this;"
"                   var selectorName = methodName;"
"                   methodName = methodName.replace(/__/g, \"-\");"
"                   selectorName = methodName.replace(/_/g, \":\").replace(/-/g, \"_\");"
"                   var marchArr = selectorName.match(/:/g);"
"                   return function(){"
"                       var args = Array.prototype.slice.call(arguments);"
"                       var numOfArgs = marchArr ? marchArr.length : 0;"
"                       if (args.length > numOfArgs) {"
"                           selectorName += \":\";"
"                       }"
"                       if(instance.OCClass === undefined || instance.OCClass == false){"
"                           return callInstanceMethod(instance,selectorName,args);"
"                       }else{"
"                           return callClassMethod(instance.OCObject,selectorName,args);"
"                       }"
"                   }"
"               }"
"           };"
"           for (var method in _customMethods) {"
"               if (_customMethods.hasOwnProperty(method)) {"
"                   Object.defineProperty(Object.prototype, method, {value: _customMethods[method], configurable:false, enumerable: false});"
"               }"
"           }";


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
        [_jsContext evaluateScript:patchString];
    }
    return self;
}

-(void)registNativeMethods{
    
    _jsContext[@"nativeLog"] =  ^(JSValue *logLevel, NSString *message){
        switch ([formatJSToOC(logLevel) intValue]) {
            case DDLogFlagError:
                DLogError(@"[JS ERR] %@",message);
                break;
            case DDLogFlagWarning:
                DLogWarn(@"[JS WAR] %@",message);
                break;
            case DDLogFlagInfo:
                DLogInfo(@"[JS INFO] %@",message);
                break;
            case DDLogFlagDebug:
                DLogDebug(@"[JS DEBUG] %@",message);
                break;
            case DDLogFlagVerbose:
                DLogVerbose(@"[JS VER] %@",message);
                break;
            default:
                DLogError(@"[JS ERR] undefined log level!");
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
        if ([propertyName isEqualToString:@"self"]) {
            return self;
        }
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


-(id)evaluateScript:(NSString *)script{
    return [_jsContext evaluateScript:script];
}


#pragma mark - help methods
static id callSelector(JSValue *instance, NSString *className, NSString *selectorName, JSValue *jsArguments){
    NSMethodSignature *methodSignature;
    NSInvocation *invocation;
    NSString *selectorString = [selectorName stringByReplacingOccurrencesOfString:@"_" withString:@":"];
    if(instance && !className) {
        methodSignature = [[formatJSToOC(instance) class] instanceMethodSignatureForSelector:NSSelectorFromString(selectorString)];
        invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
        [invocation setTarget:[instance toObject]];
    }
    else if(!instance && className){
        Class cls = NSClassFromString(className);
        methodSignature = [cls methodSignatureForSelector:NSSelectorFromString(selectorString)];
        invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
        [invocation setTarget:cls];
    }
    
    [invocation setSelector:NSSelectorFromString(selectorString)];
    NSArray *arguments = [jsArguments toArray];
    for(int i = 0;i < [arguments count] && i + 2 < [methodSignature numberOfArguments]; i++){
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
                if (tempResultValue != nil && strlen(tempResultValue) > 0) {
                    [invocation setArgument:&(tempResultValue[0]) atIndex:i+2];
                }
                else{
                    char emptyChar = "";
                    [invocation setArgument:&emptyChar atIndex:i+2];
                }
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
//process return value;
    const char *returnEncode = methodSignature.methodReturnType;
    switch (returnEncode[0]) {
    #define LA_RETURN_ENCODE_CASE(_typeString, _type)              \
        case _typeString: {                                     \
            _type tempValue;                                    \
            [invocation getReturnValue:&tempValue];             \
            NSNumber *value = @(tempValue);                     \
            return value;                                       \
        }
            
            LA_RETURN_ENCODE_CASE('s', short)
            LA_RETURN_ENCODE_CASE('S', unsigned short)
            LA_RETURN_ENCODE_CASE('i', int)
            LA_RETURN_ENCODE_CASE('I', unsigned int)
            LA_RETURN_ENCODE_CASE('l', long)
            LA_RETURN_ENCODE_CASE('L', unsigned long)
            LA_RETURN_ENCODE_CASE('q', long long)
            LA_RETURN_ENCODE_CASE('Q', unsigned long long)
            LA_RETURN_ENCODE_CASE('f', float)
            LA_RETURN_ENCODE_CASE('d', double)
            LA_RETURN_ENCODE_CASE('B', BOOL)
        case '*':{
            char *tempResultValue = malloc(sizeof(char) * methodSignature.methodReturnLength);
            [invocation getReturnValue:&tempResultValue];
            NSString *value = [[NSString alloc] initWithBytes:tempResultValue
                                                       length:methodSignature.methodReturnLength
                                                     encoding:NSUTF8StringEncoding];
            return value;
        }
        case 'c':
        case 'C':{
            char tempResultValue;
            [invocation getReturnValue:&tempResultValue];
            NSString *value = [NSString stringWithFormat:@"%c",tempResultValue];
            return value;
        }
        case '@':{
            void *value;
            [invocation getReturnValue:&value];
            if ([selectorName isEqualToString:@"alloc"] || [selectorName isEqualToString:@"new"] ||
                [selectorName isEqualToString:@"copy"] || [selectorName isEqualToString:@"mutableCopy"]) {
                return (__bridge_transfer id)value;
            } else {
                return (__bridge id)value;
            }
        }
        case 'v':{
            return nil;
        }
        default:{
            DLogError(@"unsupport return value type");
            return nil;
        }
    }

    
    
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
