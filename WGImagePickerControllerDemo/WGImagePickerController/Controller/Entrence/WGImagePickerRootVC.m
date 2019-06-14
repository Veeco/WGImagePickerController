//
//  WGImagePickerRootVC.m
//  Puchi
//
//  Created by Veeco on 2019/1/16.
//  Copyright © 2019 Chance. All rights reserved.
//

#import "WGImagePickerRootVC.h"
#import "WGAlbumPickerVC.h"
#import "WGPhotoPickerVC.h"
#import "UtilHeader.h"
#import "WGPhotoTakeVC.h"
#import "WGVideoTakeVC.h"
#import "ColorHeader.h"
#import "WGAlbumModel.h"
#import "WGImageManager.h"
#import "WGImagePickerConfig.h"
#import "WGImagePickerParam.h"
#import "WGAssetModel.h"
#import "LoadingHelper.h"
#import "WGImagePickerVC.h"
#import "UIView+WGExtension.h"

@interface WGImagePickerRootVC () <WGAlbumPickerVCDelegate, UIScrollViewDelegate, WGPhotoPickerVCDelegate>

{
    /** 是否获得权限 */
    BOOL _auth;
    /** 相册VC */
    WGAlbumPickerVC *_albumPickerVC;
    /** SV */
    __weak UIScrollView *_SV;
    /** 3大VC */
    WGPhotoPickerVC *_photoPickerVC;
    WGPhotoTakeVC *_photoTakeVC;
    WGVideoTakeVC *_videoTakeVC;
    /** 底部按钮级 */
    NSArray<UIButton *> *_bottomItems;
    /** 当前选中按钮 */
    __weak UIButton *_selectedItem;
    /** 底部选中条 */
    __weak UIView *_bottomLine;
    /** 顶部标题 */
    __weak UILabel *_navTitle;
    /** 箭头 */
    __weak UIImageView *_arr;
    /** 顶部标题大容器 */
    __weak UIView *_titleView;
    /** 相册选择是否展开中 */
    BOOL _isAlbumShow;
    /** 底部栏 */
    __weak UIView *_bottom;
    /** 相册偏移 */
    CGFloat _albumOffsetY;
    /** 当前相册模型 */
    WGAlbumModel *_currentAlbum;
    /** 相册是否首次获取过资源 */
    BOOL _didGetAsset;
}

@end

// 底部按钮tag
const static int kPhotoPickerTag = 1;
const static int kPhotoTakeTag = 2;
const static int kVideoTakeTag = 3;

@implementation WGImagePickerRootVC

#pragma mark - <System>

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 初始化UI
    [self preSetupUI];
}

#pragma mark - <Normal>

/**
 预初始化UI
 */
- (void)preSetupUI {
    
    self.navBack.text = @"取消";
    self.view.backgroundColor = UIColor.whiteColor;
    
    if (_auth) {
        
        [self setup];
    }
}

