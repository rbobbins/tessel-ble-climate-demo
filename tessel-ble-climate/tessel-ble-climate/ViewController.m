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
@property (weak, nonatomic) IBOutlet UIButton *killButton;
@property (weak, nonatomic) IBOutlet UILabel *currentTemperatureLabel;
@property (weak, nonatomic) IBOutlet UILabel *currentHumidityLabel;
@property (weak, nonatomic) IBOutlet UILabel *connectionStatusLabel;
@property (nonatomic) TesselBluetoothManager *bluetoothManager;
@property (nonatomic) NSNumberFormatter *numberFormatter;
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
    self.currentHumidityLabel.text = @"--";
    self.currentTemperatureLabel.text = @"--";
    
    NSString *status = [TesselBluetoothManager descriptionForStatus:self.bluetoothManager.status];
    self.connectionStatusLabel.text = [NSString stringWithFormat:@"Current Status: %@", status];
    
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


@end
