//
//  NSString+LAMD5.m
//  Pods
//
//  Created by LakeR on 16/6/29.
//
//

#import "NSString+LAMD5.h"
#include <CommonCrypto/CommonDigest.h>


@implementation NSString (LAMD5)


- (NSString *)LA_md5
{
    NSData* inputData = [self dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char outputData[CC_MD5_DIGEST_LENGTH];
    CC_MD5([inputData bytes], (unsigned int)[inputData length], outputData);
    
    NSMutableString* hashStr = [NSMutableString string];
    int i = 0;
    for (i = 0; i < CC_MD5_DIGEST_LENGTH; ++i)
        [hashStr appendFormat:@"%02x", outputData[i]];
    
    return hashStr;
}

@end
