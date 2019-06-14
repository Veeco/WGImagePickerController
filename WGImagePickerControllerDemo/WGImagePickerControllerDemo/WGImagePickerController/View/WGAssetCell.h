//
//  WGAssetCell.h
//  Puchi
//
//  Created by Veeco on 2019/1/22.
//  Copyright © 2019 Chance. All rights reserved.
//

#import <UIKit/UIKit.h>
@class WGAssetModel;

NS_ASSUME_NONNULL_BEGIN

@interface WGAssetCell : UICollectionViewCell

/** 模型 */
@property (nullable, nonatomic, strong) WGAssetModel *model;

@end

NS_ASSUME_NONNULL_END