- (void)didClickBack {
    
    [_photoPickerVC playerStop];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

/**
 得到权限时调用
 */
- (void)didGetAuth {
    
    _auth = YES;
    
    if (self.viewLoaded) {
        
        [self setup];
    }
}

/**
 监听标题点击
 */
- (void)didTapTitleView {

    _isAlbumShow = !_isAlbumShow;
    
    [UIView animateWithDuration:0.2f animations:^{
       
        if (self->_isAlbumShow) {
            
            self->_albumPickerVC.view.transform = CGAffineTransformMakeTranslation(0, -self->_albumOffsetY);
            self.navBack.alpha = 0;
            self.navNext.alpha = 0;
            self.navBack.userInteractionEnabled = NO;
            self.navNext.userInteractionEnabled = NO;
            self->_arr.transform = CGAffineTransformMakeRotation(M_PI);
            
            [self->_photoPickerVC playerPause];
        }
        else {
            
            self->_albumPickerVC.view.transform = CGAffineTransformIdentity;
            self.navBack.alpha = 1;
            self.navNext.alpha = 1;
            self.navBack.userInteractionEnabled = YES;
            self.navNext.userInteractionEnabled = YES;
            self->_arr.transform = CGAffineTransformIdentity;
            
            [self->_photoPickerVC playerStart];
        }
    }];
}

- (void)didClickNext {
    
    if ([_photoPickerVC checkPreviewSVISHandle]) {
        
        return;
    }
    !self.didPickHandle ?: self.didPickHandle([_photoPickerVC cropAsset]);
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

/**
 更新导航UI
 */
- (void)updateNavUI {
    
    self.navBar.hidden = YES;
    self.holdView.hidden = YES;
    self.navNext.hidden = YES;
    _arr.hidden = YES;
    _titleView.userInteractionEnabled = NO;
    
    NSInteger tag = _selectedItem.tag;
    
    if (tag == kPhotoPickerTag) {
        
        if (_currentAlbum) {
            
            _navTitle.text = _currentAlbum.name;
            CGSize size = [_navTitle.text sizeWithAttributes:@{NSFontAttributeName : _navTitle.font}];
            _navTitle.frame = (CGRect){0, 0, size};
            _arr.x = CGRectGetMaxX(_navTitle.frame) + 5;
            
            _titleView.width = CGRectGetMaxX(_arr.frame);
            _titleView.height = MAX(_navTitle.height, _arr.height);
            
            _navTitle.centerY = _titleView.height / 2;
            _arr.centerY = _navTitle.centerY;
            
            self.navBar.hidden = NO;
            self.holdView.hidden = NO;
            self.navNext.hidden = NO;
            _titleView.userInteractionEnabled = YES;
            _arr.hidden = NO;
        }
    }
    else if (tag == kPhotoTakeTag) {
        
        _navTitle.text = @"照片";
        CGSize size = [_navTitle.text sizeWithAttributes:@{NSFontAttributeName : _navTitle.font}];
        _navTitle.frame = (CGRect){0, 0, size};
        
        _titleView.width = _navTitle.width;
        _titleView.height = _navTitle.height;
        
        self.navBar.hidden = NO;
        self.holdView.hidden = NO;
    }
    else if (tag == kVideoTakeTag) {
        
        
    }
    _titleView.center = CGPointMake(self.navBar.bounds.size.width / 2, self.navBar.bounds.size.height / 2);
}

/**
 初始化UI
 */
- (void)setupUI {
    
    self.navNext.text = @"下一步";
    
    UIView *titleView = [UIView new];
    [self.navBar addSubview:titleView];
    _titleView = titleView;
    titleView.layer.masksToBounds = YES;
    [titleView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapTitleView)]];
    
    UILabel *title = [UILabel new];
    [titleView addSubview:title];
    _navTitle = title;
    title.font = getNavTitleFont();
    title.textColor = getNavTitleColor();
    
    UIImageView *arr = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"publish_arrow_drown"]];
    [titleView addSubview:arr];
    _arr = arr;
    
    // 底部
    UIView *bottom = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 45)];
    [self.view addSubview:bottom];
    _bottom = bottom;
    CGRect frame = bottom.frame;
    frame.origin.y = self.view.bounds.size.height - frame.size.height - BOTTOM_SAFE_MARGIN;
    bottom.frame = frame;
    NSMutableArray *arrM = @[].mutableCopy;
    const int btnCount = 3;
    const CGFloat btnW = bottom.bounds.size.width / btnCount;
    for (int i = 1; i <= btnCount; i++) {
        
        UIButton *btn = [UIButton new];
        [bottom addSubview:btn];
        [arrM addObject:btn];
        btn.frame = CGRectMake((i - 1) * btnW, 0, btnW, bottom.bounds.size.height);
        btn.titleLabel.font = FONT_SIZE(14);
        [btn setTitleColor:UIColorMakeFromRGB(0x999999) forState:UIControlStateNormal];
        [btn setTitleColor:UIColorMakeFromRGB(0x222222) forState:UIControlStateSelected];
        btn.tag = i;
        [btn addTarget:self action:@selector(didClickBottomItem:) forControlEvents:UIControlEventTouchUpInside];
        
        if (i == kPhotoPickerTag) {
            
            [btn setTitle:@"相册" forState:UIControlStateNormal];
            UIView *line = [UIView new];
            [bottom addSubview:line];
            _bottomLine = line;
            line.backgroundColor = UIColorMakeFromRGB(0xf8c301);
            line.frame = CGRectMake(0, 0, 16, 3);
            line.center = CGPointMake(btn.center.x, btn.bounds.size.height / 4 * 3 + 2.5f);
            line.layer.cornerRadius = line.height / 2;
            line.layer.masksToBounds = YES;
        }
        else if (i == kPhotoTakeTag) {
            
            [btn setTitle:@"照片" forState:UIControlStateNormal];
        }
        else if (i == kVideoTakeTag) {
            
            [btn setTitle:@"视频" forState:UIControlStateNormal];
        }
    }
    _bottomItems = arrM.copy;
    
    // SV
    WGImagePickerRootVCSVNoMultiHeight = bottom.frame.origin.y;
    WGImagePickerRootVCSVMultiHeight = WGImagePickerRootVCSVNoMultiHeight + bottom.bounds.size.height;
    UIScrollView *SV = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, WGImagePickerRootVCSVNoMultiHeight)];
    [self.view addSubview:SV];
    _SV = SV;
    SV.contentSize = CGSizeMake(SV.bounds.size.width * 3, 0);
    SV.pagingEnabled = YES;
    SV.showsHorizontalScrollIndicator = NO;
    SV.delegate = self;
    if (IOS_SINCE(11)) {
        
        SV.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    else {
        
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    
    // 3大VC
    frame = SV.bounds;
    
    _photoPickerVC = [WGPhotoPickerVC new];
    [SV addSubview:_photoPickerVC.view];
    _photoPickerVC.delegate = self;
    
    _photoTakeVC = [WGPhotoTakeVC new];
    [SV addSubview:_photoTakeVC.view];
    frame.origin.x = SV.bounds.size.width;
    _photoTakeVC.view.frame = frame;
    
    _videoTakeVC = [WGVideoTakeVC new];
    [SV addSubview:_videoTakeVC.view];
    frame.origin.x = SV.bounds.size.width * 2;
    _videoTakeVC.view.frame = frame;
    
    // 预加载相册选择
    _albumPickerVC = [WGAlbumPickerVC new];
    [self.view addSubview:_albumPickerVC.view];
    CGFloat y = CGRectGetMaxY(self.navBar.frame);
    _albumPickerVC.view.frame = CGRectMake(0, y, self.view.bounds.size.width, self.view.bounds.size.height - y);
    frame = _albumPickerVC.view.frame;
    frame.origin.y = self.view.bounds.size.height;
    _albumOffsetY = frame.origin.y - y;
    _albumPickerVC.view.frame = frame;
    _albumPickerVC.delegate = self;
}

/**
 初始化
 */
- (void)setup {
    
    // 1. 初始化UI
    [self setupUI];
    
    // 2. 初始化数据
    [self setupData];
}

/**
 初始化数据
 */
- (void)setupData {
    
    UIButton *item = nil;
    
    if (self.cameraMode) {
        
        item = _bottomItems.lastObject;
    }
    else {
        
        item = _bottomItems.firstObject;
    }
    [self didClickBottomItem:item];
}

/**
 监听底部按钮点击

 @param item 底部按钮
 */
- (void)didClickBottomItem:(UIButton *)item {
 
    if (_selectedItem == item) {
        
        return;
    }
    NSInteger oldTag = _selectedItem.tag;
    _selectedItem.selected = NO;
    _selectedItem.titleLabel.font = FONT_SIZE(14);
    _selectedItem = item;
    _selectedItem.selected = YES;
    _selectedItem.titleLabel.font = BOLD_SIZE(14);
    CGPoint center = _bottomLine.center;
    center.x = _selectedItem.center.x;
    NSInteger tag = _selectedItem.tag;
    
    [UIView animateWithDuration:0.2f animations:^{
        
        self->_bottomLine.center = center;
        [self->_SV setContentOffset:CGPointMake(self->_SV.bounds.size.width * (tag - 1), 0) animated:NO];
        [self updateNavUI];
        
    } completion:^(BOOL finished) {
        
        if (tag == kPhotoPickerTag) {
            
            // 获取相机相册封面
            if (!self->_didGetAsset) {
                
                WGImagePickerConfig *config = [WGImagePickerConfig sharedInstance];
                dispatch_sync(dispatch_get_global_queue(0, 0), ^{
                    
                    WEAK(self)
                    [[WGImageManager manager] getAlbumWithType:AlbumTypeCam allowPickingVideo:config.allowPickingVideo allowPickingImage:config.allowPickingImage needFetchAssets:NO completion:^(NSArray<WGAlbumModel *> * _Nonnull models) {
                        STRONG(self)
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            
                            if (models.count == 1) {
                                
                                self->_didGetAsset = YES;
                                self->_isAlbumShow = YES;
                                [self albumPickerVC:self->_albumPickerVC didSelectAlbumWithAlbumModel:models.firstObject];
                            }
                        });
                    }];
                });
            }
            
            if (oldTag == kPhotoTakeTag) {
                
                [self->_photoTakeVC pcViewDidDisappear];
            }
            else if (oldTag == kVideoTakeTag) {
                
                [self->_videoTakeVC pcViewDidDisappear];
            }
            [self->_photoPickerVC pcViewDidAppear];
        }
        else if (tag == kPhotoTakeTag) {
            
            if (oldTag == kPhotoPickerTag) {
                
                [self->_photoPickerVC pcViewDidDisappear];
            }
            else if (oldTag == kVideoTakeTag) {
                
                [self->_videoTakeVC pcViewDidDisappear];
            }
            [self->_photoTakeVC pcViewDidAppear];
        }
        else if (tag == kVideoTakeTag) {
            
            if (oldTag == kPhotoPickerTag) {
                
                [self->_photoPickerVC pcViewDidDisappear];
            }
            else if (oldTag == kPhotoTakeTag) {
                
                [self->_photoTakeVC pcViewDidDisappear];
            }
            [self->_videoTakeVC pcViewDidAppear];
        }
    }];
}

