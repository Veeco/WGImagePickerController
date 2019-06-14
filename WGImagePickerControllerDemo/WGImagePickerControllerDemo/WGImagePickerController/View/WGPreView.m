//
//  WGPreView.m
//  Puchi
//
//  Created by Veeco on 2019/1/29.
//  Copyright © 2019 Chance. All rights reserved.
//

#import "WGPreView.h"
#import "WGAssetModel.h"
#import "WGImagePickerParam.h"
#import "WGImageManager.h"
#import "UtilHeader.h"
#import "WGImagePickerConfig.h"
#import "UIView+WGExtension.h"

@interface WGPreView () <UIScrollViewDelegate>

{
    /** SV */
    UIScrollView *_SV;
    /** 图像 */
    UIImageView *_image;
    /** 视频 */
    UIView *_video;
    AVPlayer *_player;
    AVPlayerLayer *_videoLayer;
    /** Gif */
    UIImageView *_gif;
    /** Live */
    UIImageView *_live;
    /** 格仔 */
    UIImageView *_box;
    /** 蒙板 */
    UIView *_mask;
    /** 当前类型 */
    WGAssetModelMediaType _currentType;
    /** 当前展示容器 */
    __weak UIView *_currentContentView;
    /** 当前资源 */
    id _currentAsset;
    /** 多选按钮 */
    __weak UIButton *_multi;
    /** 缩放按钮 */
    __weak UIButton *_zoom;
    /** 当前展示容器默认尺寸 */
    CGSize _defaultSize;
}

@end

// 动画执行时长
static const NSTimeInterval kAnimeDur = 0.2f;
// 极限尺寸
static const CGFloat kMaxScale = 16.0f/9;
static const CGFloat kMinScale = 4.0f/5;

@implementation WGPreView

#pragma mark - <Getter & Setter>

- (CGSize)svSize {
    
    return _SV.size;
}

- (void)setIsMulti:(BOOL)isMulti {
    _isMulti = isMulti;
 
    _multi.selected = isMulti;
    _zoom.hidden = isMulti;
    
    if (isMulti) {
        
        // 重新布置内容尺寸
        if (_SV.contentSize.width < _SV.width || _SV.contentSize.height < _SV.height) {
            
            self.model.scale = nil;
        }
        
        CGFloat w = _currentContentView.width;
        CGFloat h = _currentContentView.height;
        
        if (w < _SV.width - 1) { // - 1 为防止有SB错误 居然 w 有可能为 413.99999999 _SV.width 为 414
            
            _SV.width = w;
            _SV.centerX = self.width / 2;
            UIEdgeInsets inset = _SV.contentInset;
            inset.left = inset.right = 0;
            _SV.contentInset = inset;
        }
        else if (h < _SV.height) {
            
            _SV.height = h;
            _SV.centerY = self.height / 2;
            UIEdgeInsets inset = _SV.contentInset;
            inset.top = inset.bottom = 0;
            _SV.contentInset = inset;
        }
        
        // 重新布置内容尺寸
        [_SV setZoomScale:1 animated:NO];
        [_SV setContentInset:UIEdgeInsetsZero];
        [self layoutContentView];
    }
    else {
        
        _SV.frame = self.bounds;
    }
}

#pragma mark - <System>

