//
//  WGPhotoPickerVC.m
//  Puchi
//
//  Created by Veeco on 2019/1/18.
//  Copyright © 2019 Chance. All rights reserved.
//

#import "WGPhotoPickerVC.h"
#import "WGImagePickerConfig.h"
#import "WGImageManager.h"
#import "WGAlbumModel.h"
#import "WGAssetCell.h"
#import "WGAssetModel.h"
#import "UtilHeader.h"
#import "WGImagePickerParam.h"
#import "WGPreView.h"
#import "LoadingHelper.h"
#import "PopView.h"
#import "UIView+WGExtension.h"

@interface WGPhotoPickerVC () <UICollectionViewDataSource, UICollectionViewDelegate, WGPreViewDelegate>

{
    /** 预览 */
    __weak WGPreView *_preView;
    /** 相册 */
    __weak UICollectionView *_CV;
    /** 数据源 */
    NSArray<WGAssetModel *> *_datas;
    /** 当前选中元素 */
    WGAssetModel *_currentModel;
    /** CV现时高度 */
    CGFloat _CVNowHeight;
    /** 预览view是否处于收起状态 */
    BOOL _isPrePackUp;
    /** 预览view正常状态最大y */
    CGFloat _preNormalMaxY;
    /** 当前相册中是否有包含当前所选资源 */
    BOOL _isContainCurrentAsset;
}
/** 预览view是否变化中 */
@property (assign, nonatomic) BOOL isPreDidChange;
/** 所选资源 */
@property (nullable, nonatomic, strong) NSMutableArray<WGAssetModel *> *selectedModels;

@end

// cellID
static NSString *const kCellID = @"kCellID";
// 预览view缩小状态最大y
static const CGFloat kPreMinMaxY = 48;
// 动画执行时长
static const NSTimeInterval kAnimeDur = 0.2f;

@implementation WGPhotoPickerVC

#pragma mark - <Get & Set>

- (BOOL)isPreDidChange {
    
    return _preView.frame.origin.y != 0;
}

#pragma mark - <Lazy>

- (NSMutableArray<WGAssetModel *> *)selectedModels {
    if (!_selectedModels) {
        
        self.selectedModels = [NSMutableArray array];
    }
    return _selectedModels;
}

#pragma mark - <System>

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = UIColor.lightGrayColor;
    
    // 1. 初始化UI
    [self setupUI];
}

#pragma mark - <Normal>

/**
 剪切
 
 @return 所选的资源
 */
- (nullable NSArray<WGAssetModel *> *)cropAsset {
    
    if (self.selectedModels.count) {
        
        [self.selectedModels enumerateObjectsUsingBlock:^(WGAssetModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
           
            [self cropWithModel:obj];
        }];
        return self.selectedModels;
    }
    else if (_currentModel) {
        
        [self cropWithModel:_currentModel];
        
        return @[_currentModel];
    }
    return nil;
}

/**
 检测预览图SV是否在操作
 
 @return 是否在操作
 */
- (BOOL)checkPreviewSVISHandle {
    
    return [_preView checkSVISHandle];
}

/**
 剪切
 */
- (void)cropWithModel:(nonnull WGAssetModel *)model {
    
    [LoadingHelper show];
    
    if (
        model.type == WGAssetModelMediaTypePhoto ||
        model.type == WGAssetModelMediaTypeGif ||
        model.type == WGAssetModelMediaTypeLivePhoto
        ) {
        
        CGSize svSize = _preView.svSize;
        CGFloat scale = 1;
        CGPoint offset = CGPointZero;
        CGFloat assetScale = model.assetContentScale;
        
        if (model.scale) {
            
            scale = model.scale.floatValue;
        }
        if (model.contentOffsetX.floatValue > 0) {
            
            offset.x = model.contentOffsetX.floatValue;
        }
        if (model.contentOffsetY.floatValue > 0) {
            
            offset.y = model.contentOffsetY.floatValue;
        }
        CGFloat x = offset.x / scale;
        CGFloat y = offset.y / scale;
        CGFloat w = svSize.width / scale;
        CGFloat h = svSize.height / scale;
        x *= assetScale;
        y *= assetScale;
        w *= assetScale;
        h *= assetScale;
        
        // bug? wh不为整型时 CGImageCreateWithImageInRect 方法生成的图片会存在无效像素
        w = ceilf(w);
        h = ceilf(h);
        
        if (model.type == WGAssetModelMediaTypePhoto) {
            
            CGImageRef ref1 = model.image.CGImage;
            CGImageRef ref2 = CGImageCreateWithImageInRect(ref1, CGRectMake(x, y, w, h));
            model.cropImage = [UIImage imageWithCGImage:ref2];
            CGImageRelease(ref2);
        }
        else if (model.type == WGAssetModelMediaTypeGif) {
            
            CGImageRef ref1 = model.gif.CGImage;
            CGImageRef ref2 = CGImageCreateWithImageInRect(ref1, CGRectMake(x, y, w, h));
            model.cropGif = [UIImage imageWithCGImage:ref2];
            CGImageRelease(ref2);
        }
        else if (model.type == WGAssetModelMediaTypeLivePhoto) {
            
            CGImageRef ref1 = model.live.CGImage;
            CGImageRef ref2 = CGImageCreateWithImageInRect(ref1, CGRectMake(x, y, w, h));
            model.cropLive = [UIImage imageWithCGImage:ref2];
            CGImageRelease(ref2);
        }
    }
    else if (model.type == WGAssetModelMediaTypeVideo) {
        
        model.cropVideo = model.video;
    }
    [LoadingHelper hide];
}

