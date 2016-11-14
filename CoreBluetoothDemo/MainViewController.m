//
//  MainViewController.m
//  CoreBluetoothDemo
//
//  Created by LiuYiiyuan on 16/10/20.
//  Copyright © 2016年 LiuYiiyuan. All rights reserved.
//

#import "MainViewController.h"

@interface MainViewController ()

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)touchBpButton:(id)sender {
    [self performSegueWithIdentifier:@"ToBloodPressure" sender:self];
}

- (IBAction)touchTemperatureButton:(id)sender {
    [self performSegueWithIdentifier:@"ToTemperature" sender:self];
}

@end
