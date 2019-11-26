//
//  TabBarVc.m
//  LFBMediaCacheDemo
//
//  Created by liufubo on 2019/11/25.
//  Copyright © 2019 liufubo. All rights reserved.
//

#import "TabBarVc.h"
#import "ViewController.h"
#import "TestViewController.h"

@interface TabBarVc ()<UITabBarDelegate,UITabBarControllerDelegate>

@end

@implementation TabBarVc

+ (void)initialize
{
    UITabBarItem *tabBarItem = [UITabBarItem appearance];
    
    NSMutableDictionary *normolAttribute = [NSMutableDictionary dictionary];
    [normolAttribute setValue:[UIColor colorWithRed:170/255.0f green:170/255.0f blue:170/255.0f alpha:1] forKey:NSForegroundColorAttributeName];
    [normolAttribute setValue:[UIFont systemFontOfSize:11] forKey:NSFontAttributeName];
    
    NSMutableDictionary *selectedAttribute = [NSMutableDictionary dictionary];
    [selectedAttribute setValue:[UIColor colorWithRed:34/255.0f green:34/255.0f blue:34/255.0f alpha:1] forKey:NSForegroundColorAttributeName];
    [selectedAttribute setValue:[UIFont systemFontOfSize:11] forKey:NSFontAttributeName];
    
    [tabBarItem setTitleTextAttributes:normolAttribute forState:UIControlStateNormal];
    [tabBarItem setTitleTextAttributes:selectedAttribute forState:UIControlStateSelected];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tabBar.translucent = NO;
    self.delegate = self;
    TestViewController *testVc = [[TestViewController alloc]init];
    [self setupChildViewController:testVc title:@"View" imageName:@"view" selectedImageName:@"viewgray"];
    ViewController *tableVc = [[ViewController alloc]init];
    [self setupChildViewController:tableVc title:@"tableView" imageName:@"table" selectedImageName:@"tablegray"];
}

- (void)setupChildViewController:(UIViewController *)childVc title:(NSString *)title imageName:(NSString *)imageName selectedImageName:(NSString *)selectedImageName{
    //1.设置控制器的属性
    childVc.title = title;
    //设置图标
    childVc.tabBarItem.image = [UIImage imageNamed:imageName];
    [childVc.tabBarItem setImageInsets:UIEdgeInsetsMake(-3, 0, 3, 0)];
    
    //设置选中的图标
    UIImage *selectedImage = [UIImage imageNamed:selectedImageName];
    childVc.tabBarItem.selectedImage = [selectedImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    
    [childVc.tabBarItem setTitlePositionAdjustment:UIOffsetMake(0, -3)];
    
    //包装一个导航控制器
    UINavigationController *nav = [[UINavigationController alloc]initWithRootViewController:childVc];
    [self addChildViewController:nav];
}

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController{
    
}


@end