- (void)pcViewDidAppear {
    
    [self playerStart];
}

- (void)pcViewDidDisappear {
    
    [self playerPause];
}

/**
 暂停播放
 */
- (void)playerPause {
    
    [_preView playerPause];
}

/**
 继续播放
 */
- (void)playerStart {
    
    [_preView playerStart];
}

/**
 停止播放
 */
- (void)playerStop {
    
    [_preView playerStop];
}

/**
 更新UI
 
 @param multiSwitch 是否为多选切换
 */
- (void)updateUIWithMultiSwitch:(BOOL)multiSwitch {
    
    const CGFloat preMaxY = CGRectGetMaxY(_preView.frame);
    const CGFloat CVHeight = self.view.bounds.size.height - preMaxY;
    _CV.frame = CGRectMake(0, preMaxY, _preView.bounds.size.width, CVHeight);
    
    CGFloat offsetYDelta = CVHeight - _CVNowHeight;
    _CVNowHeight = CVHeight;
    
    CGPoint offset = _CV.contentOffset;
    offset.y -= multiSwitch ? 0 : offsetYDelta;
    if (offset.y < 0) {
        
        offset.y = 0;
    }
    [_CV setContentOffset:offset animated:NO];
}

/**
 监听预览点击
 */
- (void)didTapPre {
    
    if (_isPrePackUp) {
        
        [UIView animateWithDuration:kAnimeDur animations:^{
            
            CGRect frame = self->_preView.frame;
            frame.origin.y = 0;
            self->_preView.frame = frame;
            
        } completion:^(BOOL finished) {
            
            [self updateUIWithMultiSwitch:NO];
            self->_isPrePackUp = NO;
            [self->_preView maskShow:NO];
            [self scrollToCurrentAsset];
        }];
    }
}

/**
 滚动到当前资源
 */
- (void)scrollToCurrentAsset {
    
    // 滚动到当前选择
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        if (self->_isContainCurrentAsset && self->_currentModel.IP) {
            
            [self->_CV scrollToItemAtIndexPath:self->_currentModel.IP atScrollPosition:UICollectionViewScrollPositionTop animated:YES];
        }
    });
}

/**
 更新预览UI
 */
- (void)updatePreViewUI {
    
    _preView.model = _currentModel;
}

/**
 检测能否选择
 */
- (void)checkCanSelect {
    
    if (_currentModel) {
        
        if (![WGImagePickerConfig sharedInstance].allowMultiVideo) {
            
            if (_currentModel.type == WGAssetModelMediaTypeVideo) {
                
                [_datas enumerateObjectsUsingBlock:^(WGAssetModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        
                    obj.isCanSelect = obj == self->_currentModel;
                }];
                
                return;
            }
        }
        if (self.selectedModels.count) {
            
            [_datas enumerateObjectsUsingBlock:^(WGAssetModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                
                obj.isCanSelect = self->_currentModel.type == obj.type;
            }];
        }
    }
}

/**
 还原可以选择属性
 */
- (void)resetCanSelect {
    
    [_datas enumerateObjectsUsingBlock:^(WGAssetModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        obj.isCanSelect = YES;
    }];
}

/**
 初始化UI
 */
