//
//  DeviceViewController.m
//  ObjCStarter
//
//  Created by Stephen Schiffli on 4/27/16.
//  Copyright © 2016 MBIENTLAB, INC. All rights reserved.
//

#import "DeviceViewController.h"

@interface DeviceViewController ()
@property (weak, nonatomic) IBOutlet UILabel *deviceStatus;
@end

@implementation DeviceViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.device addObserver:self forKeyPath:@"state" options:NSKeyValueObservingOptionNew context:nil];
    [self.device connectWithHandler:^(NSError * _Nullable error) {
        NSLog(@"We are connected");
    }];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.device removeObserver:self forKeyPath:@"state"];
    [self.device disconnectWithHandler:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        switch (self.device.state) {
            case MBLConnectionStateConnected:
            self.deviceStatus.text = @"Connected";
            break;
            case MBLConnectionStateDiscovery:
            self.deviceStatus.text = @"Discovery";
            break;
            case MBLConnectionStateConnecting:
            self.deviceStatus.text = @"Connecting";
            break;
            case MBLConnectionStateDisconnected:
            self.deviceStatus.text = @"Disconnected";
            break;
            case MBLConnectionStateDisconnecting:
            self.deviceStatus.text = @"Disconnecting";
            break;
        }
    }];
}

@end
