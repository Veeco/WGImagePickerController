//
//  WGImagePickerBaseVC.m
//  Puchi
//
//  Created by Veeco on 2019/1/16.
//  Copyright © 2019 Chance. All rights reserved.
//

#import "WGImagePickerBaseVC.h"
#import "UtilHeader.h"
#import "Masonry.h"
#import "ColorHeader.h"
#import "WGImagePickerParam.h"
#import "UIView+WGExtension.h"

@interface WGImagePickerBaseVC ()

/** 点击手势 */
@property (nullable, nonatomic, strong) UITapGestureRecognizer *tap;

@end

@implementation WGImagePickerBaseVC

#pragma mark - <Lazy>

- (UITapGestureRecognizer *)tap {
    if (!_tap) {
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTouchBG)];
        _tap = tap;
    }
    return _tap;
}

#pragma mark - <Getter && Setter>

- (void)setClickKBOff:(BOOL)clickKBOff {
    _clickKBOff = clickKBOff;
    
    if (clickKBOff) [self.view addGestureRecognizer:self.tap];
    else [self.view removeGestureRecognizer:self.tap];
}

#pragma mark - <System>

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    [self.view bringSubviewToFront:_holdView];
    [self.view bringSubviewToFront:_navBar];
}

- (void)dealloc {
    
    LOG(@"%@ -> dealloc", self.class)
    
    [NSNotificationCenter.defaultCenter removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    [self.view endEditing:YES];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    
    return UIInterfaceOrientationMaskPortrait;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(keyBoardWillChange:) name:UIKeyboardWillChangeFrameNotification object:nil];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    // 1. 顶部占位
    UIView *holdView = [UIView new];
    if (SCREEN_NEW) {
        
        [self.view addSubview:holdView];
        _holdView = holdView;
        holdView.backgroundColor = UIColor.whiteColor;
        holdView.frame = CGRectMake(0, 0, SCREEN_WIDTH, STATUS_BAR_HEIGHT);
    }
    
    // 2. 导航栏
    UIView *navBar = [UIView new];
    [self.view addSubview:navBar];
    _navBar = navBar;
    navBar.backgroundColor = UIColor.whiteColor;
    navBar.frame = CGRectMake(0, CGRectGetMaxY(holdView.frame), SCREEN_WIDTH, 44);
    WGImagePickerRootVCNavMaxY = CGRectGetMaxY(navBar.frame);
    
    UIView *line = [UIView new];
    [navBar addSubview:line];
    line.backgroundColor = UIColorMakeFromRGB(0xd8d8d8);
    line.width = navBar.width;
    line.height = 0.5f;
    line.y = navBar.height - line.height;
    
    // 3. 左上角
    UILabel *navBack = [UILabel new];
    [navBar addSubview:navBack];
    _navBack = navBack;
    navBack.font = FONT_SIZE(14);
    navBack.textColor = UIColorMakeFromRGB(0x222222);
    navBack.userInteractionEnabled = YES;
    [navBack addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didClickBack)]];
    [navBack mas_makeConstraints:^(MASConstraintMaker *make) {
       
        make.left.mas_equalTo(15);
        make.centerY.mas_equalTo(0);
    }];
    
    // 4. 右上角
    UILabel *navNext = [UILabel new];
    [navBar addSubview:navNext];
    _navNext = navNext;
    navNext.font = BOLD_SIZE(14);
    navNext.textColor = UIColorMakeFromRGB(0x2196f3);
    navNext.userInteractionEnabled = YES;
    [navNext addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didClickNext)]];
    [navNext mas_makeConstraints:^(MASConstraintMaker *make) {
       
        make.right.mas_equalTo(-15);
        make.centerY.mas_equalTo(0);
    }];
}

#pragma mark - <Normal>

/**
 键盘即将变化回调
 专供重写
 
 @param offsetY 变化的偏移量
 */
- (void)keyBoardWillChangeOffsetY:(CGFloat)offsetY {
    
    if (offsetY > 0 && self.view.y == 0) return; // 应对输入法中的语音恶心问题
    
    if (self.upWhenEdit) self.view.y += offsetY / 3;
}

/**
 监听键盘变化
 
 @param noti 通知
 */
- (void)keyBoardWillChange:(NSNotification *)noti {
    
    NSDictionary *userInfo = noti.userInfo;
    CGFloat beginY = [userInfo[UIKeyboardFrameBeginUserInfoKey] CGRectValue].origin.y;
    CGFloat endY = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue].origin.y;
    CGFloat offsetY = endY - beginY;
    NSTimeInterval time = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    [UIView animateWithDuration:time animations:^{
        
        [self keyBoardWillChangeOffsetY:offsetY];
    }];
}

/**
 监听背景点击
 */
- (void)didTouchBG {
    
    [self.view endEditing:YES];
}

/**
 监听右上角点击
 */
- (void)didClickNext {}

/**
 监听左上角点击
 */
- (void)didClickBack {
    
    if (self.navigationController.childViewControllers.count > 1) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

@end