- (void)setupUI {
    
    // 0. 自身
    CGRect frame = self.view.frame;
    frame.origin.y = WGImagePickerRootVCNavMaxY;
    frame.size.width = SCREEN_WIDTH;
    frame.size.height = WGImagePickerRootVCSVNoMultiHeight - frame.origin.y;
    self.view.frame = frame;
    
    // 1. 预览
    WGPhotoPickerVCPreViewWidthHeight = frame.size.width;
    WGPreView *preView = [WGPreView new];
    [self.view addSubview:preView];
    _preView = preView;
    preView.delegate = self;
    preView.backgroundColor = UIColor.whiteColor;
    [preView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapPre)]];
    preView.frame = CGRectMake(0, 0, WGPhotoPickerVCPreViewWidthHeight, WGPhotoPickerVCPreViewWidthHeight);
    _preNormalMaxY = CGRectGetMaxY(preView.frame);
    
    // 2. 选择器
    WGImagePickerConfig *config = [WGImagePickerConfig sharedInstance];
    UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
    const CGFloat itemWH = (_preView.bounds.size.width - (config.colCount - 1) * config.itemMargin) / config.colCount;
    layout.itemSize = CGSizeMake(itemWH, itemWH);
    config.itemSize = layout.itemSize;
    layout.minimumInteritemSpacing = config.itemMargin;
    layout.minimumLineSpacing = config.itemMargin;
    PCCollectionView *CV = [[PCCollectionView alloc] initWithFrame:CGRectMake(0, _preNormalMaxY, _preView.bounds.size.width, self.view.bounds.size.height - _preNormalMaxY) collectionViewLayout:layout];
    [self.view insertSubview:CV belowSubview:preView];
    _CV = CV;
    _CVNowHeight = CV.bounds.size.height;
    CV.dataSource = self;
    CV.delegate = self;
    CV.backgroundColor = UIColor.whiteColor;
    CV.alwaysBounceHorizontal = NO;
    CV.alwaysBounceVertical = YES;
    [CV registerClass:[WGAssetCell class] forCellWithReuseIdentifier:kCellID];
}

/**
 选择相册后调用
 
 @param album 相册模型
 */
- (void)didSelectAlbum:(nonnull WGAlbumModel *)album {
    
    _isContainCurrentAsset = NO;
    
    WGImagePickerConfig *config = [WGImagePickerConfig sharedInstance];
    WEAK(self)
    [[WGImageManager manager] getAssetWithAlbum:album allowPickingVideo:config.allowPickingVideo allowPickingImage:config.allowPickingImage completion:^(NSArray<WGAssetModel *> * _Nonnull models) {
        STRONG(self)
        
        self->_datas = models;
        
        if (!self->_preView.isMulti) { // 单选
            
            if (self->_datas.count) {
                
                self->_currentModel.isSelected = NO;
                self->_currentModel = self->_datas.firstObject;
                self->_currentModel.isSelected = YES;
                self->_isContainCurrentAsset = YES;
                [self updatePreViewUI];
            }
        }
        else { // 多选
            
            if (self.selectedModels.count == 0) {
                
                if (self->_currentModel) {
                    
                    [self->_datas enumerateObjectsUsingBlock:^(WGAssetModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                       
                        if (!self->_isContainCurrentAsset && [obj.ID isEqualToString:self->_currentModel.ID]) {
                            
                            obj.cover = self->_currentModel.cover;
                            obj.scale = self->_currentModel.scale;
                            obj.contentOffsetX = self->_currentModel.contentOffsetX;
                            obj.contentOffsetY = self->_currentModel.contentOffsetY;
                            obj.image = self->_currentModel.image;
                            obj.video = self->_currentModel.video;
                            obj.gif = self->_currentModel.gif;
                            obj.live = self->_currentModel.live;
                            
                            self->_currentModel.isSelected = NO;
                            self->_currentModel = obj;
                            self->_currentModel.isSelected = YES;
                            self->_isContainCurrentAsset = YES;
                            
                            *stop = YES;
                        }
                    }];
                }
            }
            else {
                
                // 遍历已选择
                [self.selectedModels.mutableCopy enumerateObjectsUsingBlock:^(WGAssetModel * _Nonnull seObj, NSUInteger seIdx, BOOL * _Nonnull seStop) {
                    [self->_datas enumerateObjectsUsingBlock:^(WGAssetModel * _Nonnull daObj, NSUInteger daIdx, BOOL * _Nonnull daStop) {
                        
                        if ([seObj.ID isEqualToString:daObj.ID]) {
                            
                            // 缓存迁移
                            daObj.cover = self.selectedModels[seIdx].cover;
                            daObj.scale = self.selectedModels[seIdx].scale;
                            daObj.contentOffsetX = self.selectedModels[seIdx].contentOffsetX;
                            daObj.contentOffsetY = self.selectedModels[seIdx].contentOffsetY;
                            daObj.image = self.selectedModels[seIdx].image;
                            daObj.video = self.selectedModels[seIdx].video;
                            daObj.gif = self.selectedModels[seIdx].gif;
                            daObj.live = self.selectedModels[seIdx].live;
                            
                            self.selectedModels[seIdx] = daObj;
                            daObj.multiNum = seIdx + 1;
                            
                            if (!self->_isContainCurrentAsset && [seObj.ID isEqualToString:self->_currentModel.ID]) {
                                
                                self->_currentModel.isSelected = NO;
                                self->_currentModel = daObj;
                                self->_currentModel.isSelected = YES;
                                self->_isContainCurrentAsset = YES;
                            }
                            *daStop = YES;
                        }
                    }];
                }];
                [self checkCanSelect];
            }
        }
        [self->_CV reloadData];
        [self->_CV setContentOffset:CGPointMake(0, 0) animated:NO];
    }];
}

