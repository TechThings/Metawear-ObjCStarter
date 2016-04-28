//
//  MainTableViewController.m
//  ObjCStarter
//
//  Created by Stephen Schiffli on 4/27/16.
//  Copyright © 2016 MBIENTLAB, INC. All rights reserved.
//

#import "MainTableViewController.h"
#import "ScanTableViewController.h"
#import "DeviceViewController.h"
#import <MetaWear/MetaWear.h>

@interface MainTableViewController () <ScanTableViewControllerDelegate>
@property (nonatomic) NSMutableArray<MBLMetaWear *> *devices;
@end

@implementation MainTableViewController


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[[MBLMetaWearManager sharedManager] retrieveSavedMetaWearsAsync] success:^(NSArray<MBLMetaWear *> * _Nonnull array) {
        self.devices = [array mutableCopy];
        [self.tableView reloadData];
    }];
}

#pragma mark - Scan table view delegate

- (void)scanTableViewController:(ScanTableViewController *)controller didSelectDevice:(MBLMetaWear *)device
{
    [device rememberDevice];
    // TODO: You may want to assign a device configuration object here
    //[device setConfiguration:... handler:...]
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return MAX(self.devices.count, 1);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    if (self.devices.count) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"MetaWearCell" forIndexPath:indexPath];
        MBLMetaWear *cur = self.devices[indexPath.row];
        
        UILabel *name = (UILabel *)[cell viewWithTag:1];
        name.text = cur.name;
        
        UILabel *uuid = (UILabel *)[cell viewWithTag:2];
        uuid.text = cur.identifier.UUIDString;
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"NoDeviceCell" forIndexPath:indexPath];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (self.devices.count) {
        MBLMetaWear *cur = self.devices[indexPath.row];
        [self performSegueWithIdentifier:@"ViewDevice" sender:cur];
    } else {
        [self performSegueWithIdentifier:@"AddNewDevice" sender:nil];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    return self.devices.count != 0;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        MBLMetaWear *cur = self.devices[indexPath.row];
        [cur forgetDevice];
        [self.devices removeObjectAtIndex:indexPath.row];
        
        if (self.devices.count) {
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        } else {
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.destinationViewController isKindOfClass:[ScanTableViewController class]]) {
        ScanTableViewController *scanController = segue.destinationViewController;
        scanController.delegate = self;
    } else if ([segue.destinationViewController isKindOfClass:[DeviceViewController class]]) {
        DeviceViewController *deviceController = segue.destinationViewController;
        deviceController.device = sender;
    }
}

@end
