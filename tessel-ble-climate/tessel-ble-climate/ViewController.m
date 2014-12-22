//
//  ViewController.m
//  tessel-ble-climate
//
//  Created by Rachel Bobbins on 12/20/14.
//  Copyright (c) 2014 Rachel Bobbins. All rights reserved.
//
#import <CoreBluetooth/CoreBluetooth.h>
#import "ViewController.h"
#import "TesselBluetoothManager.h"


@interface ViewController () <TesselBluetoothManagerDelegate, UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UIButton *scanButton;
@property (weak, nonatomic) IBOutlet UIButton *killButton;
@property (weak, nonatomic) IBOutlet UILabel *currentTemperatureLabel;
@property (weak, nonatomic) IBOutlet UILabel *currentHumidityLabel;
@property (weak, nonatomic) IBOutlet UILabel *connectionStatusLabel;
@property (weak, nonatomic) IBOutlet UITableView *logTableView;
@property (nonatomic) TesselBluetoothManager *bluetoothManager;
@property (nonatomic) NSNumberFormatter *numberFormatter;
@property (nonatomic) NSArray *logCache;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CBCentralManager *centralManager = [[CBCentralManager alloc] initWithDelegate:nil queue:nil];
    self.bluetoothManager = [[TesselBluetoothManager alloc] initWithCBCentralManager:centralManager];
    self.bluetoothManager.delegate = self;
    self.numberFormatter = [[NSNumberFormatter alloc] init];
    self.numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    self.numberFormatter.maximumFractionDigits = 2;
    self.numberFormatter.minimumFractionDigits = 2;
    [self didChangeTesselConnectionStatus];
    
}
- (IBAction)didTapScanButton:(id)sender {
    [self.bluetoothManager scanAndConnectToTessel];
}

- (IBAction)didTapKillButton:(id)sender {
    [self.bluetoothManager killConnection];
}
- (IBAction)didTapClearButton:(id)sender {
    [self.bluetoothManager clearLogHistory];
    [self updateTableViewData];
}
- (IBAction)didTapRefreshButton:(id)sender {
    [self updateTableViewData];
}

#pragma mark - <TesselBluetoothManager>

- (void)didTurnOnBluetooth {
    [self.scanButton setEnabled:YES];
}

- (void)didReceiveUpdatedTemperature:(NSNumber *)number {
    NSString *numberString = [self.numberFormatter stringFromNumber:number];
    self.currentTemperatureLabel.text = [NSString stringWithFormat:@"%@ °F", numberString];
}

- (void)didReceiveUpdatedHumidity:(NSNumber *)number {
    NSString *numberString = [self.numberFormatter stringFromNumber:number];
    self.currentHumidityLabel.text = [NSString stringWithFormat:@"%@ %%", numberString];
}

- (void)didChangeTesselConnectionStatus {
    [self updateTableViewData];
    self.currentHumidityLabel.text = @"--";
    self.currentTemperatureLabel.text = @"--";
    
    self.connectionStatusLabel.text = [TesselBluetoothManager descriptionForStatus:self.bluetoothManager.status];
    
    switch (self.bluetoothManager.status) {
        case TesselBluetoothStatusDiscovered:
        case TesselBluetoothStatusScanning:
        case TesselBluetoothStatusConnected:
        {
            self.scanButton.enabled = NO;
            self.killButton.enabled = YES;
            break;
        }
        case TesselBluetoothStatusDisconnected:
        case TesselBluetoothStatusConnectionFailed:
        {
            self.scanButton.enabled = YES;
            self.killButton.enabled = NO;
            break;
        }
        default:
            break;
    }
}

#pragma mark <UITableViewDataSource>

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.logCache.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellIdentifier"]; //Same as in storyboard
    cell.textLabel.text = self.logCache[indexPath.row];
    return cell;
}

#pragma mark - <UITableViewDelegate>

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString *message = self.logCache[indexPath.row];
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Log Event Detail"
                                                                             message:message preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK"
                                                        style:UIAlertActionStyleDefault
                                                      handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - Getters and Setters

- (NSArray *)logCache {
    if (!_logCache) {
        _logCache = self.bluetoothManager.logHistory;
    }
    return _logCache;
}

#pragma mark - Private

- (void)updateTableViewData {
    self.logCache = nil;
    [self.logTableView reloadData];
}


@end