#pragma mark - <UIScrollViewDelegate>

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    if (scrollView.panGestureRecognizer.state != UIGestureRecognizerStateChanged) {
        
        return;
    }
    if (_isPrePackUp) { // 收起状态
        
        const CGPoint offset = scrollView.contentOffset;
        if (offset.y < 0) {
            
            // 预览部分下移
            CGRect frame = _preView.frame;
            frame.origin.y = kPreMinMaxY - frame.size.height - offset.y;
            _preView.frame = frame;
        }
    }
    else { // 未收起状态
        
        CGFloat viewLocaY = [scrollView.panGestureRecognizer locationInView:self.view].y;
        CGFloat preOffsetY = _preNormalMaxY - viewLocaY;
        
        if (preOffsetY > 0) {
            
            // 预览部分上移
            CGRect frame = _preView.frame;
            frame.origin.y = -preOffsetY;
            _preView.frame = frame;
            
            [self updateUIWithMultiSwitch:NO];
        }
        else if (self.isPreDidChange) {
            
            // 预览部分回归
            CGRect frame = _preView.frame;
            frame.origin.y = 0;
            _preView.frame = frame;
            
            [self updateUIWithMultiSwitch:NO];
        }
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    
    // 收起状态
    if (_isPrePackUp) {
        
        if (scrollView.contentOffset.y < 0) {
            
            [self didTapPre];
        }
    }
    // 未收起状态
    else {
        
        if (self.isPreDidChange) {
            
            const CGFloat maxY = CGRectGetMaxY(_preView.frame);
            __block CGRect frame = _preView.frame;
            
            [UIView animateWithDuration:kAnimeDur animations:^{
                
                // 缩小
                if (maxY < self->_preNormalMaxY * 0.7f) {
                    
                    self->_isPrePackUp = YES;
                    
                    frame.origin.y = -(frame.size.height - kPreMinMaxY);
                }
                // 复原
                else {
                    
                    self->_isPrePackUp = NO;
                    
                    frame.origin.y = 0;
                }
                self->_preView.frame = frame;
                [self->_preView maskShow:self->_isPrePackUp];
                
                if (decelerate || self->_isPrePackUp) {
                    
                    [self updateUIWithMultiSwitch:NO];
                }
            } completion:^(BOOL finished) {
                
                if (!decelerate && !self->_isPrePackUp) {
                    
                    [self updateUIWithMultiSwitch:NO];
                }
            }];
        }
    }
}

#pragma mark - <UICollectionViewDataSource>

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    return _datas.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    WGAssetCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCellID forIndexPath:indexPath];
    WGAssetModel *model = _datas[indexPath.item];
    model.IP = indexPath;
    model.isMulti = _preView.isMulti;
    cell.model = model;
    
    return cell;
}

