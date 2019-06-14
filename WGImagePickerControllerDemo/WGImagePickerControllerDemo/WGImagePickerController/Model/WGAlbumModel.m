//
//  WGAlbumModel.m
//  Puchi
//
//  Created by Veeco on 2019/1/15.
//  Copyright © 2019 Chance. All rights reserved.
//

#import "WGAlbumModel.h"
#import "WGImageManager.h"
#import "WGAssetModel.h"

@implementation WGAlbumModel

- (NSString *)name {
    
    if (_name) {
        
        return _name;
    }
    return @"";
}

@end
