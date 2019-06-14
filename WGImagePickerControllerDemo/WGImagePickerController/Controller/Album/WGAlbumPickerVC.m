//
//  WGAlbumPickerVC.m
//  Puchi
//
//  Created by Veeco on 2019/1/15.
//  Copyright © 2019 Chance. All rights reserved.
//

#import "WGAlbumPickerVC.h"
#import "WGImageManager.h"
#import "WGImagePickerConfig.h"
#import "WGAlbumModel.h"
#import "WGAlbumCell.h"
#import "ColorHeader.h"

@interface WGAlbumPickerVC () <UITableViewDataSource, UITableViewDelegate>

{
    /** 相册数据源 */
    NSArray<WGAlbumModel *> *_albumArr;
}

@end

@implementation WGAlbumPickerVC

#pragma mark - <System>

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 初始化UI
    [self setupUI];
}

#pragma mark - <Normal>

/**
 初始化UI
 */
- (void)setupUI {
    
    if (![[WGImageManager manager] authorizationStatusAuthorized]) {
        
        return;
    }
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        WGImagePickerConfig *config = [WGImagePickerConfig sharedInstance];
        [[WGImageManager manager] getAlbumWithType:AlbumTypeAll allowPickingVideo:config.allowPickingVideo allowPickingImage:config.allowPickingImage needFetchAssets:NO completion:^(NSArray<WGAlbumModel *> * _Nonnull models) {

            dispatch_async(dispatch_get_main_queue(), ^{

                self->_albumArr = models;

                UITableView *TB = [UITableView new];
                [self.view addSubview:TB];
                TB.backgroundColor = UIColorMakeFromRGB(0xf6f7f9);
                TB.frame = self.view.bounds;
                TB.rowHeight = 110;
                TB.tableFooterView = [UIView new];
                TB.dataSource = self;
                TB.delegate = self;
                TB.contentInset = UIEdgeInsetsMake(15, 0, 0, 0);
                TB.separatorStyle = UITableViewCellSeparatorStyleNone;
            });
        }];
    });
}

#pragma mark - <UITableViewDataSource>

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return _albumArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *const cellID = @"cellID";
    WGAlbumCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        
        cell = [[WGAlbumCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
    }
    cell.model = _albumArr[indexPath.row];  
    
    return cell;
}

#pragma mark - <UITableViewDelegate>

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    if ([self.delegate respondsToSelector:@selector(albumPickerVC:didSelectAlbumWithAlbumModel:)]) {
        
        WGAlbumModel *model = _albumArr[indexPath.row];
        [self.delegate albumPickerVC:self didSelectAlbumWithAlbumModel:model];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

@end
