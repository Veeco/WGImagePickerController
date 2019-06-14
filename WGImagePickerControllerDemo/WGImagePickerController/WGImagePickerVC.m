//
//  WGImagePickerVC.m
//  Puchi
//
//  Created by Veeco on 2019/1/15.
//  Copyright © 2019 Chance. All rights reserved.
//

#import "WGImagePickerVC.h"
#import "WGImagePickerConfig.h"
#import "WGImagePickerRootVC.h"
#import "WGImageManager.h"
#import "NSTimer+WGExtension.h"
#import "WGImageManager.h"

@interface WGImagePickerVC () <UIGestureRecognizerDelegate>

{
    /** 根VC */
    __weak WGImagePickerRootVC *_rootVC;
    /** 权限定时器 */
    NSTimer *_timer;
    /** 权限提示 */
    __weak UILabel *_tipLabel;
    __weak UIButton *_settingBtn;
}

@end

@implementation WGImagePickerVC

#pragma mark - <System>

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationBarHidden = YES;
    UIApplication.sharedApplication.statusBarHidden = YES;
    self.interactivePopGestureRecognizer.delegate = self;
}

- (void)dealloc {
    
    UIApplication.sharedApplication.statusBarHidden = NO;
}

#pragma mark - <Get & Set>

- (void)setAllowPickingImage:(BOOL)allowPickingImage {
    _allowPickingImage = allowPickingImage;
    
    [WGImagePickerConfig sharedInstance].allowPickingImage = allowPickingImage;
}

- (void)setAllowPickingVideo:(BOOL)allowPickingVideo {
    _allowPickingVideo = allowPickingVideo;
    
    [WGImagePickerConfig sharedInstance].allowPickingVideo = allowPickingVideo;
}

- (void)setAllowMultiType:(BOOL)allowMultiType {
    _allowMultiType = allowMultiType;
    
    [WGImagePickerConfig sharedInstance].allowMultiType = allowMultiType;
}

- (void)setColCount:(NSUInteger)colCount {
    _colCount = colCount;
    
    [WGImagePickerConfig sharedInstance].colCount = colCount;
}

- (void)setItemMargin:(CGFloat)itemMargin {
    _itemMargin = itemMargin;
    
    [WGImagePickerConfig sharedInstance].itemMargin = itemMargin;
}

- (void)setDidPickHandle:(void (^)(NSArray<WGAssetModel *> * _Nullable))didPickHandle {
    _didPickHandle = didPickHandle;
    
    WGImagePickerRootVC *VC = self.viewControllers.firstObject;
    if ([VC isKindOfClass:[WGImagePickerRootVC class]]) {
        
        VC.didPickHandle = didPickHandle;
        VC.cameraMode = self.cameraMode;
    }
}

#pragma mark - <Normal>

/**
 实例化
 
 @param maxImagesCount 最大值
 @return 实例
 */
+ (instancetype)imagePickerWithMaxImagesCount:(NSInteger)maxImagesCount {

    [WGImageManager manager].sortAscendingByModificationDate = NO;
    WGImagePickerConfig *config = [WGImagePickerConfig sharedInstance];
    config.maxImagesCount = maxImagesCount > 0 ? maxImagesCount : 9;
    config.allowPickingImage = YES;
    config.allowPickingVideo = YES;
    config.allowMultiType = NO;
    config.colCount = 3;
    config.itemMargin = 2;
    WGImagePickerRootVC *photoPickerVC = [WGImagePickerRootVC new];
    WGImagePickerVC *selfVC = [[super alloc] initWithRootViewController:photoPickerVC];
    
    if (selfVC) {

        selfVC->_rootVC = photoPickerVC;
        
        if ([[WGImageManager manager] authorizationStatusAuthorized]) {
            
            [photoPickerVC didGetAuth];
        }
        else {
            
            UILabel *tipLabel = [UILabel new];
            [selfVC.view addSubview:tipLabel];
            selfVC->_tipLabel = tipLabel;
            tipLabel.frame = CGRectMake(8, 120, selfVC.view.bounds.size.width - 16, 60);
            tipLabel.textAlignment = NSTextAlignmentCenter;
            tipLabel.numberOfLines = 0;
            tipLabel.font = [UIFont systemFontOfSize:16];
            tipLabel.textColor = [UIColor blackColor];
            tipLabel.text = @"请打开相册权限开关";
            
            UIButton *settingBtn = [UIButton buttonWithType:UIButtonTypeSystem];
            [selfVC.view addSubview:settingBtn];
            selfVC->_settingBtn = settingBtn;
            [settingBtn setTitle:@"设置" forState:UIControlStateNormal];
            settingBtn.frame = CGRectMake(0, 180, selfVC.view.bounds.size.width, 44);
            settingBtn.titleLabel.font = [UIFont systemFontOfSize:18];
            [settingBtn addTarget:selfVC action:@selector(settingBtnClick) forControlEvents:UIControlEventTouchUpInside];
            
            [selfVC checkAuth];
        }
    }
    return selfVC;
}

/**
 监听设置按钮点击
 */
- (void)settingBtnClick {
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
#pragma clang diagnostic pop
}

/**
 权限检测
 */
- (void)checkAuth {
    
    [self->_timer invalidate];
    self->_timer = nil;
    
    if ([WGImageManager authorizationStatus] == PHAuthorizationStatusNotDetermined) {
    
        _timer = [NSTimer scheduledTimerWithTimeInterval:0.2f target:self selector:@selector(checkAuth) userInfo:nil repeats:NO];
    }
    else if ([[WGImageManager manager] authorizationStatusAuthorized]) {
        
        [_tipLabel removeFromSuperview];
        [_settingBtn removeFromSuperview];
        [_rootVC didGetAuth];
    }
}

#pragma mark - <UIGestureRecognizerDelegate>

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    
    return YES;
}

@end
