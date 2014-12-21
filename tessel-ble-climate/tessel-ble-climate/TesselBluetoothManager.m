//
//  TesselBluetoothManager.m
//  tessel-ble-climate
//
//  Created by Rachel Bobbins on 12/21/14.
//  Copyright (c) 2014 Rachel Bobbins. All rights reserved.
//

#import "TesselBluetoothManager.h"
#import <CoreBluetooth/CoreBluetooth.h>

static NSString *kTesselBLEAdvertisingServiceUUID = @"D752C5FB-1380-4CD5-B0EF-CAC7D72CFF20"; //Via ble-ble113a gatt profile
static NSString *kTesselCharacteristicUUID = @"883F1E6B-76F6-4DA1-87EB-6BDBDB617888"; //TODO: is this the same for all Tessels?

@interface TesselBluetoothManager () <CBCentralManagerDelegate, CBPeripheralDelegate>

@property (nonatomic) CBCentralManager *centralManager;
@property (nonatomic) CBPeripheral *peripheral;
@property (nonatomic) CBCharacteristic *characteristic;
@end


@implementation TesselBluetoothManager

- (instancetype)initWithCBCentralManager:(CBCentralManager *)cbCentralManager
{
    self = [super init];
    if (self) {
        self.centralManager = cbCentralManager;
        self.centralManager.delegate = self;
    }
    return self;
}
- (void)scanAndConnectToTessel {

    [self.centralManager scanForPeripheralsWithServices:nil options:nil];
}


#pragma mark - <CBCentralManagerDelegate>

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    if (central.state == CBCentralManagerStatePoweredOn) {
        NSLog(@"================> %@", @"Powered on");
        [self.delegate didTurnOnBluetooth];
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
        [self.centralManager stopScan];
        NSLog(@"================> %@", @"Discovered your Tessel");
    } else {
        NSLog(@"================> Discovered non-Tessel peripheral: %@", peripheral.name);
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"================> %@", @"Connected to Tessel    ");
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
    
    CBUUID *characteristicUUID = [CBUUID UUIDWithString:kTesselCharacteristicUUID];
    for (CBCharacteristic *characteristic in service.characteristics) {
        if ([characteristic.UUID.UUIDString isEqualToString:characteristicUUID.UUIDString]) {
            NSLog(@"================> %@", @"Subscribed to notifcations for characteristic");
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            return;
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSString *str = [[NSString alloc] initWithData:characteristic.value
                                          encoding:NSUTF8StringEncoding];
    
    NSLog(@"================> Received data: %@", str);
}
@end
