//
//  TesselBluetoothManager.h
//  tessel-ble-climate
//
//  Created by Rachel Bobbins on 12/21/14.
//  Copyright (c) 2014 Rachel Bobbins. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@class CBCentralManager;
@class CBPeripheral;

FOUNDATION_EXPORT NSString * const kTesselDataTransceivingServiceUUID;

typedef NS_ENUM(NSUInteger, TesselBluetoothStatus) {
    TesselBluetoothStatusUnknown = 0,
    TesselBluetoothStatusScanning,
    TesselBluetoothStatusDiscovered,
    TesselBluetoothStatusConnected,
    TesselBluetoothStatusDisconnected,
    TesselBluetoothStatusConnectionFailed
};

@protocol TesselBluetoothManagerDelegate <NSObject>
@required
- (void)didTurnOnBluetooth;
- (void)didChangeTesselConnectionStatus;
- (void)didReceiveUpdatedTemperature:(NSNumber *)number;
- (void)didReceiveUpdatedHumidity:(NSNumber *)number;
@end



@interface TesselBluetoothManager : NSObject <CBCentralManagerDelegate>

@property (weak, nonatomic) id<TesselBluetoothManagerDelegate> delegate;
@property (nonatomic, readonly) CBPeripheral *peripheral;
@property (nonatomic, readonly) TesselBluetoothStatus status;

+ (NSString *)descriptionForStatus:(TesselBluetoothStatus)status;

- (instancetype)init __attribute__((unavailable("Use initWithCBCentralManager: instead")));
- (instancetype)initWithCBCentralManager:(CBCentralManager *)cbCentralManager;
- (void)scanAndConnectToTessel;
- (void)killConnection;


@end
