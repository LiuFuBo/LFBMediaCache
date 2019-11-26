//
//  LFBResourceLoadingRequestWorker.m
//  LFBMediaCacheDemo
//
//  Created by liufubo on 2019/10/31.
//  Copyright © 2019 liufubo. All rights reserved.
//

#import "LFBResourceLoadingRequestWorker.h"
#import "LFBMediaDownloader.h"
#import "LFBContentInfo.h"

@import MobileCoreServices;
@import AVFoundation;
@import UIKit;

@interface LFBResourceLoadingRequestWorker () <LFBMediaDownloaderDelegate>

@property (nonatomic, strong, readwrite) AVAssetResourceLoadingRequest *request;
@property (nonatomic, strong) LFBMediaDownloader *mediaDownloader;

@end

@implementation LFBResourceLoadingRequestWorker

- (instancetype)initWithMediaDownloader:(LFBMediaDownloader *)mediaDownloader resourceLoadingRequest:(AVAssetResourceLoadingRequest *)request {
    self = [super init];
    if (self) {
        _mediaDownloader = mediaDownloader;
        _mediaDownloader.delegate = self;
        _request = request;
        
        [self fullfillContentInfo];
    }
    return self;
}

/**
 * 每次数据请求完成以后都要调用该方法，告诉系统现在已经下载了多少内容了，
 *下载器则决定接下来该下载多少内容
 */
- (void)fullfillContentInfo {
    AVAssetResourceLoadingContentInformationRequest *contentInformationRequest = self.request.contentInformationRequest;
    if (self.mediaDownloader.info && !contentInformationRequest.contentType) {
        //Fullfilll cotent information
        contentInformationRequest.contentType = self.mediaDownloader.info.contentType;
        contentInformationRequest.contentLength = self.mediaDownloader.info.contentLength;
        contentInformationRequest.byteRangeAccessSupported = self.mediaDownloader.info.byteRangeAccessSupported;
    }
}

- (void)startWork {
    
    AVAssetResourceLoadingDataRequest *dataRequest = self.request.dataRequest;
    
    //获取需要下载片段长度和起始位置
    long long offset = dataRequest.requestedOffset;
    NSInteger length = dataRequest.requestedLength;
    if (dataRequest.currentOffset != 0) {
        offset = dataRequest.currentOffset;
    }
    
    BOOL toEnd = NO;
    if (@available(iOS 9.0, *)) {
        if (dataRequest.requestsAllDataToEndOfResource) {
            toEnd = YES;
        }
    }
    //根据请求区段请求数据
    [self.mediaDownloader downloadTaskFromOffset:offset length:length toEnd:toEnd];
}

- (void)cancel {
    [self.mediaDownloader cancel];
}

- (void)finish {
    if (!self.request.isFinished) {
        [self.request finishLoadingWithError:[self loaderCancelledError]];
    }
}

- (NSError *)loaderCancelledError {
    NSError *error = [[NSError alloc]initWithDomain:@"com.resourceloader" code:-3 userInfo:@{NSLocalizedDescriptionKey:@"Resourceloader cancelled"}];
    return error;
}

#pragma mark - LFBMediaDownloaderDelegate
- (void)mediaDownloader:(LFBMediaDownloader *)downloader didReceiveResponse:(NSURLResponse *)response {
    [self fullfillContentInfo]; //响应消息后填充request
}

- (void)mediaDownloader:(LFBMediaDownloader *)downloader didReceiveData:(NSData *)data {
    [self.request.dataRequest respondWithData:data];
}

/** 在response有响应会调用，不管成功还是失败了，只要响应完成就会回调 （包含response响应失败，以及完成数据请求失败） */
- (void)mediaDownloader:(LFBMediaDownloader *)downloader didFinishedWithError:(NSError *)error {
    if (error.code == NSURLErrorCancelled) {
        return;
    }
     //调用finishLoading，会去获取contentInformationRequest的信息，判断接下来要如何处理
    if (!error) {
        [self.request finishLoading];
    }else {
        [self.request finishLoadingWithError:error];
    }
    
    [self.delegate resourceLoadingRequestWorker:self didCompleteWithError:error];
}

@end
