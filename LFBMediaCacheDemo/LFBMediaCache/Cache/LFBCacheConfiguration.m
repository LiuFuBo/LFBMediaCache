//
//  LFBCacheConfiguration.m
//  LFBMediaCacheDemo
//
//  Created by liufubo on 2019/10/28.
//  Copyright © 2019 liufubo. All rights reserved.
//

#import "LFBCacheConfiguration.h"
#import "LFBCacheManager.h"
#import <MobileCoreServices/MobileCoreServices.h>

static NSString *kFileNameKey = @"kFileNameKey";
static NSString *kCacheFragmentsKey = @"kCacheFragmentsKey";
static NSString *kDownloadInfoKey = @"kDownloadInfoKey";
static NSString *kContentInfoKey = @"kContentInfoKey";
static NSString *kURLKey = @"kURLKey";

@interface LFBCacheConfiguration () <NSCoding>

@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, copy) NSString *fileName;
@property (nonatomic, copy) NSArray<NSValue *> *internalCacheFragments;
@property (nonatomic, copy) NSArray *downloadInfo;

@end

@implementation LFBCacheConfiguration

+ (instancetype)configurationWithFilePath:(NSString *)filePath {
    //缓存目录追加mf_cfg
    filePath = [self configurationFilePathForFilePath:filePath];
    LFBCacheConfiguration *configuration = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
    
    if (!configuration) {
        configuration = [[LFBCacheConfiguration alloc]init];
        configuration.fileName = [filePath lastPathComponent];
    }
    configuration.filePath = filePath;
    
    
    return configuration;
}

+ (NSString *)configurationFilePathForFilePath:(NSString *)filePath {
    return [filePath stringByAppendingPathExtension:@"mf_cfg"];
}

- (NSArray<NSValue *> *)internalCacheFragments {
    if (!_internalCacheFragments) {
        _internalCacheFragments = [NSArray array];
    }
    return _internalCacheFragments;
}

- (NSArray *)downloadInfo {
    if (!_downloadInfo) {
        _downloadInfo = [NSArray array];
    }
    return _downloadInfo;
}

- (NSArray<NSValue *> *)cacheFragments {
    return [_internalCacheFragments copy];
}

- (float)progress {
    float progress = self.downloadedBytes / (float)self.contentInfo.contentLength;
    return progress;
}

- (long long)downloadedBytes {
    float bytes = 0;
    @synchronized (self.internalCacheFragments) {
        for (NSValue *range in self.internalCacheFragments) {
            bytes += range.rangeValue.length;
        }
    }
    return bytes;
}

- (float)downloadSpeed {
    long long bytes = 0;
    NSTimeInterval time = 0;
    @synchronized (self.downloadInfo) {
        for (NSArray *f in self.downloadInfo) {
            bytes += [[f firstObject] longLongValue];
            time += [[f lastObject] doubleValue];
        }
    }
    return bytes / 1024.0 / time;
}

#pragma mark - NSCoding
- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.fileName forKey:kFileNameKey];
    [aCoder encodeObject:self.internalCacheFragments forKey:kCacheFragmentsKey];
    [aCoder encodeObject:self.downloadInfo forKey:kDownloadInfoKey];
    [aCoder encodeObject:self.contentInfo forKey:kContentInfoKey];
    [aCoder encodeObject:self.url forKey:kURLKey];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        _fileName = [aDecoder decodeObjectForKey:kFileNameKey];
        _internalCacheFragments = [[aDecoder decodeObjectForKey:kCacheFragmentsKey] mutableCopy];
        if (!_internalCacheFragments) {
            _internalCacheFragments = [NSArray array];
        }
        _downloadInfo = [aDecoder decodeObjectForKey:kDownloadInfoKey];
        _contentInfo = [aDecoder decodeObjectForKey:kContentInfoKey];
        _url = [aDecoder decodeObjectForKey:kURLKey];
    }
    return self;
}

#pragma mark - NSCopying
- (id)copyWithZone:(NSZone *)zone {
    
    LFBCacheConfiguration *configuration = [[LFBCacheConfiguration allocWithZone:zone] init];
    configuration.fileName = self.fileName;
    configuration.filePath = self.filePath;
    configuration.internalCacheFragments = self.internalCacheFragments;
    configuration.downloadInfo = self.downloadInfo;
    configuration.url = self.url;
    configuration.contentInfo = self.contentInfo;
    
    return configuration;
}

#pragma mark - Update
- (void)save {
    @synchronized (self.internalCacheFragments) {
        [NSKeyedArchiver archiveRootObject:self toFile:self.filePath];
    }
}

