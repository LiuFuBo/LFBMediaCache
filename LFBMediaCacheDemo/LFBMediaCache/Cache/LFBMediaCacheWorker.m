//
//  LFBMediaCacheWorker.m
//  LFBMediaCacheDemo
//
//  Created by liufubo on 2019/10/29.
//  Copyright © 2019 liufubo. All rights reserved.
//

#import "LFBMediaCacheWorker.h"
#import "LFBCacheAction.h"
#import "LFBCacheManager.h"

@import UIKit;

static NSInteger const kPackageLength = 204800; // 200kb per package;
static NSString *kMCMediaCacheResponseKey = @"kMCMediaCacheResponseKey";
static NSString *LFBMediaCacheErrorDomain = @"com.lfbmediacache";

@interface LFBMediaCacheWorker ()

@property (nonatomic, strong) NSFileHandle *readFileHandle;
@property (nonatomic, strong) NSFileHandle *writeFileHandle;
@property (nonatomic, strong, readwrite) NSError *setupError;
@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, strong) LFBCacheConfiguration *internalCacheConfiguration;

@property (nonatomic) long long currentOffset;

@property (nonatomic, strong) NSDate *startWriteDate;
@property (nonatomic) float writeBytes;
@property (nonatomic) BOOL writting;

@end

@implementation LFBMediaCacheWorker

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self save];
    [_readFileHandle closeFile];
    [_writeFileHandle closeFile];
}

- (instancetype)initWithURL:(NSURL *)url {
    self = [super init];
    if (self) {
       //缓存目录
        NSString *path = [LFBCacheManager cachedFilePathForURL:url];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        _filePath = path;
        NSError *error;
        //如果不存在缓存文件路径，则创建路径
        NSString *cacheFolder = [path stringByDeletingLastPathComponent];
        if (![fileManager fileExistsAtPath:cacheFolder]) {
            [fileManager createDirectoryAtPath:cacheFolder withIntermediateDirectories:YES attributes:nil error:&error];
        }
        
        if (!error) {
            //缓存目录存在了，但是如果缓存目录下的缓存路径不存在则创建
            if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
                [[NSFileManager defaultManager] createFileAtPath:path contents:nil attributes:nil];
            }
            NSURL *fileURL = [NSURL fileURLWithPath:path];
            _readFileHandle = [NSFileHandle fileHandleForReadingFromURL:fileURL error:&error];
            if (!error) {
                _writeFileHandle = [NSFileHandle fileHandleForWritingToURL:fileURL error:&error];
                _internalCacheConfiguration = [LFBCacheConfiguration configurationWithFilePath:path];
                _internalCacheConfiguration.url = url;
            }
        }
        _setupError = error;
    }
    return self;
}

- (LFBCacheConfiguration *)cacheConfiguration {
    return self.internalCacheConfiguration;
}

- (void)cacheData:(NSData *)data forRange:(NSRange)range error:(NSError *__autoreleasing *)error {
    @synchronized (self.writeFileHandle) {
        @try {
            [self.writeFileHandle seekToFileOffset:range.location];
            [self.writeFileHandle writeData:data];
            self.writeBytes += data.length;
            //缓存成功，记录当前缓存片段范围
            [self.internalCacheConfiguration addCacheFragment:range];
        } @catch (NSException *exception) {
            NSLog(@"write to file error");
            *error = [NSError errorWithDomain:exception.name code:123 userInfo:@{NSLocalizedDescriptionKey: exception.reason,@"exception":exception}];
        }
    }
}

- (NSData *)cachedDataForRange:(NSRange)range error:(NSError *__autoreleasing *)error {
    @synchronized (self.readFileHandle) {
        @try {
            [self.readFileHandle seekToFileOffset:range.location];
            NSData *data = [self.readFileHandle readDataOfLength:range.length];
            return data; //空数据也会返回，如果range错误，会导致播放失效
        } @catch (NSException *exception) {
            NSLog(@"read cached data error: %@",exception);
            *error = [NSError errorWithDomain:exception.name code:123 userInfo:@{NSLocalizedDescriptionKey:exception.reason,@"exception":exception}];
        }
    }
    return nil;
}

