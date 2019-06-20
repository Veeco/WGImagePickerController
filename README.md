# WGImagePickerController
模仿Ins的图片选择器

## 不废话直接看效果
![1.gif](https://upload-images.jianshu.io/upload_images/2404215-881d1a6767de6f05.gif?imageMogr2/auto-orient/strip)

## 使用方法
引用头文件后, 直接上代码:
```objc
    WGImagePickerVC *VC = [WGImagePickerVC imagePickerWithMaxImagesCount:9];
    VC.didPickHandle = ^(NSArray<WGAssetModel *> * _Nullable models) {
        
        // 此处为选择资源后的执行操作
        NSLog(@"%@", models);
    };
    [self presentViewController:VC animated:YES completion:nil];
```
PS : 未支持Live图的展示, 底部的拍摄功能未实现.

### 最近忙着人生大事很少回复希望大家多多见谅, 如有意见或其它想法可以多多提出, 谢谢!