#pragma mark - addCacheFragment
- (void)addCacheFragment:(NSRange)fragment {
    
    if (fragment.location == NSNotFound || fragment.length == 0) {
        return;
    }
    @synchronized (self.internalCacheFragments) {
        //先深拷贝一份以前的缓存片段信息
        NSMutableArray *internalCacheFragments = [self.internalCacheFragments mutableCopy];
        //将要缓存片段range转化为value
        NSValue *fragmentValue = [NSValue valueWithRange:fragment];
        NSInteger count = self.internalCacheFragments.count;
        if (count == 0) {
            //当缓存数量为0时，直接加入
            [internalCacheFragments addObject:fragmentValue];
        }else{
            //当缓存片段数目不为0时，需要将当前缓存片段按顺序存放到指定位置
            NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
            [internalCacheFragments enumerateObjectsUsingBlock:^(NSValue *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                NSRange range = obj.rangeValue;
                if (fragment.location + fragment.length <= range.location) {
                    if (indexSet.count == 0) {
                        [indexSet addIndex:idx];
                    }
                    *stop = YES;
                }else if (fragment.location <= (range.location + range.length) && (fragment.location + fragment.length) > range.location){
                    [indexSet addIndex:idx];
                }else if (fragment.location >= range.location + range.length){
                    if (idx == count - 1) {
                        [indexSet addIndex:idx];
                    }
                }
            }];
            
            if (indexSet.count > 1) {
                NSRange firstRange = self.internalCacheFragments[indexSet.firstIndex].rangeValue;
                NSRange lastRange = self.internalCacheFragments[indexSet.lastIndex].rangeValue;
                NSInteger location = MIN(firstRange.location, fragment.location);
                NSInteger endOffset = MAX(lastRange.location + lastRange.length, fragment.location + fragment.length);
                NSRange combinRange = NSMakeRange(location, endOffset - location);
                [internalCacheFragments removeObjectsAtIndexes:indexSet];
                [internalCacheFragments insertObject:[NSValue valueWithRange:combinRange] atIndex:indexSet.firstIndex];
            }else if (indexSet.count == 1){
                NSRange firstRange = self.internalCacheFragments[indexSet.firstIndex].rangeValue;
                NSRange expandFirstRange = NSMakeRange(firstRange.location, firstRange.length + 1);
                NSRange expandFragmentRange = NSMakeRange(fragment.location, fragment.length + 1);
                NSRange intersectionRange = NSIntersectionRange(expandFirstRange, expandFragmentRange);
                if (intersectionRange.length > 0) {
                    NSInteger location = MIN(firstRange.location, fragment.location);
                    NSInteger endOffset = MAX(firstRange.location + firstRange.length, fragment.location + fragment.length);
                    NSRange combinRange = NSMakeRange(location, endOffset - location);
                    [internalCacheFragments removeObjectAtIndex:indexSet.firstIndex];
                    [internalCacheFragments insertObject:[NSValue valueWithRange:combinRange] atIndex:indexSet.firstIndex];
                }else{
                    if (firstRange.location > fragment.location) {
                        [internalCacheFragments insertObject:fragmentValue atIndex:[indexSet lastIndex]];
                    }else{
                        [internalCacheFragments insertObject:fragmentValue atIndex:[indexSet lastIndex] + 1];
                    }
                }
            }
        }
        self.internalCacheFragments = [internalCacheFragments copy];
    }
}

- (void)addDownloadedBytes:(long long)bytes spent:(NSTimeInterval)time {
    @synchronized (self.downloadInfo) {
        self.downloadInfo = [self.downloadInfo arrayByAddingObject:@[@(bytes),@(time)]];
    }
}

@end

@implementation LFBCacheConfiguration (LFBConvenient)

+ (BOOL)createAndSaveDownloadedConfigurationForURL:(NSURL *)url error:(NSError *__autoreleasing *)error {
    NSString *filePath = [LFBCacheManager cachedFilePathForURL:url];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDictionary<NSFileAttributeKey, id> *attributes = [fileManager attributesOfItemAtPath:filePath error:error];
    if (!attributes) {
        return NO;
    }
    
    NSUInteger fileSize = (NSUInteger)attributes.fileSize;
    NSRange range = NSMakeRange(0, fileSize);
    
    LFBCacheConfiguration *configuration = [LFBCacheConfiguration configurationWithFilePath:filePath];
    configuration.url = url;
    
    LFBContentInfo *contentInfo = [LFBContentInfo new];
    
    NSString *fileExtension = [url pathExtension];
    NSString *UTI = (__bridge_transfer NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)fileExtension, NULL);
    NSString *contentType = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)UTI, kUTTagClassMIMEType);
    if (!contentType) {
        contentType = @"application/octet-stream";
    }
    contentInfo.contentType = contentType;
    
    contentInfo.contentLength = fileSize;
    contentInfo.byteRangeAccessSupported = YES;
    contentInfo.downloadedContentLength = fileSize;
    configuration.contentInfo = contentInfo;
    
    [configuration addCacheFragment:range];
    [configuration save];
    
    return YES;
}

@end