- (NSArray<LFBCacheAction *> *)cachedDataActionsForRange:(NSRange)range {
    NSArray *cachedFragments = [self.internalCacheConfiguration cacheFragments];
    NSMutableArray *actions = [NSMutableArray array];
    
    if (range.location == NSNotFound) {
        return [actions copy];
    }
    NSInteger endOffset = range.location + range.length;
    //处理range请求范围内和缓存数据交集部分
    [cachedFragments enumerateObjectsUsingBlock:^(NSValue  *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSRange fragmentRange = obj.rangeValue;
        //获取当前请求range和缓存片段之间的交集
        NSRange intersectionRange = NSIntersectionRange(range, fragmentRange);
        if (intersectionRange.length > 0) {
            //计算交集内容分为多少个200KB的包
            NSInteger package = intersectionRange.length / kPackageLength;
            for (NSInteger i=0; i<=package; i++) {
                LFBCacheAction *action = [LFBCacheAction new];
                action.actionType = LFBCacheActionTypeLocal;
                //每次包的偏移量
                NSInteger offset = i * kPackageLength;
                //每个交集包的起点位置
                NSInteger offsetLocation = intersectionRange.location + offset;
                //交集包的最大范围长度
                NSInteger maxLocation = intersectionRange.location + intersectionRange.length;
                //判断每个包的起点加200KB包长，是否超出了交集范围，如果超出了，则仅仅取交集范围内容
                NSInteger length = (offsetLocation + kPackageLength) > maxLocation ? (maxLocation - offsetLocation) : kPackageLength;
                //设置当前range请求范围
                action.range = NSMakeRange(offsetLocation, length);
                
                [actions addObject:action];
            }
        }else if (fragmentRange.location >= endOffset){
            /** 当进度条拉到60%,然后再拉回50%,此时有起点部分范围内容和60%以后部分内容50%-60%之间内容，
             跟之前缓存没有交集，所以不能从本地取数据 */
            *stop = YES;
        }
    }];
    
    if (actions.count == 0) {
        //当前range请求范围跟之前缓存片段没有交集的时候需要进行远程请求
        LFBCacheAction *action = [LFBCacheAction new];
        action.actionType = LFBCacheActionTypeRemote;
        action.range = range;
        [actions addObject:action];
    }else{
        //当前range请求范围和之前缓存片段有交集以后，处理有交集和没有交集的部分做一个组合
        NSMutableArray *localRemoteActions = [NSMutableArray array];
        [actions enumerateObjectsUsingBlock:^(LFBCacheAction  *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSRange actionRange = obj.range;
            if (idx == 0) {
                //处理seek位置在缓存部分前面的情况,未在缓存区的部分远程请求
                if (range.location < actionRange.location) {
                    LFBCacheAction *action = [LFBCacheAction new];
                    action.actionType = LFBCacheActionTypeRemote;
                    action.range = NSMakeRange(range.location, actionRange.location - range.location);
                    [localRemoteActions addObject:action];
                }
                //然后再添加上缓存区部分内容
                [localRemoteActions addObject:obj];
            }else{
                //取出上次装了数组的最后一个action的range如果跟下一个缓存本地区块没有交集，则需要将缺失的那块补上
                LFBCacheAction *lastAction = [localRemoteActions lastObject];
                NSInteger lastOffset = lastAction.range.location + lastAction.range.length;
                if (actionRange.location > lastOffset) {
                    LFBCacheAction *action = [LFBCacheAction new];
                    action.actionType = LFBCacheActionTypeRemote;
                    action.range = NSMakeRange(lastOffset, actionRange.location - lastOffset);
                    [localRemoteActions addObject:obj];
                }
                //然后再添加上缓存区部分内容
                [localRemoteActions addObject:obj];
            }
            if (idx == actions.count - 1) {
                //当所有缓存区的内容和要请求range返回内交集部分都处理完以后，range超出部分需要远端请求数据
                NSInteger localEndOffset = actionRange.location + actionRange.length;
                if (endOffset > localEndOffset) {
                    LFBCacheAction *action = [LFBCacheAction new];
                    action.actionType = LFBCacheActionTypeRemote;
                    action.range = NSMakeRange(localEndOffset, endOffset - localEndOffset);
                    [localRemoteActions addObject:action];
                }
            }
        }];
        actions = localRemoteActions;
    }
    
    return [actions copy];
}

- (void)setContentInfo:(LFBContentInfo *)contentInfo error:(NSError *__autoreleasing *)error {
    self.internalCacheConfiguration.contentInfo = contentInfo;
    @try {
        [self.writeFileHandle truncateFileAtOffset:contentInfo.contentLength];
        [self.writeFileHandle synchronizeFile];
    } @catch (NSException *exception) {
        *error = [NSError errorWithDomain:exception.name code:123 userInfo:@{NSLocalizedDescriptionKey:exception.reason,@"exception":exception}];
    }
}

- (void)save {
    @synchronized (self.writeFileHandle) {
        [self.writeFileHandle synchronizeFile];
        [self.internalCacheConfiguration save];
    }
}

- (void)startWritting {
    if (!self.writting) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
    self.writting = YES;
    self.startWriteDate = [NSDate date];
    self.writeBytes = 0;
}

- (void)finishWritting {
    if (self.writting) {
        self.writting = NO;
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        NSTimeInterval time = [[NSDate date] timeIntervalSinceDate:self.startWriteDate];
        [self.internalCacheConfiguration addDownloadedBytes:self.writeBytes spent:time];
    }
}

#pragma mark - Notification
- (void)applicationDidEnterBackground:(NSNotification *)notification {
    [self save];
}

@end
