//
//  LFBCacheAction.m
//  LFBMediaCacheDemo
//
//  Created by liufubo on 2019/10/28.
//  Copyright © 2019 liufubo. All rights reserved.
//

#import "LFBCacheAction.h"

@implementation LFBCacheAction

- (instancetype)initWithActionType:(LFBCacheActionType)actionType range:(NSRange)range {
    self = [super init];
    if (self) {
        _actionType = actionType;
        _range = range;
    }
    return self;
}

- (NSUInteger)hash {
    return [[NSString stringWithFormat:@"%@%@",NSStringFromRange(self.range),@(self.actionType)] hash];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"actionType %@, range: %@",@(self.actionType),NSStringFromRange(self.range)];
}

@end
