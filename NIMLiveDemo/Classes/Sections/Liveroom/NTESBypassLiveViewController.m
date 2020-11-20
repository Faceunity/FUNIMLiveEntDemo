//
//  NTESBypassLiveViewController.m
//  NIMLiveDemo
//
//  Created by Simon Blue on 2019/10/25.
//  Copyright © 2019 Netease. All rights reserved.
//

#import "NTESBypassLiveViewController.h"

@interface NTESBypassLiveViewController ()

@end

@implementation NTESBypassLiveViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}


- (UITraitCollection *)traitCollection
{
    if (@available(iOS 13, *)) {
        UITraitCollection *traitCollection = [super traitCollection];
        if (!traitCollection) {
            return [[UITraitCollection alloc] init];
        }
    }
    return [super traitCollection];
}

@end
