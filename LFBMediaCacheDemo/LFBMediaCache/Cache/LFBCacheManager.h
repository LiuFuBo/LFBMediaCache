//
//  LFBCacheManager.h
//  LFBMediaCacheDemo
//
//  Created by liufubo on 2019/10/28.
//  Copyright © 2019 liufubo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LFBCacheConfiguration.h"


extern NSString *LFBCacheManagerDidUpdateCacheNotification;
extern NSString *LFBCacheManagerDidFinishCacheNotification;

extern NSString *LFBCacheConfigurationKey;
extern NSString *LFBCacheFinishedErrorKey;

@interface LFBCacheManager : NSObject

+ (void)setCacheDirectory:(NSString *)cacheDirectory;
+ (NSString *)cacheDirectory;

/** 设置多久触发一次缓存更新通知 */
+ (void)setCacheUpdateNotifyInterval:(NSTimeInterval)interval;
+ (NSTimeInterval)cacheUpdateNotifyInterval;

+ (NSString *)cachedFilePathForURL:(NSURL *)url;
+ (LFBCacheConfiguration *)cacheConfigurationForURL:(NSURL *)url;

+ (void)setFileNameRules:(NSString *(^)(NSURL *url))rules;


/**
 * 估算缓存文件大小
 @param error if error not empty, calculate failed
 @return files size,respresent by 'byte', if error occurs, return -1
 */
+ (unsigned long long)calculateCachedSizeWithError:(NSError **)error;
+ (void)cleanAllCacheWithError:(NSError **)error;
+ (void)cleanCacheForURL:(NSURL *)url error:(NSError **)error;



/**
 * 上传本地文件到服务器时使用
 @param filePath local file path
 @param url remote resouce url
 @param error On input, a pointer to an error object. if an error occurs, this pointer is set to an actual error object containing the error information
 */
+ (BOOL)addCacheFile:(NSString *)filePath forURL:(NSURL *)url error:(NSError **)error;

@end


