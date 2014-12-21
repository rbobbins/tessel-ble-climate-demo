//
//  ViewController.m
//  tessel-ble-climate
//
//  Created by Rachel Bobbins on 12/20/14.
//  Copyright (c) 2014 Rachel Bobbins. All rights reserved.
//
#import <CoreBluetooth/CoreBluetooth.h>
#import "ViewController.h"

static NSString *kTesselBLEAdvertisingServiceUUID = @"D752C5FB-1380-4CD5-B0EF-CAC7D72CFF20"; //Via ble-ble113a gatt profile

@interface ViewController () <CBCentralManagerDelegate, CBPeripheralDelegate>
@property (weak, nonatomic) IBOutlet UIButton *scanButton;
@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) CBPeripheral *peripheral;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    
}
- (IBAction)didTapScanButton:(id)sender {
    [self.centralManager scanForPeripheralsWithServices:nil options:nil];
}

#pragma mark - <CBCentralManagerDelegate>

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    if (central.state == CBCentralManagerStatePoweredOn) {
        self.scanButton.enabled = YES;
        NSLog(@"================> %@", @"Powered on");
    }
}

- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary *)advertisementData
                  RSSI:(NSNumber *)RSSI {
    
    if ([peripheral.name isEqualToString:@"Tessel BLE113A Module"]) {
        self.peripheral = peripheral;
        self.peripheral.delegate = self;
        [self.centralManager connectPeripheral:peripheral options:nil];
        NSLog(@"================> %@", @"Found yo tessel");
    } else {
        NSLog(@"================> %@ vs %@", peripheral.name, @"Tessel BLE113A Module");
    }
    NSLog(@"================> Discovered peripheral: %@", peripheral.name);
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"================> %@", @"Connected peripheral");
    CBUUID *dataServiceUUID = [CBUUID UUIDWithString:kTesselBLEAdvertisingServiceUUID];
    [peripheral discoverServices:@[dataServiceUUID]];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"================> %@", error);
}

#pragma mark - <CBPeripheralDelegate>

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    NSLog(@"================> Discovered service(s): %@", peripheral.services);
    
    for (CBService *service in peripheral.services) {
        [peripheral discoverCharacteristics:nil forService:service];
    }

}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    NSLog(@"================> %@", @"Discovered characteristics for service");
    
    CBUUID *characteristicUUID = [CBUUID UUIDWithString:@"883F1E6B-76F6-4DA1-87EB-6BDBDB617888"];
    for (CBCharacteristic *characteristic in service.characteristics) {
        if ([characteristic.UUID.UUIDString isEqualToString:characteristicUUID.UUIDString]) {
            NSString *str = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
            NSLog(@"================> %@", str);
        }
    }
}

@end
