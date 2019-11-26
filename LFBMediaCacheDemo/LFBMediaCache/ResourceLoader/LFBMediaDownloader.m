//
//  LFBMediaDownloader.m
//  LFBMediaCacheDemo
//
//  Created by liufubo on 2019/10/29.
//  Copyright © 2019 liufubo. All rights reserved.
//

#import "LFBMediaDownloader.h"
#import "LFBContentInfo.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "LFBCacheSessionManager.h"

#import "LFBMediaCacheWorker.h"
#import "LFBCacheManager.h"
#import "LFBCacheAction.h"

#pragma mark - Class: LFBURLSessionDelegateObject

@protocol LFBURLSessionDelegateObjectDelegate <NSObject>

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void(^)(NSURLSessionAuthChallengeDisposition,NSURLCredential *_Nullable))completionHandler;
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(nonnull void (^)(NSURLSessionResponseDisposition disposition))completionHandler;
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(nonnull NSData *)data;
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error;

@end

static NSInteger kBufferSize = 10*1024;

@interface LFBURLSessionDelegateObject : NSObject <NSURLSessionDelegate>

- (instancetype)initWithDelegate:(id<LFBURLSessionDelegateObjectDelegate>)delegate;

@property (nonatomic, weak) id<LFBURLSessionDelegateObjectDelegate> delegate;
@property (nonatomic, strong) NSMutableData *bufferData;

@end

@implementation LFBURLSessionDelegateObject

- (instancetype)initWithDelegate:(id<LFBURLSessionDelegateObjectDelegate>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
        _bufferData = [NSMutableData data];
    }
    return self;
}

#pragma mark - NSURLSessionDataDelegate
/* 响应来自远程服务器的会话级别认证请求，从代理请求凭据。 这种方法在两种情况下被调用： 1、远程服务器请求客户端证书或Windows NT LAN Manager（NTLM）身份验证时，允许您的应用程序提供适当的凭据 2、当会话首先建立与使用SSL或TLS的远程服务器的连接时，允许您的应用程序验证服务器的证书链 如果您未实现此方法，则会话会调用其委托的URLSession：task：didReceiveChallenge：completionHandler：方。 注：此方法仅处理NSURLAuthenticationMethodNTLM，NSURLAuthenticationMethodNegotiate，NSURLAuthenticationMethodClientCertificate和NSURLAuthenticationMethodServerTrust身份验证类型。对于所有其他认证方案，会话仅调用URLSession：task：didReceiveChallenge：completionHandler：方法。 */
- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler{
    [self.delegate URLSession:session didReceiveChallenge:challenge completionHandler:completionHandler];
}

/* 告诉代理数据任务从服务器收到初始回复（headers）。
 NSURLSessionResponseDisposition枚举：
 NSURLSessionResponseCancel = 0,      取消加载, 与[task cancel]一致
 NSURLSessionResponseAllow = 1,      继续加载
 NSURLSessionResponseBecomeDownload = 2,      转为下载
 NSURLSessionResponseBecomeStream API_AVAILABLE(macos(10.11), ios(9.0), watchos(2.0), tvos(9.0)) = 3,  转为流任务 */

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    [self.delegate URLSession:session dataTask:dataTask didReceiveResponse:response completionHandler:completionHandler];
}

/* 接收到数据的回调 */
- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    @synchronized (self.bufferData) {
        [self.bufferData appendData:data];
        if (self.bufferData.length > kBufferSize) {
            NSRange chunkRange = NSMakeRange(0, self.bufferData.length);
            NSData *chunkData = [self.bufferData subdataWithRange:chunkRange];
            [self.bufferData replaceBytesInRange:chunkRange withBytes:NULL length:0];
            [self.delegate URLSession:session dataTask:dataTask didReceiveData:chunkData];
        }
    }
}

/* 请求失败或者结束的回调 */
- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionDataTask *)task
didCompleteWithError:(nullable NSError *)error {
    @synchronized (self.bufferData) {
        if (self.bufferData.length > 0 && !error) {
            NSRange chunkRange = NSMakeRange(0, self.bufferData.length);
            NSData *chunkData = [self.bufferData subdataWithRange:chunkRange];
            [self.bufferData replaceBytesInRange:chunkRange withBytes:NULL length:0];
            [self.delegate URLSession:session dataTask:task didReceiveData:chunkData];
        }
    }
    [self.delegate URLSession:session task:task didCompleteWithError:error];
}

@end

#pragma mark - Class: LFBActionWorker

@class LFBActionWorker;

@protocol LFBActionWorkerDelegate <NSObject>

