//
//  WGImagePickerConfig.m
//  Puchi
//
//  Created by Veeco on 2019/1/15.
//  Copyright © 2019 Chance. All rights reserved.
//

#import "WGImagePickerConfig.h"

@implementation WGImagePickerConfig

/**
 单例
 
 @return 实例
 */
+ (instancetype)sharedInstance {
    
    static WGImagePickerConfig *config = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        if (config == nil) {
            
            config = [WGImagePickerConfig new];
            config->_gifPreviewMaxImagesCount = 200;
        }
    });
    return config;
}

@end
