//
//  ViewController.m
//  LFBMediaCacheDemo
//
//  Created by liufubo on 2019/10/28.
//  Copyright © 2019 liufubo. All rights reserved.
//

#import "ViewController.h"
#import "LFBTableViewCell.h"
#import "LFBMediaCache.h"
#import "Masonry.h"

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *dataSource;
@property (nonatomic, strong) NSIndexPath *indexPath;
@property (nonatomic, strong) LFBCachePlayer *playerView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.tableView];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.dataSource count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    LFBTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([LFBTableViewCell class])];
    if (!cell) {
        cell = [[LFBTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NSStringFromClass([LFBTableViewCell class])];
    }
    cell.url = [self.dataSource objectAtIndex:indexPath.row];
    __weak typeof(self) weakSelf = self;
    __weak typeof(cell) weakCell = cell;
    cell.targetClickBlock = ^(UIButton *sender) {
        [weakSelf p_tableViewCellPlayMediaWithCell:weakCell indexPath:indexPath];
    };
    if ([_indexPath isEqual:indexPath]) {
        if (![cell.contentView.subviews containsObject:self.playerView]) {
            [cell.contentView addSubview:self.playerView];
        }
        [self.playerView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.top.right.bottom.mas_equalTo(cell.contentView);
        }];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([_indexPath isEqual:indexPath]) {
        [self.playerView removeFromSuperview];
    }
}

- (void)p_tableViewCellPlayMediaWithCell:(LFBTableViewCell *)cell indexPath:(NSIndexPath *)indexPath {
    _indexPath = indexPath;
    [self.playerView removeFromSuperview];
    self.playerView = nil;
    LFBCachePlayer *playerView = [[LFBCachePlayer alloc]initWithURL:[NSURL URLWithString:cell.url] configuration:[LFBPlayerConfiguration new]];
    [self setPlayerView:playerView];
    [cell.contentView addSubview:playerView];
    [playerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.right.bottom.mas_equalTo(cell.contentView);
    }];
    [playerView startPlay];
}


#pragma mark - Getter
- (UITableView *)tableView {
    return _tableView?:({
        _tableView = [[UITableView alloc]initWithFrame:self.view.bounds style:UITableViewStylePlain];
        [_tableView registerClass:[LFBTableViewCell class] forCellReuseIdentifier:NSStringFromClass([LFBTableViewCell class])];
        [_tableView setDelegate:self];
        [_tableView setDataSource:self];
        [_tableView setRowHeight:300];
        _tableView;
    });
}

- (NSMutableArray *)dataSource {
    return _dataSource?:({
        NSString *path = [[NSBundle mainBundle] pathForResource:@"media" ofType:@"plist"];
        _dataSource = [NSMutableArray arrayWithContentsOfFile:path];
        _dataSource;
    });
}

@end