- (void)actionWorker:(LFBActionWorker *)actionWorker didReceiveResponse:(NSURLResponse *)response;
- (void)actionWorker:(LFBActionWorker *)actionWorker didReceiveData:(NSData *)data isLocal:(BOOL)isLocal;
- (void)actionWorker:(LFBActionWorker *)actionWorker didFinishWithError:(NSError *)error;

@end

@interface LFBActionWorker : NSObject <LFBURLSessionDelegateObjectDelegate>

@property (nonatomic, strong) NSMutableArray<LFBCacheAction *> *actions;
- (instancetype)initWithActions:(NSArray<LFBCacheAction *> *)actions url:(NSURL *)url cacheWorker:(LFBMediaCacheWorker *)cacheWorker;

@property (nonatomic, assign) BOOL canSaveToCache;
@property (nonatomic, weak) id<LFBActionWorkerDelegate> delegate;

- (void)start;
- (void)cancel;

@property (nonatomic, getter=isCancelled) BOOL cancelled;

@property (nonatomic, strong) LFBMediaCacheWorker *cacheWorker;
@property (nonatomic, strong) NSURL *url;

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) LFBURLSessionDelegateObject *sessionDelegateObject;
@property (nonatomic, strong) NSURLSessionDataTask *task;
@property (nonatomic) NSInteger startOffset;

@end

@interface LFBActionWorker ()

@property (nonatomic) NSTimeInterval notifyTime;

@end

@implementation LFBActionWorker

- (void)dealloc {
    [self cancel];
}

- (instancetype)initWithActions:(NSArray<LFBCacheAction *> *)actions url:(NSURL *)url cacheWorker:(LFBMediaCacheWorker *)cacheWorker {
    self = [super init];
    if (self) {
        _canSaveToCache = YES;
        _actions = [actions mutableCopy];
        _cacheWorker = cacheWorker;
        _url = url;
    }
    return self;
}

- (void)start {
    [self processActions];
}

- (void)cancel {
    if (_session) {
        [self.session invalidateAndCancel];
    }
    self.cancelled = YES;
}

- (LFBURLSessionDelegateObject *)sessionDelegateObject {
    if (!_sessionDelegateObject) {
        _sessionDelegateObject = [[LFBURLSessionDelegateObject alloc]initWithDelegate:self];
    }
    return _sessionDelegateObject;
}

- (NSURLSession *)session {
    if (!_session) {
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:self.sessionDelegateObject delegateQueue:[LFBCacheSessionManager shared].downloadQueue];
        _session = session;
    }
    return _session;
}

- (void)processActions {
    if (self.isCancelled) {
        return;
    }
    
    LFBCacheAction *action = [self.actions firstObject];
    if (!action) {
    //如果action不存在了，表示当前range的data已经请求完了，回调finish方法，session再继续请求下一个range内容
        if ([self.delegate respondsToSelector:@selector(actionWorker:didFinishWithError:)]) {
            [self.delegate actionWorker:self didFinishWithError:nil];
        }
        return;
    }
    [self.actions removeObjectAtIndex:0];
    
    if (action.actionType == LFBCacheActionTypeLocal) {
        NSError *error;
        NSData *data = [self.cacheWorker cachedDataForRange:action.range error:&error];
        if (error) {
            //发生错误，走错误代理回调
            if ([self.delegate respondsToSelector:@selector(actionWorker:didFinishWithError:)]) {
                [self.delegate actionWorker:self didFinishWithError:error];
            }
        }else{
            //如果存在本地缓存，则取出缓存填充给reponseData
            if ([self.delegate respondsToSelector:@selector(actionWorker:didReceiveData:isLocal:)]) {
                [self.delegate actionWorker:self didReceiveData:data isLocal:YES];
            }
            [self processActions];
        }
    }else{
        //range 属于remote内容，则直接请求
        long long fromOffset = action.range.location;
        long long endOffset = action.range.location + action.range.length - 1;
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.url];
        request.cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
        NSString *range = [NSString stringWithFormat:@"bytes=%lld-%lld", fromOffset, endOffset];
        [request setValue:range forHTTPHeaderField:@"Range"];
        self.startOffset = action.range.location;
        self.task = [self.session dataTaskWithRequest:request];
        [self.task resume];
    }
}

- (void)notifyDownloadProgressWithFlush:(BOOL)flush finished:(BOOL)finished {
    double currentTime = CFAbsoluteTimeGetCurrent();
    double interval = [LFBCacheManager cacheUpdateNotifyInterval];
    if ((self.notifyTime < currentTime - interval) || flush) {
        self.notifyTime = currentTime;
        LFBCacheConfiguration *configuration = [self.cacheWorker.cacheConfiguration copy];
        [[NSNotificationCenter defaultCenter] postNotificationName:LFBCacheManagerDidUpdateCacheNotification object:self userInfo:@{LFBCacheConfigurationKey:configuration}];
        if (finished && configuration.progress >= 1.0) {
            [self notifyDownloadFinishedWithError:nil];
        }
    }
}

