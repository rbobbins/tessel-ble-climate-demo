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

static NSString *kTesselBLEAdvertisingServiceUUID = @"D752C5FB-1380-4CD5-B0EF-CAC7D72CFF20"; //Via ble-ble113a gatt profile

@interface ViewController () <TesselBluetoothManagerDelegate>
@property (weak, nonatomic) IBOutlet UIButton *scanButton;
@property (nonatomic) TesselBluetoothManager *bluetoothManager;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CBCentralManager *centralManager = [[CBCentralManager alloc] initWithDelegate:nil queue:nil];
    self.bluetoothManager = [[TesselBluetoothManager alloc] initWithCBCentralManager:centralManager];
    self.bluetoothManager.delegate = self;
}
- (IBAction)didTapScanButton:(id)sender {
    [self.bluetoothManager scanAndConnectToTessel];
//    [self.centralManager scanForPeripheralsWithServices:nil options:nil];
}

#pragma mark - <TesselBluetoothManager>

- (void)didTurnOnBluetooth {
    [self.scanButton setEnabled:YES];
}


@end