- (instancetype)initWithFrame:(CGRect)frame {
    
    frame = CGRectMake(0, 0, WGPhotoPickerVCPreViewWidthHeight, WGPhotoPickerVCPreViewWidthHeight);
    
    if (self = [super initWithFrame:frame]) {
        
        _SV = [[UIScrollView alloc] initWithFrame:frame];
        [self addSubview:_SV];
        _SV.alwaysBounceVertical = YES;
        _SV.alwaysBounceHorizontal = YES;
        _SV.delegate = self;
        _SV.maximumZoomScale = 5;
        _SV.minimumZoomScale = CGFLOAT_MIN;
        
        _image = [[UIImageView alloc] initWithFrame:frame];
        [_SV addSubview:_image];
        _image.hidden = YES;
        
        _video = [[UIView alloc] initWithFrame:frame];
        [_SV addSubview:_video];
        _player = [AVPlayer playerWithPlayerItem:nil];
        _player.volume = 0;
        _videoLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
        [_video.layer addSublayer:_videoLayer];
        _video.layer.masksToBounds = YES;
        _video.hidden = YES;
        
        _gif = [[UIImageView alloc] initWithFrame:frame];
        [_SV addSubview:_gif];
        _gif.hidden = YES;
        
        _live = [[UIImageView alloc] initWithFrame:frame];
        [_SV addSubview:_live];
        _live.hidden = YES;
        
        _box = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"box"]];
        [self addSubview:_box];
        _box.frame = frame;
        _box.alpha = 0;
        _box.userInteractionEnabled = NO;
        
        UIButton *multi = [UIButton new];
        [self addSubview:multi];
        _multi = multi;
        const CGFloat wh = 34;
        multi.size = CGSizeMake(wh, wh);
        frame = multi.frame;
        frame.origin.x = self.width - frame.size.width - 15;
        frame.origin.y = self.height - frame.size.height - 15;
        multi.frame = frame;
        [multi addTarget:self action:@selector(didClickMulti:) forControlEvents:UIControlEventTouchUpInside];
        [multi setBackgroundImage:[UIImage imageNamed:@"publish_photo_choosemore"] forState:UIControlStateNormal];
        [multi setBackgroundImage:[UIImage imageNamed:@"publish_photo_choosemore_on"] forState:UIControlStateSelected];
        
        UIButton *zoom = [UIButton new];
        [self addSubview:zoom];
        _zoom = zoom;
        zoom.size = multi.size;
        zoom.x = 15;
        zoom.y = multi.y;
        [zoom addTarget:self action:@selector(didClickZoom:) forControlEvents:UIControlEventTouchUpInside];
        [zoom setBackgroundImage:[UIImage imageNamed:@"publish_photo_reduce"] forState:UIControlStateNormal];
        [zoom setBackgroundImage:[UIImage imageNamed:@"publish_photo_enlarge"] forState:UIControlStateSelected];
        
        _mask = [[UIView alloc] initWithFrame:self.bounds];
        [self addSubview:_mask];
        _mask.backgroundColor = UIColor.blackColor;
        _mask.alpha = 0;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didPlayToEnd) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
}

#pragma mark - <Normal>

/**
 监听多选按钮点击
 
 @param multi 按钮
 */
- (void)didClickMulti:(UIButton *)multi {
    
    if ([self checkSVISHandle]) {
        
        return;
    }
    if ([self.delegate respondsToSelector:@selector(didClickMultiInPreView:)]) {
        [self.delegate didClickMultiInPreView:self];
    }
}

/**
 监听缩放按钮点击
 
 @param zoom 缩放按钮
 */
- (void)didClickZoom:(UIButton *)zoom {
    
    if ([self checkSVISHandle]) {
        
        return;
    }
    _isZoomMin = !self.isZoomMin;
    zoom.selected = self.isZoomMin;
    [self handleZoomRectWithZoomButton:YES];
}

/**
 检测SV是否在操作

 @return 是否在操作
 */
- (BOOL)checkSVISHandle {
    
    return _SV.panGestureRecognizer.state != UIGestureRecognizerStatePossible || _SV.pinchGestureRecognizer.state != UIGestureRecognizerStatePossible;
}

/**
 监听播放完成
 */
- (void)didPlayToEnd {
    
    [_player seekToTime:kCMTimeZero completionHandler:^(BOOL finished) {}];
    [_player pause];
    [_player play];
}

/**
 展示蒙板
 
 @param show 是否展示蒙板
 */
- (void)maskShow:(BOOL)show {
    
    _mask.alpha = show ? 0.3f : 0;
}

/**
 处理缩放区域
 
 @param zoomButton 是否点击缩放按钮进入
 */
