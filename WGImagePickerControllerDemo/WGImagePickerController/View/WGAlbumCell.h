//
//  WGAlbumCell.h
//  Puchi
//
//  Created by Veeco on 2019/1/16.
//  Copyright © 2019 Chance. All rights reserved.
//

#import <UIKit/UIKit.h>
@class WGAlbumModel;

NS_ASSUME_NONNULL_BEGIN

@interface WGAlbumCell : UITableViewCell

/** 模型 */
@property (nullable, nonatomic, strong) WGAlbumModel *model;

@end

NS_ASSUME_NONNULL_END
