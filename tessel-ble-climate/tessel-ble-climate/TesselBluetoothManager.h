//
//  TesselBluetoothManager.h
//  tessel-ble-climate
//
//  Created by Rachel Bobbins on 12/21/14.
//  Copyright (c) 2014 Rachel Bobbins. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CBCentralManager;
@class CBPeripheral;
@protocol CBCentralManagerDelegate;


@protocol TesselBluetoothManagerDelegate <NSObject>
@required
- (void)didTurnOnBluetooth;

@end

@interface TesselBluetoothManager : NSObject <CBCentralManagerDelegate>

@property (weak, nonatomic) id<TesselBluetoothManagerDelegate> delegate;
@property (nonatomic, readonly) CBPeripheral *peripheral;


- (instancetype)init __attribute__((unavailable("Use initWithCBCentralManager: instead")));
- (instancetype)initWithCBCentralManager:(CBCentralManager *)cbCentralManager;
- (void)scanAndConnectToTessel;

@end
