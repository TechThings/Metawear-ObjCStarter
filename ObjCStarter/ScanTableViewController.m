/**
 * ScanTableViewController.m
 * MetaWearApiTest
 *
 * Created by Stephen Schiffli on 7/29/14.
 * Copyright 2014-2015 MbientLab Inc. All rights reserved.
 *
 * IMPORTANT: Your use of this Software is limited to those specific rights
 * granted under the terms of a software license agreement between the user who
 * downloaded the software, his/her employer (which must be your employer) and
 * MbientLab Inc, (the "License").  You may not use this Software unless you
 * agree to abide by the terms of the License which can be found at
 * www.mbientlab.com/terms.  The License limits your use, and you acknowledge,
 * that the Software may be modified, copied, and distributed when used in
 * conjunction with an MbientLab Inc, product.  Other than for the foregoing
 * purpose, you may not use, reproduce, copy, prepare derivative works of,
 * modify, distribute, perform, display or sell this Software and/or its
 * documentation for any purpose.
 *
 * YOU FURTHER ACKNOWLEDGE AND AGREE THAT THE SOFTWARE AND DOCUMENTATION ARE
 * PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESS OR IMPLIED,
 * INCLUDING WITHOUT LIMITATION, ANY WARRANTY OF MERCHANTABILITY, TITLE,
 * NON-INFRINGEMENT AND FITNESS FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL
 * MBIENTLAB OR ITS LICENSORS BE LIABLE OR OBLIGATED UNDER CONTRACT, NEGLIGENCE,
 * STRICT LIABILITY, CONTRIBUTION, BREACH OF WARRANTY, OR OTHER LEGAL EQUITABLE
 * THEORY ANY DIRECT OR INDIRECT DAMAGES OR EXPENSES INCLUDING BUT NOT LIMITED
 * TO ANY INCIDENTAL, SPECIAL, INDIRECT, PUNITIVE OR CONSEQUENTIAL DAMAGES, LOST
 * PROFITS OR LOST DATA, COST OF PROCUREMENT OF SUBSTITUTE GOODS, TECHNOLOGY,
 * SERVICES, OR ANY CLAIMS BY THIRD PARTIES (INCLUDING BUT NOT LIMITED TO ANY
 * DEFENSE THEREOF), OR OTHER SIMILAR COSTS.
 *
 * Should you have any questions regarding your right to use this Software,
 * contact MbientLab via email: hello@mbientlab.com
 */

#import "ScanTableViewController.h"
#import "MBProgressHUD.h"
#import <MetaWear/MetaWear.h>

@interface ScanTableViewController ()
@property (nonatomic) NSArray<MBLMetaWear *> *devices;

@end

@implementation ScanTableViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[MBLMetaWearManager sharedManager] startScanForMetaWearsAllowDuplicates:YES handler:^(NSArray *array) {
        self.devices = array;
        [self.tableView reloadData];
    }];}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [[MBLMetaWearManager sharedManager] stopScanForMetaWears];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.devices.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MetaWearCell" forIndexPath:indexPath];
    MBLMetaWear *cur = self.devices[indexPath.row];
    
    UILabel *uuid = (UILabel *)[cell viewWithTag:1];
    uuid.text = cur.identifier.UUIDString;
    
    UILabel *rssi = (UILabel *)[cell viewWithTag:2];
    rssi.text = [cur.discoveryTimeRSSI stringValue];
    
    UILabel *connected = (UILabel *)[cell viewWithTag:3];
    if (cur.state == CBPeripheralStateConnected) {
        [connected setHidden:NO];
    } else {
        [connected setHidden:YES];
    }
    
    UILabel *name = (UILabel *)[cell viewWithTag:4];
    name.text = cur.name;
    
    UIImageView *signal = (UIImageView *)[cell viewWithTag:5];
    if (cur.averageRSSI) {
        double movingAverage = cur.averageRSSI.doubleValue;
        if (movingAverage < -80.0) {
            signal.image = [UIImage imageNamed:@"wifi_d1"];
        } else if (movingAverage < -70.0) {
            signal.image = [UIImage imageNamed:@"wifi_d2"];
        } else if (movingAverage < -60.0) {
            signal.image = [UIImage imageNamed:@"wifi_d3"];
        } else if (movingAverage < -50.0) {
            signal.image = [UIImage imageNamed:@"wifi_d4"];
        } else if (movingAverage < -40.0) {
            signal.image = [UIImage imageNamed:@"wifi_d5"];
        } else {
            signal.image = [UIImage imageNamed:@"wifi_d6"];
        }
    } else {
        signal.image = [UIImage imageNamed:@"wifi_not_connected"];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    hud.labelText = @"Connecting...";
    
    MBLMetaWear *selected = self.devices[indexPath.row];
    [selected connectWithTimeout:15 handler:^(NSError * _Nullable error) {
        [hud hide:YES];
        if (error) {
            [self showAlertTitle:@"Error" message:error.localizedDescription];
        } else {
            [selected.led flashLEDColorAsync:[UIColor greenColor] withIntensity:1.0];
            
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Confirm Device" message:@"Do you see a blinking green LED on the MetaWear" preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"NO" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                [selected.led setLEDOnAsync:NO withOptions:1];
                [selected disconnectWithHandler:nil];
            }]];
            [alert addAction:[UIAlertAction actionWithTitle:@"YES!" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [selected.led setLEDOnAsync:NO withOptions:1];
                [selected disconnectWithHandler:nil];
                [self.delegate scanTableViewController:self didSelectDevice:selected];
            }]];
            [self presentViewController:alert animated:YES completion:nil];
        }
    }];
}

- (void)showAlertTitle:(NSString *)title message:(NSString *)message
{
    [[[UIAlertView alloc] initWithTitle:title
                                message:message
                               delegate:nil
                      cancelButtonTitle:@"Okay"
                      otherButtonTitles:nil] show];
}

@end
