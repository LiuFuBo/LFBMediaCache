//
//  NSString+LFBMD5.m
//  LFBMediaCacheDemo
//
//  Created by liufubo on 2019/10/29.
//  Copyright © 2019 liufubo. All rights reserved.
//

#import "NSString+LFBMD5.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSString (LFBMD5)

- (NSString *)lfb_md5 {
    const char* str = [self UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (CC_LONG)strlen(str), result);
    
    NSMutableString *ret = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH*2];
    for (int i=0; i<CC_MD5_DIGEST_LENGTH; i++) {
        [ret appendFormat:@"%02x",result[i]];
    }
    
    return ret;
}

@end
