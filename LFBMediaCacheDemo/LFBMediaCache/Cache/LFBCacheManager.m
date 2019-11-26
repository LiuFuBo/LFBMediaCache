//
//  LFBCacheManager.m
//  LFBMediaCacheDemo
//
//  Created by liufubo on 2019/10/28.
//  Copyright © 2019 liufubo. All rights reserved.
//

#import "LFBCacheManager.h"
#import "LFBMediaDownloader.h"
#import "NSString+LFBMD5.h"

NSString *LFBCacheManagerDidUpdateCacheNotification = @"LFBCacheManagerDidUpdateCacheNotification";
NSString *LFBCacheManagerDidFinishCacheNotification = @"LFBCacheManagerDidFinishCacheNotification";

NSString *LFBCacheConfigurationKey = @"LFBCacheConfigurationKey";
NSString *LFBCacheFinishedErrorKey = @"LFBCacheFinishedErrorKey";

static NSString *kMCMediCacheDirectory;
static NSTimeInterval kMCMediaCacheNotifyInterval;
static NSString *(^kMCFileNameRules)(NSURL *url);

@implementation LFBCacheManager

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        //创建临时换粗目录
        [self setCacheDirectory:[NSTemporaryDirectory() stringByAppendingPathComponent:@"lfbmedia"]];
        //设置更新缓存的时间间隔
        [self setCacheUpdateNotifyInterval:0.1];
    });
}

+ (void)setCacheDirectory:(NSString *)cacheDirectory {
    kMCMediCacheDirectory = cacheDirectory;
}

+ (NSString *)cacheDirectory {
    return kMCMediCacheDirectory;
}

+ (void)setCacheUpdateNotifyInterval:(NSTimeInterval)interval {
    kMCMediaCacheNotifyInterval = interval;
}

+ (NSTimeInterval)cacheUpdateNotifyInterval {
    return kMCMediaCacheNotifyInterval;
}

+ (void)setFileNameRules:(NSString *(^)(NSURL *))rules {
    kMCFileNameRules = rules;
}

+ (NSString *)cachedFilePathForURL:(NSURL *)url {
    NSString *pathComponent = nil;
    if (kMCFileNameRules) {
        pathComponent = kMCFileNameRules(url);
    }else{
        //先将url进行MD5加密
        pathComponent = [url.absoluteString lfb_md5];
        //再拼接后缀.mp4或者.mp3
        pathComponent = [pathComponent stringByAppendingPathExtension:url.pathExtension];
    }
    
    //临时目录再追加加密后的后缀
    return [[self cacheDirectory] stringByAppendingPathComponent:pathComponent];
}

+ (LFBCacheConfiguration *)cacheConfigurationForURL:(NSURL *)url {
    //缓存目录
    NSString *filePath = [self cachedFilePathForURL:url];
    //获取配置类
    LFBCacheConfiguration *configuration = [LFBCacheConfiguration configurationWithFilePath:filePath];
    return configuration;
}

+ (unsigned long long)calculateCachedSizeWithError:(NSError **)error {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *cacheDirectory = [self cacheDirectory];
    NSArray *files = [fileManager contentsOfDirectoryAtPath:cacheDirectory error:error];
    //记录总文件大小
    unsigned long long size = 0;
    if (files) {
        for (NSString *path in files) {
            //找到临时目录下每个文件路径
            NSString *filePath = [cacheDirectory stringByAppendingPathComponent:path];
            //获取临时目录下每个文件参数属性
            NSDictionary<NSFileAttributeKey, id> *attribute = [fileManager attributesOfItemAtPath:filePath error:error];
            if (!attribute) {
                size = -1;
                break;
            }
            //将临时缓存目录下所有文件大小相加，得到缓存文件大小
            size += [attribute fileSize];
        }
    }
    return size;
}

+ (void)cleanAllCacheWithError:(NSError *__autoreleasing *)error {
    //Find downloading file
    NSMutableSet *downloadingFiles = [NSMutableSet set];
    [[[LFBMediaDownloaderStatus shared] urls] enumerateObjectsUsingBlock:^(NSURL * _Nonnull obj, BOOL * _Nonnull stop) {
       //获取缓存文件路径
        NSString *file = [self cachedFilePathForURL:obj];
        [downloadingFiles addObject:file];
        //配置文件目录
        NSString *configurationPath = [LFBCacheConfiguration configurationFilePathForFilePath:file];
        [downloadingFiles addObject:configurationPath];
    }];
    
    //Remove files
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *cacheDirectory = [self cacheDirectory];
    
    NSArray *files = [fileManager contentsOfDirectoryAtPath:cacheDirectory error:error];
    if (files) {
        for (NSString *path in files) {
            NSString *filePath = [cacheDirectory stringByAppendingPathComponent:path];
            //判断文件管理器缓存目录下是否有正在下载的文件，有则跳过,其他存在的文件直接删除
            if ([downloadingFiles containsObject:filePath]) {
                continue;
            }
            if (![fileManager removeItemAtPath:filePath error:error]) {
                break;
            }
        }
    }
}

+ (void)cleanCacheForURL:(NSURL *)url error:(NSError *__autoreleasing *)error {
    //需要删除的url资源如果正在下载中,则直接返回报错信息
    if ([[LFBMediaDownloaderStatus shared] containsURL:url]) {
        NSString *description = [NSString stringWithFormat:NSLocalizedString(@"Clean cache for url `%@` can't be done, because it's downloading", nil), url];
        if (error) {
            *error = [NSError errorWithDomain:@"com.mediadownload" code:2 userInfo:@{NSLocalizedDescriptionKey:description}];
        }
        return;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *filePath = [self cachedFilePathForURL:url];
    //文件存在则删除
    if ([fileManager fileExistsAtPath:filePath]) {
        if (![fileManager removeItemAtPath:filePath error:error]) {
            return;
        }
    }
    
    NSString *configurationPath = [LFBCacheConfiguration configurationFilePathForFilePath:filePath];
    if ([fileManager fileExistsAtPath:configurationPath]) {
        if (![fileManager removeItemAtPath:configurationPath error:error]) {
            return;
        }
    }
}

+ (BOOL)addCacheFile:(NSString *)filePath forURL:(NSURL *)url error:(NSError *__autoreleasing *)error {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    //缓存文件路径
    NSString *cachePath = [LFBCacheManager cachedFilePathForURL:url];
    
    NSString *cacheFolder = [cachePath stringByDeletingLastPathComponent];
    if (![fileManager fileExistsAtPath:cacheFolder]) {
        if (![fileManager createDirectoryAtPath:cacheFolder withIntermediateDirectories:YES attributes:nil error:error]) {
            return NO;
        }
    }
    
    if (![fileManager copyItemAtPath:filePath toPath:cachePath error:error]) {
        return NO;
    }
    
    if (![LFBCacheConfiguration createAndSaveDownloadedConfigurationForURL:url error:error]) {
        [fileManager removeItemAtPath:cachePath error:error];
        return NO;
    }
    return YES;
}



@end
