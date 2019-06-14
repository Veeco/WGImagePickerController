//
//  WGAlbumCell.m
//  Puchi
//
//  Created by Veeco on 2019/1/16.
//  Copyright © 2019 Chance. All rights reserved.
//

#import "WGAlbumCell.h"
#import "Masonry.h"
#import "UtilHeader.h"
#import "WGAlbumModel.h"
#import "WGImageManager.h"
#import "ColorHeader.h"

@interface WGAlbumCell ()

{
    /** 封面 */
    __weak UIImageView *_cover;
    /** 标题 */
    __weak UILabel *_title;
    /** 资源数 */
    __weak UILabel *_count;
}

@end

/** 封面宽高 */
static const CGFloat kCoverWH = 100;

@implementation WGAlbumCell

#pragma mark - <System>

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        
        self.backgroundColor = UIColor.clearColor;
        
        UIImageView *cover = [UIImageView new];
        [self.contentView addSubview:cover];
        _cover = cover;
        cover.contentMode = UIViewContentModeScaleAspectFill;
        cover.layer.masksToBounds = YES;
        [cover mas_makeConstraints:^(MASConstraintMaker *make) {
           
            make.width.mas_equalTo(kCoverWH);
            make.height.mas_equalTo(kCoverWH);
            make.left.mas_equalTo(15);
            make.top.mas_equalTo(0);
        }];
        
        UILabel *title = [UILabel new];
        [self.contentView addSubview:title];
        _title = title;
        title.font = BOLD_SIZE(13);
        title.textColor = UIColorMakeFromRGB(0x222222);
        [title mas_makeConstraints:^(MASConstraintMaker *make) {
           
            make.left.mas_equalTo(cover.mas_right).mas_offset(15);
            make.top.mas_equalTo(35);
        }];
        
        UILabel *count = [UILabel new];
        [self.contentView addSubview:count];
        _count = count;
        count.font = FONT_SIZE(11);
        count.textColor = title.textColor;
        [count mas_makeConstraints:^(MASConstraintMaker *make) {
           
            make.left.mas_equalTo(title);
            make.top.mas_equalTo(title.mas_bottom).mas_offset(6);
        }];
    }
    return self;
}

#pragma mark - <Normal>

- (void)setModel:(WGAlbumModel *)model {
    _model = model;
    
    WEAK(self)
    [[WGImageManager manager] getPostImageWithAlbumModel:model widthPixel:kCoverWH * 2 completion:^(UIImage * _Nullable image) {
        STRONG(self)
        
        self->_cover.image = image;
    }];
    
    _title.text = model.name;
    _count.text = [NSString stringWithFormat:@"%zd", model.count];
}

@end
