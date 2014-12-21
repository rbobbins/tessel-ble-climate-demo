#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "TesselBluetoothManager.h"
#import "OCMock.h"


@interface TesselBluetoothManagerTests : XCTestCase
@property (nonatomic) TesselBluetoothManager *subject;
@property (nonatomic) id centralManager;
@end

@implementation TesselBluetoothManagerTests

- (void)setUp {
    [super setUp];
    
    self.centralManager = OCMClassMock([CBCentralManager class]);
    self.subject = [[TesselBluetoothManager alloc] initWithCBCentralManager:self.centralManager];
}

- (void)tearDown {
    [super tearDown];
}

#pragma mark - Configuration

- (void)testItShouldAssignItselfAsTheCBCentralManagersDelegate {
    OCMVerify([self.centralManager setDelegate:self.subject]);
}

#pragma mark - Scanning for Tessel

- (void)testItShouldScanForTesselBLEWhenToldTo {
    [self.subject scanAndConnectToTessel];
    
    OCMVerify([self.centralManager scanForPeripheralsWithServices:nil options:nil]);
}

#pragma mark - Responding to CBCentral events
#pragma mark Discovering the Tessel

- (void)simulateDiscoveringPeripheral:(CBPeripheral *)peripheral {
    [self.subject centralManager:self.centralManager
           didDiscoverPeripheral:peripheral
               advertisementData:@{}
                            RSSI:@0];
}

- (void)testAfterFindingPeripheralItShouldConnectIfPeripheralIsTessel {
    CBPeripheral *peripheral = OCMClassMock([CBPeripheral class]);
    OCMStub([peripheral name]).andReturn(@"Tessel BLE113A Module");
    OCMExpect([self.centralManager connectPeripheral:peripheral options:nil]);
    OCMExpect([self.centralManager stopScan]);
    
    [self simulateDiscoveringPeripheral:peripheral];
}

- (void)testAfterFindingPeripheralItShouldRetainReferenceIfPeripheralIsTessel {
    CBPeripheral *peripheral = OCMClassMock([CBPeripheral class]);
    OCMStub([peripheral name]).andReturn(@"Tessel BLE113A Module");
    
    [self simulateDiscoveringPeripheral:peripheral];
    XCTAssertEqual(peripheral, self.subject.peripheral);
}


- (void)testAfterFindingPeripheralItShouldNotConnectIfPeripheralIsntTessel {
    CBPeripheral *peripheral = OCMClassMock([CBPeripheral class]);
    OCMStub([peripheral name]).andReturn(@"NOT!!! Tessel BLE113A Module");
    
    //Test will fail if connectPeripheral:options is called
    [[self.centralManager reject] connectPeripheral:peripheral options:nil];
    
    [self simulateDiscoveringPeripheral:peripheral];
    
}

@end