- (void)handleZoomRectWithZoomButton:(BOOL)zoomButton {
    
    CGFloat coverW = self.model.asset.pixelWidth;
    CGFloat coverH = self.model.asset.pixelHeight;
    
    if (coverW <= 0 || coverH <= 0) {
        
        return;
    }
    
    CGFloat scale = coverW / coverH;
    CGFloat zoomScale = 1;
    
    // 单选
    if (!self.isMulti) {
        
        if (self.isZoomMin || self.model.type == WGAssetModelMediaTypeVideo) {
            
            // 横图 原上下顶边
            if (scale > 1) {
                
                // => SV高度变小上下顶边
                if (scale > kMaxScale && self.model.type != WGAssetModelMediaTypeVideo) {
                    
                    const CGFloat targetH = _SV.width / kMaxScale;
                    coverH = targetH;
                }
                else {
                    
                    // => 左右顶边
                    coverW = _SV.width;
                    coverH = coverW / scale;
                }
                zoomScale = coverH / _defaultSize.height;
            }
            // 竖图 左右顶边 => 上下顶边
            else {
                
                // => SV高度变小上下顶边
                if (scale < kMinScale && self.model.type != WGAssetModelMediaTypeVideo) {
                
                    const CGFloat targetW = _SV.height * kMinScale;
                    coverW = targetW;
                }
                else {
                    
                    coverH = _SV.height;
                    coverW = coverH * scale;
                }
                zoomScale = coverW / _defaultSize.width;
            }
        }
    }
    // 多选
    else {
     
        if (self.model.scale) {
            
            zoomScale = self.model.scale.floatValue;
        }
    }
    [UIView animateWithDuration:zoomButton ? kAnimeDur : 0 animations:^{
        
        [self->_SV setZoomScale:zoomScale animated:NO];
        
        if (self.isMulti) {
                
            CGPoint offset = self->_SV.contentOffset;
            offset.x = self.model.contentOffsetX ? self.model.contentOffsetX.floatValue : offset.x;
            offset.y = self.model.contentOffsetY ? self.model.contentOffsetY.floatValue : offset.y;
            [self->_SV setContentOffset:offset animated:NO];
        }
        [self handleInsetWithAnime:NO];
    }];
}

/**
 边距处理
 
 @param anime 是否需要动画
 */
- (void)handleInsetWithAnime:(BOOL)anime {
    
    [UIView animateWithDuration:anime ? kAnimeDur : 0 animations:^{
        
        [self handleZoomInset];
        
    } completion:^(BOOL finished) {
        
        self.model.scale = @(self->_SV.zoomScale);
        [self markOffset:nil];
    }];
}

/**
 处理缩放后内边距
 */
- (void)handleZoomInset {
    
    CGPoint defaultOffset = CGPointMake((_SV.contentSize.width - _SV.width) / 2, (_SV.contentSize.height - _SV.height) / 2);
    UIEdgeInsets inset = _SV.contentInset;
    inset.left = inset.right = defaultOffset.x < 0 ? -defaultOffset.x : 0;
    inset.top = inset.bottom = defaultOffset.y < 0 ? -defaultOffset.y : 0;
    _SV.contentInset = inset;
}

/**
 布局容器
 */
- (void)layoutContentView {
    
    _currentContentView.size = [self getContentViewSize];
    _defaultSize = _currentContentView.size;
    
    if (_currentContentView == _video) {
            
        [_videoLayer removeFromSuperlayer];
        _videoLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
        _videoLayer.frame = _video.bounds;
        [_video.layer addSublayer:_videoLayer];
    }
    CGSize contentSize = _currentContentView.size;
    
    if (contentSize.width < _SV.width) {
        contentSize.width = _SV.width;
    }
    if (contentSize.height < _SV.height) {
        contentSize.height = _SV.height;
    }
    _SV.contentSize = contentSize;
    _currentContentView.center = CGPointMake(_SV.contentSize.width / 2, _SV.contentSize.height / 2);
    [_SV setContentOffset:CGPointMake((_SV.contentSize.width - _SV.width) / 2, (_SV.contentSize.height - _SV.height) / 2) animated:NO];
    
    [self handleZoomRectWithZoomButton:NO];
}

/**
 设置内容
 */
