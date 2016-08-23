//
//  NSBundle+Framework.m
//  Pods
//
//  Created by LakeR on 16/8/23.
//
//

#import "NSBundle+Framework.h"

@implementation NSBundle (Framework)

+(instancetype)frameworkBundle:(NSString *)framework{
    NSBundle *frameworkBundle = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:framework
                                                                                         ofType:@"framework"
                                                                                    inDirectory:@"Frameworks"]];
    return [NSBundle bundleWithPath:[frameworkBundle pathForResource:framework ofType:@"bundle"]];
}

@end
