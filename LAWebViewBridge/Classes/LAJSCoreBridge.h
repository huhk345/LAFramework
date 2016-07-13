//
//  LAJSCoreBridge.h
//  Pods
//
//  Created by LakeR on 16/7/8.
//
//

#import <Foundation/Foundation.h>

@class JSContext;

#define LAJS_EXPORT(JS_name) __attribute__((used, section("__DATA,LAJSExport" \
))) static const char *__rct_export_entry__[] = { __func__, #JS_name }

@protocol LAJSCoreBridgeDelegate <NSObject>

@optional
-(id)getProperty:(NSString *)properyName;
-(void)setProperty:(NSString *)propertyName  value:(id)propertyValue;

@end


@interface LAJSCoreBridge : NSObject


-(instancetype)initWithWebview:(UIWebView *)webView;

-(instancetype)initWithWebview:(UIWebView *)webView delegate:(id<LAJSCoreBridgeDelegate>)delegate;

-(id)evaluateScript:(NSString *)script;

@end
