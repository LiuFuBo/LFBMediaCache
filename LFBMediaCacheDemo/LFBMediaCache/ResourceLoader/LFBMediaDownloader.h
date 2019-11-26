//
//  LFBMediaDownloader.h
//  LFBMediaCacheDemo
//
//  Created by liufubo on 2019/10/29.
//  Copyright © 2019 liufubo. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol LFBMediaDownloaderDelegate;
@class LFBContentInfo;
@class LFBMediaCacheWorker;


@interface LFBMediaDownloaderStatus : NSObject

+ (instancetype)shared;

- (void)addURL:(NSURL *)url;
- (void)removelURL:(NSURL *)url;

/**
 * 如果正在下载中则返回YES
 */
- (BOOL)containsURL:(NSURL *)url;
- (NSSet *)urls;

@end

@interface LFBMediaDownloader : NSObject

- (instancetype)initWithURL:(NSURL *)url cacheWorker:(LFBMediaCacheWorker *)cacheWorker;
@property (nonatomic, strong, readonly) NSURL *url;
@property (nonatomic, weak) id<LFBMediaDownloaderDelegate> delegate;
@property (nonatomic, strong) LFBContentInfo *info;
@property (nonatomic, assign) BOOL saveToCache;

- (void)downloadTaskFromOffset:(unsigned long long)fromOffset length:(NSUInteger)length toEnd:(BOOL)toEnd;
- (void)downloadFromStartToEnd;

- (void)cancel;

@end


@protocol LFBMediaDownloaderDelegate <NSObject>

@optional
- (void)mediaDownloader:(LFBMediaDownloader *)downloader didReceiveResponse:(NSURLResponse *)response;
- (void)mediaDownloader:(LFBMediaDownloader *)downloader didReceiveData:(NSData *)data;
- (void)mediaDownloader:(LFBMediaDownloader *)downloader didFinishedWithError:(NSError *)error;

@end
