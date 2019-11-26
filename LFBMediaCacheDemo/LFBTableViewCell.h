//
//  LFBTableViewCell.h
//  LFBMediaCacheDemo
//
//  Created by liufubo on 2019/11/21.
//  Copyright © 2019 liufubo. All rights reserved.
//

#import <UIKit/UIKit.h>



@interface LFBTableViewCell : UITableViewCell
@property (nonatomic, copy) NSString *url;
@property (nonatomic, copy) void(^targetClickBlock)(UIButton *sender);

@end


