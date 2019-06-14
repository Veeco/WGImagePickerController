//
//  ViewController.m
//  WGImagePickerControllerDemo
//
//  Created by Veeco on 2019/6/14.
//  Copyright © 2019 Chance. All rights reserved.
//

#import "ViewController.h"
#import "WGImagePickerVC.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    WGImagePickerVC *VC = [WGImagePickerVC imagePickerWithMaxImagesCount:9];
    VC.didPickHandle = ^(NSArray<WGAssetModel *> * _Nullable models) {
        
        NSLog(@"%@", models);
    };
    [self presentViewController:VC animated:YES completion:nil];
}

@end
