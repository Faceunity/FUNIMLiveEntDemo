//
//  NTESLiveroomSelectViewController.m
//  NIMLiveDemo
//
//  Created by chris on 16/3/9.
//  Copyright © 2016年 Netease. All rights reserved.
//

#import "NTESLiveRoomSelectViewController.h"
#import "NTESCommonTableDelegate.h"
#import "NTESCommonTableData.h"
#import "SVProgressHUD.h"
#import "UIView+Toast.h"
#import "NTESAudienceLiveViewController.h"
#import "NTESLiveManager.h"
#import "NSString+NTES.h"
#import "NSDictionary+NTESJson.h"
#import "NTESDemoService.h"
#import "NTESUserUtil.h"
#import "NTESLiveUtil.h"

@interface NTESLiveRoomSelectViewController ()

@property (nonatomic,strong) NTESCommonTableDelegate *delegator;

@property (nonatomic,copy  ) NSArray                 *data;

@property (nonatomic,assign) NSInteger               inputLimit;

@property (nonatomic,copy  ) NSString                *roomId;

@property (nonatomic) BOOL  disableClick;

@end

@implementation NTESLiveRoomSelectViewController


- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _inputLimit = 13;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setUpNav];
    __weak typeof(self) wself = self;
    [self buildData];
    self.delegator = [[NTESCommonTableDelegate alloc] initWithTableData:^NSArray *{
        return wself.data;
    }];
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.tableView];
    self.tableView.backgroundColor = UIColorFromRGB(0xe3e6ea);
    self.tableView.separatorStyle  = UITableViewCellSeparatorStyleNone;
    self.tableView.delegate   = self.delegator;
    self.tableView.dataSource = self.delegator;
    [self.tableView reloadData];
    
    for (UITableViewCell *cell in self.tableView.visibleCells) {
        for (UIView *subView in cell.subviews) {
            if ([subView isKindOfClass:[UITextField class]]) {
                [subView becomeFirstResponder];
                break;
            }
        }
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onTextFieldChanged:) name:UITextFieldTextDidChangeNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [SVProgressHUD dismiss];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.titleTextAttributes =@{
                                                                   NSForegroundColorAttributeName:[UIColor blackColor]};
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setUpNav{
    self.navigationItem.title = @"娱乐直播";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"完成" style:UIBarButtonItemStyleDone target:self action:@selector(onDone:)];
    self.navigationItem.rightBarButtonItem.tintColor = [UIColor blackColor];
    [self.navigationController.navigationBar setTintColor:[UIColor lightGrayColor]];
}

- (void)onDone:(id)sender{
    [self.view endEditing:YES];
    if (!self.roomId.length) {
        [self.view makeToast:@"直播间ID不能为空" duration:2.0 position:CSToastPositionCenter];
        return;
    }
    if (self.roomId.length > self.inputLimit) {
        [self.view makeToast:@"直播间ID过长" duration:2.0 position:CSToastPositionCenter];
        return;
    }
    [[NSUserDefaults standardUserDefaults] setObject:self.roomId forKey:@"cachedRoom"];
    
    
    if (_disableClick) {
        return;
    }
    self.disableClick = YES;
    [self requestPlayStream];
    
}

- (void)requestPlayStream
{
    __weak typeof(self) wself = self;
    [SVProgressHUD show];
    [[NTESDemoService sharedService] requestPlayStream:_roomId completion:^(NSError *error, NSString *playStreamUrl,NTESLiveType liveType,NIMVideoOrientation orientation) {
        [SVProgressHUD dismiss];
        self.disableClick = NO;
        if (!error) {
            DDLogDebug(@"request play stream complete: %@, live type : %@",playStreamUrl,[NTESLiveUtil liveTypeToString:liveType]);
            [NTESLiveManager sharedInstance].orientation = orientation;
            [NTESLiveManager sharedInstance].type = liveType;
            [NTESLiveManager sharedInstance].role = NTESLiveRoleAudience;

            NTESAudienceLiveViewController *vc = [[NTESAudienceLiveViewController alloc] initWithChatroomId:self.roomId streamUrl:playStreamUrl];
            UINavigationController *nav = self.navigationController;
            [nav presentViewController:vc animated:YES completion:^{
                NSMutableArray *vcs = [nav.viewControllers mutableCopy];
                [vcs removeObject:self];
                nav.viewControllers = vcs;
            }];
        }
        
        else
        {
            DDLogDebug(@"start play stream error: %zd.",error.code);
            [wself.view makeToast:@"进入直播失败" duration:2.0 position:CSToastPositionCenter];
        }
    }];

}

- (void)buildData{
    self.roomId = [[NSUserDefaults standardUserDefaults] objectForKey:@"cachedRoom"];
    NSArray *data = @[
                      @{
                          HeaderTitle:@"请输入直播间ID号",
                          RowContent :@[
                                  @{
                                      ExtraInfo     : self.roomId.length? self.roomId : @"",
                                      CellClass     : @"NTESTextSettingCell",
                                      RowHeight     : @(50),
                                      },
                                  ],
                          FooterTitle:@""
                          },
                      ];
    self.data = [NTESCommonTableSection sectionsWithData:data];
}


#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    if ([string isEqualToString:@"\n"]) {
        [self onDone:nil];
    }
    // 如果是删除键
    if ([string length] == 0 && range.length > 0)
    {
        return YES;
    }
    NSString *genString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    if (self.inputLimit && genString.length > self.inputLimit) {
        return NO;
    }
    return YES;
}


- (void)onTextFieldChanged:(NSNotification *)notification{
    UITextField *textField = notification.object;
    self.roomId = textField.text;
}

#pragma mark - 旋转处理 (iOS7)
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self.tableView reloadData];
}


@end
