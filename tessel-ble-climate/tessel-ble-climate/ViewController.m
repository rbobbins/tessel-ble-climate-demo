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


@interface ViewController () <TesselBluetoothManagerDelegate, UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UIButton *scanButton;
@property (weak, nonatomic) IBOutlet UIButton *killButton;

@property (weak, nonatomic) IBOutlet UILabel *currentTemperatureLabel;
@property (weak, nonatomic) IBOutlet UILabel *currentHumidityLabel;
@property (weak, nonatomic) IBOutlet UILabel *connectionStatusLabel;
@property (weak, nonatomic) IBOutlet UITableView *logTableView;
@property (nonatomic) TesselBluetoothManager *bluetoothManager;
@property (nonatomic) NSNumberFormatter *numberFormatter;
@property (nonatomic) NSTimer *connectionTimer;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CBCentralManager *centralManager = [[CBCentralManager alloc] initWithDelegate:nil queue:nil];
    self.bluetoothManager = [[TesselBluetoothManager alloc] initWithCBCentralManager:centralManager];
    self.bluetoothManager.delegate = self;
    [self didChangeTesselConnectionStatus];
}

#pragma mark - Actions

- (IBAction)didTapScanButton:(id)sender {
    [self.bluetoothManager scanAndConnectToTessel];
}

- (IBAction)didTapKillButton:(id)sender {
    [self.bluetoothManager killConnection];
}

- (IBAction)didTapClearButton:(id)sender {
    [self.bluetoothManager clearLogHistory];
    [self.logTableView reloadData];
}

#pragma mark - <TesselBluetoothManager>

- (void)didTurnOnBluetooth {
    //Don't allow user to monitor Tessel unless iDevice bluetooth is enabled
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

- (void)didLogEvent {
    [self.logTableView reloadData];
}

- (void)didChangeTesselConnectionStatus {
    [self.connectionTimer invalidate];
    
    // Respond to any change in connection status by resetting labels and updating logs
    self.currentHumidityLabel.text = @"--";
    self.currentTemperatureLabel.text = @"--";
    
    self.connectionStatusLabel.text = [TesselBluetoothManager descriptionForStatus:self.bluetoothManager.status];
    
    switch (self.bluetoothManager.status) {
        case TesselBluetoothStatusDiscovered:
        case TesselBluetoothStatusScanning:
        case TesselBluetoothStatusConnected:
        case TesselBluetoothStatusReconnecting:
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
        case TesselBluetoothStatusUnknown: break;
    }
    
    if (self.bluetoothManager.status == TesselBluetoothStatusReconnecting ||
        self.bluetoothManager.status == TesselBluetoothStatusScanning) {
        self.connectionTimer = [NSTimer timerWithTimeInterval:5
                                                       target:self
                                                     selector:@selector(askToKeepScanning:)
                                                     userInfo:nil
                                                      repeats:NO];
        [[NSRunLoop mainRunLoop] addTimer:self.connectionTimer forMode:NSDefaultRunLoopMode];
    }

    
}

#pragma mark <UITableViewDataSource>

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.bluetoothManager.logHistory.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellIdentifier = @"cellIdentifier"; //Same as the one defined in storyboard
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    cell.textLabel.text = self.bluetoothManager.logHistory[indexPath.row];
    return cell;
}

#pragma mark - <UITableViewDelegate>

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString *message = self.bluetoothManager.logHistory[indexPath.row];
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Log Event Detail"
                                                                             message:message preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK"
                                                        style:UIAlertActionStyleDefault
                                                      handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - Getters and Setters

- (NSNumberFormatter *)numberFormatter {
    if (!_numberFormatter) {
        _numberFormatter = [[NSNumberFormatter alloc] init];
        _numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
        _numberFormatter.maximumFractionDigits = 2;
        _numberFormatter.minimumFractionDigits = 2;
    }
    return _numberFormatter;
}

#pragma mark - Private

- (void)askToKeepScanning:(NSTimer *)timer {
    UIAlertController *controller = [UIAlertController alertControllerWithTitle:@"Keep Scanning?"
                                         message:@"You've been scanning for your Tessel for 5 seconds. Would you like to keep searching?"
                                                                 preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *continueAction = [UIAlertAction actionWithTitle:@"Yes, continue scanning"
                                                             style:UIAlertActionStyleDefault
                                                           handler:nil];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"No, stop scanning"
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction *action) {
                                                               [self.bluetoothManager killConnection];
                                                           }];
    [controller addAction:continueAction];
    [controller addAction:cancelAction];
    [self presentViewController:controller
                       animated:YES
                     completion:nil];
}


@end