#pragma mark - <WGAlbumPickerVCDelegate>

/**
 选中相册后回调
 
 @param albumPickerVC 自身
 @param albumModel 相册模型
 */
- (void)albumPickerVC:(nonnull __kindof WGAlbumPickerVC *)albumPickerVC didSelectAlbumWithAlbumModel:(nonnull WGAlbumModel *)albumModel {
    
    _currentAlbum = albumModel;
    [self updateNavUI];
    
    [self didTapTitleView];
    [_photoPickerVC didSelectAlbum:albumModel];
}

#pragma mark - <UIScrollViewDelegate>

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    
    int index = (scrollView.contentOffset.x / scrollView.bounds.size.width);
    [self didClickBottomItem:_bottomItems[index]];
}

#pragma mark - <WGPhotoPickerVCDelegate>

/**
 点击多选按钮回调
 
 @param photoPickerVC 自身
 @param multi 是否多选
 */
- (void)photoPickerVC:(nonnull __kindof WGPhotoPickerVC *)photoPickerVC didSelectMulti:(BOOL)multi {
    
    CGRect frame = _SV.frame;
    frame.size.height = multi ? WGImagePickerRootVCSVMultiHeight : WGImagePickerRootVCSVNoMultiHeight;
    _SV.frame = frame;
    _bottom.hidden = multi;
    _SV.scrollEnabled = !multi;
}

@end
