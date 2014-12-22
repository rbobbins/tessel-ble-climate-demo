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


@interface ViewController () <TesselBluetoothManagerDelegate>
@property (weak, nonatomic) IBOutlet UIButton *scanButton;
@property (weak, nonatomic) IBOutlet UILabel *currentTemperatureLabel;
@property (weak, nonatomic) IBOutlet UILabel *currentHumidityLabel;
@property (weak, nonatomic) IBOutlet UILabel *connectionStatusLabel;
@property (nonatomic) TesselBluetoothManager *bluetoothManager;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CBCentralManager *centralManager = [[CBCentralManager alloc] initWithDelegate:nil queue:nil];
    self.bluetoothManager = [[TesselBluetoothManager alloc] initWithCBCentralManager:centralManager];
    self.bluetoothManager.delegate = self;
    [self didChangeTesselConnectionStatus];
}
- (IBAction)didTapScanButton:(id)sender {
    [self.bluetoothManager scanAndConnectToTessel];
}

#pragma mark - <TesselBluetoothManager>

- (void)didTurnOnBluetooth {
    [self.scanButton setEnabled:YES];
}

- (void)didReceiveUpdatedTemperature:(NSNumber *)number {
    self.currentTemperatureLabel.text = [NSString stringWithFormat:@"%@ F", number];
}

- (void)didReceiveUpdatedHumidity:(NSNumber *)number {
    self.currentHumidityLabel.text = [NSString stringWithFormat:@"%@ Percent RH", number];
}

- (void)didChangeTesselConnectionStatus {
    self.connectionStatusLabel.text = [TesselBluetoothManager descriptionForStatus:self.bluetoothManager.status];
}


@end