- (void)setContent {
    
    if (!self->_currentContentView) {
        
        return;
    }
    [_SV setZoomScale:1 animated:NO];
    [self->_SV setContentInset:UIEdgeInsetsZero];
    
    if (_currentType == WGAssetModelMediaTypePhoto && [_currentAsset isKindOfClass:[UIImage class]]) {
        
        UIImage *image = _currentAsset;
        _image.image = nil;
        [self layoutContentView];
        _image.image = image;
    }
    else if (_currentType == WGAssetModelMediaTypeVideo && [_currentAsset isKindOfClass:[AVPlayerItem class]]) {
        
        AVPlayerItem *item = _currentAsset;
        [self layoutContentView];
        [_player replaceCurrentItemWithPlayerItem:item];
        [self playerStart];
    }
    else if (_currentType == WGAssetModelMediaTypeGif && [_currentAsset isKindOfClass:[UIImage class]]) {
        
        UIImage *image = _currentAsset;
        [self layoutContentView];
        _gif.image = image;
    }
    else if (_currentType == WGAssetModelMediaTypeLivePhoto && [_currentAsset isKindOfClass:[UIImage class]]) {
        
        UIImage *image = _currentAsset;
        [self layoutContentView];
        _live.image = image;
    }
}

/**
 记录偏移量
 */
- (void)markOffset:(nullable CGPoint *)offset {
    
    if (_SV.contentSize.width > _SV.width) {
        
        self.model.contentOffsetX = offset ? @([NSValue valueWithCGPoint:*offset].CGPointValue.x) : @(_SV.contentOffset.x);
    }
    else {
        
        self.model.contentOffsetX = nil;
    }
    if (_SV.contentSize.height > _SV.height) {
        
        self.model.contentOffsetY = offset ? @([NSValue valueWithCGPoint:*offset].CGPointValue.y) : @(_SV.contentOffset.y);
    }
    else {
        
        self.model.contentOffsetY = nil;
    }
}

- (void)setModel:(WGAssetModel *)model {
    _model = model;
    
    [self playerStop];
    _currentType = model.type;
    _currentContentView = nil;
    _defaultSize = CGSizeZero;
    _zoom.hidden = _isMulti;
    _multi.hidden = NO;
    
    _image.hidden = YES;
    _video.hidden = YES;
    _gif.hidden = YES;
    _live.hidden = YES;
    _SV.pinchGestureRecognizer.enabled = NO;
    
    if (model.type == WGAssetModelMediaTypePhoto) {
        
        _SV.pinchGestureRecognizer.enabled = YES;
        _currentContentView = _image;
        _currentContentView.hidden = NO;
        
        if (model.image) {
            
            _currentAsset = model.image;
            [self setContent];
        }
        else {
            
            _image.image = model.cover;
            
            WEAK(self)
            [[WGImageManager manager] getPhotoWithAsset:model.asset widthPixel:model.asset.pixelWidth completion:^(UIImage * _Nullable image, NSDictionary * _Nullable info, BOOL isDegraded) {
                STRONG(self)
                
                if (image) {
                    
                    self->_currentAsset = image;
                    model.image = image;
                    [self setContent];
                }
            }];
        }
    }
    else if (model.type == WGAssetModelMediaTypeVideo) {
        
        _zoom.hidden = YES;
        
        if (![WGImagePickerConfig sharedInstance].allowMultiVideo) {
            
            _multi.hidden = YES;
        }
        
        _currentContentView = _video;
        _currentContentView.hidden = NO;
        
        if (model.video) {
            
            _currentAsset = model.video;
            [self setContent];
        }
        else {
            
            WEAK(self)
            [[WGImageManager manager] getVideoWithAsset:model.asset progressHandler:nil completion:^(AVPlayerItem * _Nullable playerItem, NSDictionary * _Nullable info) {
                STRONG(self)
                
                if (playerItem) {
                    
                    self->_currentAsset = playerItem;
                    model.video = playerItem;
                    [self setContent];
                }
            }];
        }
    }
    else if (model.type == WGAssetModelMediaTypeGif) {
        
        _currentContentView = _gif;
        _currentContentView.hidden = NO;
        
        if (model.gif) {
            
            _currentAsset = model.gif;
            [self setContent];
        }
        else {
            
            _gif.image = model.cover;
            
            WEAK(self)
            [[WGImageManager manager] getPhotoWithAsset:model.asset widthPixel:model.asset.pixelWidth completion:^(UIImage * _Nullable image, NSDictionary * _Nullable info, BOOL isDegraded) {
                STRONG(self)
                
                if (image) {
                    
                    self->_currentAsset = image;
                    model.gif = image;
                    [self setContent];
                }
            }];
        }
    }
    else if (model.type == WGAssetModelMediaTypeLivePhoto) {
        
        _currentContentView = _live;
        _currentContentView.hidden = NO;
        
        if (model.live) {
            
            _currentAsset = model.live;
            [self setContent];
        }
        else {
            
            _live.image = model.cover;
            
            WEAK(self)
            [[WGImageManager manager] getPhotoWithAsset:model.asset widthPixel:model.asset.pixelWidth completion:^(UIImage * _Nullable image, NSDictionary * _Nullable info, BOOL isDegraded) {
                STRONG(self)
                
                if (image) {
                    
                    self->_currentAsset = image;
                    model.live = image;
                    [self setContent];
                }
            }];
        }
    }
}

