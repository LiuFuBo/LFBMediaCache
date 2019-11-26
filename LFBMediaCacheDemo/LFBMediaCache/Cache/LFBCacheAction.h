//
//  LFBCacheAction.h
//  LFBMediaCacheDemo
//
//  Created by liufubo on 2019/10/28.
//  Copyright © 2019 liufubo. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, LFBCacheActionType) {
    LFBCacheActionTypeLocal = 0,
    LFBCacheActionTypeRemote
};

@interface LFBCacheAction : NSObject

- (instancetype)initWithActionType:(LFBCacheActionType)actionType range:(NSRange)range;

@property (nonatomic) LFBCacheActionType actionType;
@property (nonatomic) NSRange range;

@end