#pragma mark - <UICollectionViewDelegate>

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    WGAssetModel *model = _datas[indexPath.item];
    
    if (!model.cover) {
        
        return;
    }
    if (!_preView.isMulti) { // 单选状态
        
        if (_currentModel == model) { // 至少选中一个
            
            return;
        }
        _currentModel.scale = nil;
        _currentModel.contentOffsetX= nil;
        _currentModel.contentOffsetY= nil;
        _currentModel.isSelected = NO;
        _currentModel = model;
        _currentModel.isSelected = YES;
        [self updatePreViewUI];
    }
    else { // 多选状态
        
        if (_currentModel == model) {
            
            BOOL last = self.selectedModels.count == 1;
            BOOL none = self.selectedModels.count == 0;
            
            // 只剩最后一个的情况下还原可选属性
            if (last) {

                [self resetCanSelect];
            }
            // 其它情况清空旧属性
            else {
                
                _currentModel.isSelected = NO;
                _currentModel = nil;
                
                model.scale = nil;
                model.contentOffsetX = nil;
                model.contentOffsetY = nil;
            }
            
            [self.selectedModels removeObject:model];
            model.multiNum = 0;
            
            // 无所选时添加进数组(能进来这说明上的round已进入last环节)
            if (none) {
                
                [self.selectedModels addObject:model];
            }
            
            [self.selectedModels enumerateObjectsUsingBlock:^(WGAssetModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                
                // 更新旧角标
                obj.multiNum = idx + 1;
                
                // 选中最后一个
                if (idx == self.selectedModels.count - 1) {
                    
                    self->_currentModel = obj;
                    self->_currentModel.isSelected = YES;
                    
                    if (none) {
                     
                        [self checkCanSelect];
                    }
                }
            }];
        }
        else {
            
            if (!model.multiNum) {
                
                if (model.isCanSelect) {
                    
                    if (self.selectedModels.count < [WGImagePickerConfig sharedInstance].maxImagesCount) {
                        
                        [self.selectedModels addObject:model];
                        model.multiNum = self.selectedModels.count;
                    }
                    else {
                        
                        [PopView popWithContent:[NSString stringWithFormat:@"最多只能选择%zd个", [WGImagePickerConfig sharedInstance].maxImagesCount]];
                        
                        return;
                    }
                }
                else {
                    
                    return;
                }
            }
            _currentModel.isSelected = NO;
            _currentModel = model;
            _currentModel.isSelected = YES;
            
            // 更新可否选择信息
            if (self.selectedModels.count == 1) {
                
                [self checkCanSelect];
            }
        }
        [self updatePreViewUI];
    }
    [collectionView reloadData];
    
    if (_isPrePackUp) {
        
        [UIView animateWithDuration:kAnimeDur animations:^{
            
            self->_isPrePackUp = NO;
            [self->_preView maskShow:NO];
            self->_preView.y = 0;
            [self updateUIWithMultiSwitch:NO];
            
        } completion:^(BOOL finished) {
        
            [self scrollToCurrentAsset];
        }];
    }
}

#pragma mark - <WGPreViewDelegate>

/**
 多选按钮点击回调
 
 @param preView 自身
 */
- (void)didClickMultiInPreView:(nonnull __kindof WGPreView *)preView {
    
    if (!_datas.count) {
        
        return;
    }
    _preView.isMulti = !_preView.isMulti;
    
    [_datas enumerateObjectsUsingBlock:^(WGAssetModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        obj.isMulti = self->_preView.isMulti;
        obj.multiNum = 0;
        if (!self->_preView.isMulti) {
            
            obj.scale = nil;
            obj.contentOffsetX = nil;
            obj.contentOffsetY = nil;
        }
    }];
    
    [self.selectedModels removeAllObjects];
    
    if (self->_preView.isMulti) {
        
        _currentModel.multiNum = 1;
        [self.selectedModels addObject:_currentModel];
        [self checkCanSelect];
    }
    else {
        
        [self updatePreViewUI];
        [self resetCanSelect];
    }
    [_CV reloadData];
    
    if ([self.delegate respondsToSelector:@selector(photoPickerVC:didSelectMulti:)]) {
        [self.delegate photoPickerVC:self didSelectMulti:_preView.isMulti];
    }
    CGRect frame = self.view.frame;
    frame.size.height = _preView.isMulti ? WGImagePickerRootVCSVMultiHeight - frame.origin.y : WGImagePickerRootVCSVNoMultiHeight - frame.origin.y;
    self.view.frame = frame;
    [self updateUIWithMultiSwitch:YES];
    
    if (!_preView.isMulti) {
        
        [self scrollToCurrentAsset];
    }
}

@end

@implementation PCCollectionView

- (BOOL)touchesShouldCancelInContentView:(UIView *)view {
    
    if ([view isKindOfClass:[UIControl class]]) {
        
        return YES;
    }
    return [super touchesShouldCancelInContentView:view];
}

@end
