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
@property (nonatomic) NSDateFormatter *timestampFormatter;
@property (nonatomic) NSMutableArray *logHistory;
@property (nonatomic) TesselBluetoothStatus status;
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
        
        self.timestampFormatter = [[NSDateFormatter alloc] init];
        self.timestampFormatter.timeStyle = NSDateFormatterMediumStyle;
        
        self.status = TesselBluetoothStatusUnknown;
        self.logHistory = [NSMutableArray array];
    }
    return self;
}

- (void)scanAndConnectToTessel
{
    self.status = TesselBluetoothStatusScanning;

    /* Via Apple:
     You can provide an array of CBUUID objects—representing service UUIDs—in the serviceUUIDs parameter. When you do, the central manager returns only peripherals that advertise the services you specify (recommended). If the serviceUUIDs parameter is nil, all discovered peripherals are returned regardless of their supported services (not recommended).
     
     Tessel does not include service UUID's in its advertisement. Thus, we have to scan via the non-recommended way.
     
     */
    
    [self.centralManager scanForPeripheralsWithServices:nil options:nil];
}

- (void)killConnection
{
    [self.centralManager stopScan];
    [self log:@"Stopped whatever scanning was happening"];

    if (self.peripheral) {
        [self.centralManager cancelPeripheralConnection:self.peripheral];
        [self log:@"Cancelled existing peripheral connections"];
    }
    
    self.status = TesselBluetoothStatusDisconnected;
}

- (void)clearLogHistory
{
    self.logHistory = [NSMutableArray array];
}


#pragma mark - <CBCentralManagerDelegate>

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    NSString *state;
    switch (central.state) {
        case CBCentralManagerStatePoweredOff: state = @"CBCentralManagerStatePoweredOff"; break;
        case CBCentralManagerStatePoweredOn: state = @"CBCentralManagerStatePoweredOn"; break;
        case CBCentralManagerStateResetting: state = @"CBCentralManagerStateResetting"; break;
        case CBCentralManagerStateUnauthorized: state = @"CBCentralManagerStateUnauthorized"; break;
        case CBCentralManagerStateUnsupported: state = @"CBCentralManagerStateUnsupported"; break;
        case CBCentralManagerStateUnknown: state = @"CBCentralManagerStateUnknown"; break;
    }
    [self log:[NSString stringWithFormat:@"Central bluetooth manager updated state: %@", state]];
    
    if (central.state == CBCentralManagerStatePoweredOn) {
        [self.delegate didTurnOnBluetooth];
    } else {
        /* Via Apple:
            A state with a value lower than CBCentralManagerStatePoweredOn implies that scanning has stopped and that any connected peripherals have been disconnected
         */
        self.status = TesselBluetoothStatusDisconnected;
    }

}

- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary *)advertisementData
                  RSSI:(NSNumber *)RSSI
{
    
    if ([peripheral.name isEqualToString:@"Tessel BLE113A Module"]) {
        self.peripheral = peripheral;
        self.peripheral.delegate = self;
        [self.centralManager connectPeripheral:peripheral options:nil];
        [self.centralManager stopScan];
        self.status = TesselBluetoothStatusDiscovered;
        [self log:@"Discovered your Tessel"];
    } else {
        [self log:[NSString stringWithFormat:@"Discovered non-Tessel peripheral: %@", peripheral.name]];
    }
}

- (void)centralManager:(CBCentralManager *)central
  didConnectPeripheral:(CBPeripheral *)peripheral {
    CBUUID *dataServiceUUID = [CBUUID UUIDWithString:kTesselDataTransceivingServiceUUID];
    [peripheral discoverServices:@[dataServiceUUID]];
    
    self.status = TesselBluetoothStatusConnected;
    [self log:@"Connected to Tessel. Now attempting to discover services."];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    self.status = TesselBluetoothStatusConnectionFailed;
    [self log:[NSString stringWithFormat:@"Did fail to connect to Tessel with error: %@", error]];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    if (error) {
        [self scanAndConnectToTessel];
        self.status = TesselBluetoothStatusReconnecting;
        [self log:[NSString stringWithFormat:@"Lost connection to Tessel with error (will try to reconnect): %@", error]];
    } else {
        self.status = TesselBluetoothStatusDisconnected;
        [self log:@"Lost connection to Tessel."];
    }
}


#pragma mark - <CBPeripheralDelegate>

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    [self log:[NSString stringWithFormat:@"Discovered services with error: %@", (error ?: @"N/A")]];

    CBService *service = peripheral.services[0];
    CBUUID *tempCharacteristicUUID = [CBUUID UUIDWithString:kTesselTemperatureCharacteristicUUID];
    CBUUID *humidityCharacteristicUUID = [CBUUID UUIDWithString:kTesselHumidityCharacteristicUUID];
    [peripheral discoverCharacteristics:@[tempCharacteristicUUID, humidityCharacteristicUUID]
                             forService:service];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    [self log:[NSString stringWithFormat:@"Discovered characteristics with error: %@", (error ?: @"N/A")]];
    
    for (CBCharacteristic *characteristic in service.characteristics) {
        [self log:[NSString stringWithFormat:@"Subscribed to notifcations for characteristic %@", characteristic.UUID.UUIDString]];
        [peripheral setNotifyValue:YES forCharacteristic:characteristic];
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

#pragma mark - Getters and Setters

- (void)setStatus:(TesselBluetoothStatus)status {
    _status = status;
    [self.delegate didChangeTesselConnectionStatus];
}

#pragma mark - Class Methods
+ (NSString *)descriptionForStatus:(TesselBluetoothStatus)status {
    switch (status) {
        case TesselBluetoothStatusUnknown: return @"Unknown";
        case TesselBluetoothStatusScanning: return @"Scanning";
        case TesselBluetoothStatusDiscovered: return @"Discovered";
        case TesselBluetoothStatusConnected: return @"Connected";
        case TesselBluetoothStatusDisconnected: return @"Disconnected";
        case TesselBluetoothStatusReconnecting: return @"Reconnecting";
        case TesselBluetoothStatusConnectionFailed: return @"Connection Failed";
            
    }
}
#pragma mark - Private

- (void)log:(NSString *)message {
    NSString *timestamp = [self.timestampFormatter stringFromDate:[NSDate date]];
    message = [NSString stringWithFormat:@"%@: %@", timestamp, message];
    [self.logHistory addObject:message];
}

@end