/**
 获取容器大小

 @return 容器大小
 */
- (CGSize)getContentViewSize {
    
    CGFloat coverW = self.model.asset.pixelWidth;
    CGFloat coverH = self.model.asset.pixelHeight;
    
    if (coverW <= 0 || coverH <= 0) {
        
        return CGSizeZero;
    }
    const CGFloat scale = coverW / coverH;
    const CGFloat svScale = _SV.width / _SV.height;
    
    CGFloat imageW = 0;
    CGFloat imageH = 0;
    
    if (self.model.type == WGAssetModelMediaTypePhoto) {
        
        imageW = self.model.image.size.width;
        imageH = self.model.image.size.height;
    }
    else if (self.model.type == WGAssetModelMediaTypeGif) {
        
        imageW = self.model.gif.size.width;
        imageH = self.model.gif.size.height;
    }
    else if (self.model.type == WGAssetModelMediaTypeLivePhoto) {
        
        imageW = self.model.live.size.width;
        imageH = self.model.live.size.height;
    }
    
    // 上下顶边
    if (scale > svScale) {
        
        coverH = _SV.height;
        coverW = coverH * scale;
        self.model.assetContentScale = imageH / coverH;
    }
    // 左右顶边
    else {
        
        coverW = _SV.width;
        coverH = coverW / scale;
        self.model.assetContentScale = imageW / coverW;
    }
    return CGSizeMake(coverW, coverH);
}

/**
 暂停播放
 */
- (void)playerPause {
    
    if (_currentType == WGAssetModelMediaTypeVideo) {
        
        [_player pause];
    }
}

/**
 继续播放
 */
- (void)playerStart {
    
    if (_currentType == WGAssetModelMediaTypeVideo) {
        
        [_player play];
    }
}

/**
 停止播放
 */
- (void)playerStop {
    
    if (_currentType == WGAssetModelMediaTypeVideo) {
        
        [_player seekToTime:kCMTimeZero completionHandler:^(BOOL finished) {}];
        [_player pause];
        [_player replaceCurrentItemWithPlayerItem:nil];
    }
}

#pragma mark - <UIScrollViewDelegate>

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    
    _box.alpha = 1;
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    
    [UIView animateWithDuration:kAnimeDur animations:^{
       
        self->_box.alpha = 0;
    }];
    [self markOffset:targetContentOffset];
}

- (nullable UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    
    if (_currentType == WGAssetModelMediaTypePhoto) {
        
        return _image;
    }
    if (_currentType == WGAssetModelMediaTypeVideo) {
        
        return _video;
    }
    return nil;
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view {
    
    _box.alpha = 1;
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(nullable UIView *)view atScale:(CGFloat)scale {
    
    [UIView animateWithDuration:kAnimeDur animations:^{
        
        self->_box.alpha = 0;
    }];
    
    // 单选
    if (!self.isMulti) {
        
        CGFloat showW = view.width > _SV.width ? _SV.width : view.width;
        CGFloat showH = view.height > _SV.height ? _SV.height : view.height;
        CGFloat whScale = showW / showH;
        
        if (whScale > kMaxScale || whScale < kMinScale || (showW < _SV.width && showH < _SV.height)) {
            
            _isZoomMin = YES;
            [self handleZoomRectWithZoomButton:YES];
        }
        else {
            
            _isZoomMin = NO;
            [self handleInsetWithAnime:YES];
        }
        _zoom.selected = _isZoomMin;
    }
    // 多选
    else {
        
        if (view.width < _SV.width || view.height < _SV.height) {
            
            self.model.scale = nil;
            [self handleZoomRectWithZoomButton:YES];
        }
        else {
            
            [self handleInsetWithAnime:YES];
        }
    }
}

@end
