//
//  TesselBluetoothManager.h
//  tessel-ble-climate
//
//  Created by Rachel Bobbins on 12/21/14.
//  Copyright (c) 2014 Rachel Bobbins. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TesselBluetoothManagerDelegate <NSObject>
@required
- (void)didTurnOnBluetooth;

@end

@interface TesselBluetoothManager : NSObject

@property (weak, nonatomic) id<TesselBluetoothManagerDelegate> delegate;

- (void)scanAndConnectToTessel;

@end
