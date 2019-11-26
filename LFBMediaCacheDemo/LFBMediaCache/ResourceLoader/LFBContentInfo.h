//
//  LFBContentInfo.h
//  LFBMediaCacheDemo
//
//  Created by liufubo on 2019/10/28.
//  Copyright © 2019 liufubo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LFBContentInfo : NSObject <NSCoding>

@property (nonatomic, copy) NSString *contentType; //资源类型
@property (nonatomic, assign) BOOL byteRangeAccessSupported; //是否支持片段数据访问
@property (nonatomic, assign) unsigned long long contentLength; //内容长度
@property (nonatomic) unsigned long long downloadedContentLength; //已下载内容长度

@end