- (void)notifyDownloadFinishedWithError:(NSError *)error {
    LFBCacheConfiguration *configuration = [self.cacheWorker.cacheConfiguration copy];
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    [userInfo setValue:configuration forKey:LFBCacheConfigurationKey];
    [userInfo setValue:error forKey:LFBCacheFinishedErrorKey];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:LFBCacheManagerDidFinishCacheNotification object:self userInfo:userInfo];
}

#pragma mark - LFBURLSessionDelegateObjectDelegate (请求数据回调代理方法)

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
    NSURLCredential *card = [[NSURLCredential alloc]initWithTrust:challenge.protectionSpace.serverTrust];
    completionHandler(NSURLSessionAuthChallengeUseCredential,card);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    NSString *mimeType = response.MIMEType;
    //Only download video/audio data
    if ([mimeType rangeOfString:@"video/"].location == NSNotFound && [mimeType rangeOfString:@"audio/"].location == NSNotFound && [mimeType rangeOfString:@"application"].location == NSNotFound) {
        completionHandler(NSURLSessionResponseCancel);
    }else{
        if ([self.delegate respondsToSelector:@selector(actionWorker:didReceiveResponse:)]) {
            [self.delegate actionWorker:self didReceiveResponse:response];
        }
        if (self.canSaveToCache) {
            [self.cacheWorker startWritting];
        }
        completionHandler(NSURLSessionResponseAllow);
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    if (self.isCancelled) {
        return;
    }
    
    if (self.canSaveToCache) {
        NSRange range = NSMakeRange(self.startOffset, data.length);
        NSError *error;
        //缓存数据
        [self.cacheWorker cacheData:data forRange:range error:&error];
        if (error) {
            if ([self.delegate respondsToSelector:@selector(actionWorker:didFinishWithError:)]) {
                [self.delegate actionWorker:self didFinishWithError:error];
            }
            return;
        }
        //缓存数据持久化
        [self.cacheWorker save];
    }
    //调用代理方法，给responseData塞入数据
    self.startOffset += data.length;
    if ([self.delegate respondsToSelector:@selector(actionWorker:didReceiveData:isLocal:)]) {
        [self.delegate actionWorker:self didReceiveData:data isLocal:NO];
    }
    //发出进度更新通知
    [self notifyDownloadProgressWithFlush:NO finished:NO];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    
    if (self.canSaveToCache) {
        [self.cacheWorker finishWritting];
        [self.cacheWorker save];
    }
    
    if (error) {
        if ([self.delegate respondsToSelector:@selector(actionWorker:didFinishWithError:)]) {
            [self.delegate actionWorker:self didFinishWithError:error];
        }
        [self notifyDownloadFinishedWithError:error];
    }else{
        //下载完成，发送通知，并继续下一个片段数据下载
        [self notifyDownloadProgressWithFlush:YES finished:YES];
        [self processActions];
    }
}

@end

#pragma mark - Class: LFBMediaDownloaderStatus


@interface LFBMediaDownloaderStatus ()

@property (nonatomic, strong) NSMutableSet *downloadingURLS;

@end

@implementation LFBMediaDownloaderStatus

+ (instancetype)shared {
    static LFBMediaDownloaderStatus *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc]init];
        instance.downloadingURLS = [NSMutableSet set];
    });
    return instance;
}

- (void)addURL:(NSURL *)url {
    @synchronized (self.downloadingURLS) {
        [self.downloadingURLS addObject:url];
    }
}

- (void)removelURL:(NSURL *)url {
    @synchronized (self.downloadingURLS) {
        [self.downloadingURLS removeObject:url];
    }
}

- (BOOL)containsURL:(NSURL *)url {
    @synchronized (self.downloadingURLS) {
        return [self.downloadingURLS containsObject:url];
    }
}

- (NSSet *)urls {
    return [self.downloadingURLS copy];
}


@end


#pragma mark - Class: LFBMediaDownloader

@interface LFBMediaDownloader () <LFBActionWorkerDelegate>


@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) NSURLSessionDataTask *task;

@property (nonatomic, strong) LFBMediaCacheWorker *cacheWorker;
@property (nonatomic, strong) LFBActionWorker *actionWorker;

@property (nonatomic) BOOL downloadToEnd;
@end

