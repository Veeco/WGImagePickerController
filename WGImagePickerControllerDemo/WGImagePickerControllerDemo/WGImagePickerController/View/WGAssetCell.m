//
//  WGAssetCell.m
//  Puchi
//
//  Created by Veeco on 2019/1/22.
//  Copyright © 2019 Chance. All rights reserved.
//

#import "WGAssetCell.h"
#import "WGAssetModel.h"
#import "WGImagePickerConfig.h"
#import "WGImageManager.h"
#import "UtilHeader.h"
#import "ColorHeader.h"
#import "UIView+WGExtension.h"

@interface WGAssetCell ()

{
    /** 内容 */
    __weak UIImageView *_image;
    /** 多选标识 */
    __weak UILabel *_multiNum;
    /** 视频长度 */
    __weak UILabel *_videoLength;
    /** 视频标识 */
    __weak UIView *_videoHint;
    /** 视频图标 */
    __weak UIImageView *_videoImage;
    /** 遮罩 */
    __weak UIView *_mask;
}

@end

@implementation WGAssetCell

#pragma mark - <System>

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        
        UIImageView *image = [UIImageView new];
        [self.contentView addSubview:image];
        _image = image;
        image.contentMode = UIViewContentModeScaleAspectFill;
        image.layer.masksToBounds = YES;
        
        const CGFloat multiWH = 20;
        UILabel *multiNum = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, multiWH, multiWH)];
        [self.contentView addSubview:multiNum];
        _multiNum = multiNum;
        multiNum.textColor = UIColor.whiteColor;
        multiNum.font = [UIFont systemFontOfSize:12];
        multiNum.textAlignment = NSTextAlignmentCenter;
        multiNum.layer.borderWidth = 1;
        multiNum.layer.cornerRadius = multiWH / 2;
        multiNum.layer.masksToBounds = YES;
        multiNum.hidden = YES;
        
        UIView *videoHint = [UIView new];
        [self.contentView addSubview:videoHint];
        _videoHint = videoHint;
        videoHint.hidden = YES;
        videoHint.layer.shadowOpacity = 1;
        videoHint.layer.shadowOffset = CGSizeZero;
        
        UIImageView *videoImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"publish_camera_shoot"]];
        [videoHint addSubview:videoImage];
        _videoImage = videoImage;
        
        UILabel *videoLength = [UILabel new];
        [videoHint addSubview:videoLength];
        _videoLength = videoLength;
        videoLength.font = [UIFont systemFontOfSize:12];
        videoLength.textColor = UIColor.whiteColor;
        
        UIView *mask = [UIView new];
        [self.contentView addSubview:mask];
        _mask = mask;
        mask.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.6f];
        mask.hidden = YES;
    }
    return self;
}

#pragma mark - <Normal>

- (void)setModel:(WGAssetModel *)model {
    _model = model;
    
    WGImagePickerConfig *config = [WGImagePickerConfig sharedInstance];
    const CGFloat itemWH = config.itemSize.width;
    
    // 0. 可用
    _mask.frame = (CGRect){CGPointZero, config.itemSize};
    _mask.hidden = !model.isMulti || model.isCanSelect;
    
    // 1. 内容
    _image.frame = _mask.frame;
    _image.image = nil;
    
    if (model.cover) {
        
        _image.image = model.cover;
    }
    else {
        
        WEAK(self)
        [[WGImageManager manager] getPhotoWithAsset:model.asset widthPixel:itemWH * 2 completion:^(UIImage * _Nullable image, NSDictionary * _Nullable info, BOOL isDegraded) {
            STRONG(self)
            
            if (image) {
                
                model.cover = image;
                self->_image.image = image;
            }
        }];
    }
    
    // 2. 视频标识
    if (model.type == WGAssetModelMediaTypeVideo) {
        
        NSShadow *shadow = [NSShadow new];
        shadow.shadowBlurRadius = 2.0;
        shadow.shadowOffset = CGSizeMake(0, 0);
        shadow.shadowColor = UIColorMakeFromRGBA(0x000000, 0.3);
        _videoLength.attributedText = [[NSAttributedString alloc] initWithString:model.timeLength attributes:@{NSShadowAttributeName : shadow}];
        [_videoLength sizeToFit];
        _videoLength.x = CGRectGetMaxX(_videoImage.frame) + 5;
        
        _videoHint.width = CGRectGetMaxX(_videoLength.frame);
        _videoHint.height = MAX(_videoImage.height, _videoLength.height);
        
        _videoImage.centerY = _videoHint.height / 2;
        _videoLength.centerY = _videoImage.centerY;
        
        _videoHint.x = itemWH - 6 - _videoHint.width;
        _videoHint.y = itemWH - 2.5f - _videoLength.height;
        
        _videoHint.hidden = NO;
    }
    else {
        
        _videoHint.hidden = YES;
    }
    
    // 3. 多选
    if (model.isMulti && self.model.isCanSelect) {
        
        _multiNum.hidden = NO;
        _multiNum.frame = (CGRect){itemWH - 5 - _multiNum.bounds.size.width, 5, _multiNum.bounds.size};
        
        if (model.multiNum > 0) {
            
            _multiNum.text = [NSString stringWithFormat:@"%zd", model.multiNum];
            _multiNum.backgroundColor = UIColorMakeFromRGB(0xf8c301);
            _multiNum.layer.borderColor = _multiNum.backgroundColor.CGColor;
        }
        else {
            
            _multiNum.text = nil;
            _multiNum.backgroundColor = UIColorMakeFromRGBA(0x999999, 0.6f);
            _multiNum.layer.borderColor = UIColor.whiteColor.CGColor;
        }
    }
    else {
        
        _multiNum.hidden = YES;
    }
    
    // 4. 选中
    self.contentView.alpha = model.isSelected ? 0.6f : 1;
}

@end
