//
//  UIWebView+Intercept.m
//  Pods
//
//  Created by LakeR on 16/7/18.
//
//

#import "UIWebView+Intercept.h"
#import <ObjC/runtime.h>
#import "WebViewURLIntercept.h"


@implementation UIWebView (Intercept)

+ (void)load{
    [self swizzlingInClass:self
          originalSelector:@selector(loadHTMLString:baseURL:)
          swizzledSelector:@selector(_loadHTMLString:baseURL:)];
}


+ (void)swizzlingInClass:(Class)cls originalSelector:(SEL)originalSelector swizzledSelector:(SEL)swizzledSelector{
    Class class = cls;
    
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    
    BOOL didAddMethod =
    class_addMethod(class,
                    originalSelector,
                    method_getImplementation(swizzledMethod),
                    method_getTypeEncoding(swizzledMethod));
    
    if (didAddMethod) {
        class_replaceMethod(class,
                            swizzledSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}


- (void) _loadHTMLString:(NSString *)htmlString baseURL:(NSURL *)baseURL{
    [self _loadHTMLString:[WebViewURLIntercept replaceString:htmlString] baseURL:baseURL];
}


@end