@implementation LFBMediaDownloader

- (void)dealloc {
    [[LFBMediaDownloaderStatus shared] removelURL:self.url];
}

- (instancetype)initWithURL:(NSURL *)url cacheWorker:(LFBMediaCacheWorker *)cacheWorker {
    self = [super init];
    if (self) {
        _saveToCache = YES;
        _url = url;
        _cacheWorker = cacheWorker;
        _info = _cacheWorker.cacheConfiguration.contentInfo;
        [[LFBMediaDownloaderStatus shared] addURL:self.url];
    }
    return self;
}

- (void)downloadTaskFromOffset:(unsigned long long)fromOffset length:(NSUInteger)length toEnd:(BOOL)toEnd {
    
    NSRange range = NSMakeRange((NSUInteger)fromOffset, length);
    
    if (toEnd) {
        range.length = (NSUInteger)self.cacheWorker.cacheConfiguration.contentInfo.contentLength - range.location;
    }
    
    //根据请求返回去获取缓存中存在的内容,以及创建需要请求区段action
    NSArray *actions = [self.cacheWorker cachedDataActionsForRange:range];
    self.actionWorker = [[LFBActionWorker alloc]initWithActions:actions url:self.url cacheWorker:self.cacheWorker];
    self.actionWorker.canSaveToCache = self.saveToCache;
    self.actionWorker.delegate = self;
    [self.actionWorker start];
}

- (void)downloadFromStartToEnd {
    self.downloadToEnd = YES;
    NSRange range = NSMakeRange(0, 2);
    NSArray *actions = [self.cacheWorker cachedDataActionsForRange:range];
    
    self.actionWorker = [[LFBActionWorker alloc]initWithActions:actions url:self.url cacheWorker:self.cacheWorker];
    self.actionWorker.canSaveToCache = self.saveToCache;
    self.actionWorker.delegate = self;
    [self.actionWorker start];
}

- (void)cancel {
    self.actionWorker.delegate = self;
    [[LFBMediaDownloaderStatus shared] removelURL:self.url];
    [self.actionWorker cancel];
    self.actionWorker = nil;
}

#pragma mark - LFBActionWorkerDelegate

- (void)actionWorker:(LFBActionWorker *)actionWorker didReceiveResponse:(NSURLResponse *)response {
    if (!self.info) {
        LFBContentInfo *info = [LFBContentInfo new];
        
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            NSHTTPURLResponse *HTTPURLResponse = (NSHTTPURLResponse *)response;
            NSString *acceptRange = HTTPURLResponse.allHeaderFields[@"Accept-Ranges"];
            info.byteRangeAccessSupported = [acceptRange isEqualToString:@"bytes"];
            info.contentLength = [[[HTTPURLResponse.allHeaderFields[@"Content-Range"] componentsSeparatedByString:@"/"] lastObject] longLongValue];
        }
        NSString *mimeType = response.MIMEType;
        CFStringRef contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef)(mimeType), NULL);
        info.contentType = CFBridgingRelease(contentType);
        self.info = info;
        
        NSError *error;
        [self.cacheWorker setContentInfo:info error:&error];
        if (error) {
            if ([self.delegate respondsToSelector:@selector(mediaDownloader:didFinishedWithError:)]) {
                [self.delegate mediaDownloader:self didFinishedWithError:error];
            }
            return;
        }
    }
    
    if ([self.delegate respondsToSelector:@selector(mediaDownloader:didReceiveResponse:)]) {
        [self.delegate mediaDownloader:self didReceiveResponse:response];
    }
}

- (void)actionWorker:(LFBActionWorker *)actionWorker didReceiveData:(NSData *)data isLocal:(BOOL)isLocal {
    if ([self.delegate respondsToSelector:@selector(mediaDownloader:didReceiveData:)]) {
        [self.delegate mediaDownloader:self didReceiveData:data];
    }
}

- (void)actionWorker:(LFBActionWorker *)actionWorker didFinishWithError:(NSError *)error {
    //下载任务发生错误的时候回调，此时需要删除正在下载的url记录
    [[LFBMediaDownloaderStatus shared] removelURL:self.url];
    
    if (!error && self.downloadToEnd) {
        self.downloadToEnd = NO;
        [self downloadTaskFromOffset:2 length:(NSUInteger)(self.cacheWorker.cacheConfiguration.contentInfo.contentLength - 2) toEnd:YES];
    }else{
        if ([self.delegate respondsToSelector:@selector(mediaDownloader:didFinishedWithError:)]) {
            [self.delegate mediaDownloader:self didFinishedWithError:error];
        }
    }
}

@end
