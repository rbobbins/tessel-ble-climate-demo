//
//  TesselBluetoothManager.m
//  tessel-ble-climate
//
//  Created by Rachel Bobbins on 12/21/14.
//  Copyright (c) 2014 Rachel Bobbins. All rights reserved.
//

#import "TesselBluetoothManager.h"
#import <CoreBluetooth/CoreBluetooth.h>

NSString * const kTesselDataTransceivingServiceUUID = @"D752C5FB-1380-4CD5-B0EF-CAC7D72CFF20"; //Via ble-ble113a gatt profile
NSString * const kTesselTemperatureCharacteristicUUID = @"883F1E6B-76F6-4DA1-87EB-6BDBDB617888";
NSString * const kTesselHumidityCharacteristicUUID =    @"21819AB0-C937-4188-B0DB-B9621E1696CD";

@interface TesselBluetoothManager () <CBCentralManagerDelegate, CBPeripheralDelegate>

@property (nonatomic) CBCentralManager *centralManager;
@property (nonatomic) CBPeripheral *peripheral;
@property (nonatomic) CBCharacteristic *characteristic;
@property (nonatomic) NSNumberFormatter *numberFormatter;
@end


@implementation TesselBluetoothManager

- (instancetype)initWithCBCentralManager:(CBCentralManager *)cbCentralManager
{
    self = [super init];
    if (self) {
        self.centralManager = cbCentralManager;
        self.centralManager.delegate = self;
        self.numberFormatter = [[NSNumberFormatter alloc] init];
        self.numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
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
    CBUUID *dataServiceUUID = [CBUUID UUIDWithString:kTesselDataTransceivingServiceUUID];
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
    [self log:@"Discovered characteristics for service"];
    
    CBUUID *temperatureCharacteristicUUID = [CBUUID UUIDWithString:kTesselTemperatureCharacteristicUUID];
    CBUUID *humidityCharacteristicUUID = [CBUUID UUIDWithString:kTesselHumidityCharacteristicUUID];
    
    for (CBCharacteristic *characteristic in service.characteristics) {
        if ([characteristic.UUID.UUIDString isEqualToString:temperatureCharacteristicUUID.UUIDString] ||
            [characteristic.UUID.UUIDString isEqualToString:humidityCharacteristicUUID.UUIDString]) {
            [self log:@"Subscribed to notifcations for temperature"];
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSString *str = [[NSString alloc] initWithData:characteristic.value
                                          encoding:NSUTF8StringEncoding];
    
    NSNumber *dataValue = [self.numberFormatter numberFromString:str];

    NSString *logMessage;
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:kTesselTemperatureCharacteristicUUID]]) {
        [self.delegate didReceiveUpdatedTemperature:dataValue];
         logMessage = [NSString stringWithFormat:@"Received updated temperature from Tessel: %@", dataValue];
    } else {
        [self.delegate didReceiveUpdatedHumidity:dataValue];
        logMessage = [NSString stringWithFormat:@"Received updated humidity from Tessel: %@", dataValue];
    }
    
    [self log:logMessage];

}

#pragma mark - Private
- (void)log:(NSString *)message {
    NSLog(message);
}

@end
