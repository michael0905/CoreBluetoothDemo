//
//  TemperatureViewController.m
//  CoreBluetoothDemo
//
//  Created by LiuYiiyuan on 16/10/20.
//  Copyright © 2016年 LiuYiiyuan. All rights reserved.
//

#import "TemperatureViewController.h"

NSString * const TEMPERATURE_MEASUREMENT_UUID = @"2A1C";
NSString * const TEMPERATURE_FEATURE_UUID = @"2A1D";
NSString * const DATE_TIME_UUID_ = @"2A08";
NSString * const TEMPERATURE_UUID = @"1809";

@interface TemperatureViewController () <CBPeripheralDelegate, CBCentralManagerDelegate>

@property (strong, nonatomic) CBCentralManager *centralManager;
@property (strong, nonatomic) CBPeripheral *peripheral;

@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UITextField *temperatureTextField;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *indicator;
@property (weak, nonatomic) IBOutlet UILabel *scanningLabel;

@end

@implementation TemperatureViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}

- (void)viewWillDisappear:(BOOL)animated{
    [self stopDiscover];
}

- (void)discoverDevices {
    NSLog(@"start scan");
    [self.centralManager scanForPeripheralsWithServices:[NSArray arrayWithObjects:[CBUUID UUIDWithString:TEMPERATURE_UUID], nil] options:nil];
    
    [self.indicator setHidden:NO];
    [self.indicator startAnimating];
    [self.scanningLabel setHidden:NO];
}

- (void)stopDiscover {
    [self.centralManager stopScan];
    [self.indicator stopAnimating];
    [self.indicator setHidden:YES];
    [self.scanningLabel setHidden:YES];
}

#pragma mark - CBCentralManagerDelegate
- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
    switch (central.state) {
        case CBCentralManagerStateUnknown:
            NSLog(@"CBCentralManagerStateUnknown");
            break;
        case CBCentralManagerStatePoweredOn:
            NSLog(@"CBCentralManagerStatePoweredOn");
            [self discoverDevices];
            break;
        case CBCentralManagerStateResetting:
            NSLog(@"CBCentralManagerStateResetting");
            break;
        case CBCentralManagerStatePoweredOff:
            NSLog(@"CBCentralManagerStatePoweredOff");
            break;
        case CBCentralManagerStateUnsupported:
            NSLog(@"CBCentralManagerStateUnsupported");
            break;
        case CBCentralManagerStateUnauthorized:
            NSLog(@"CBCentralManagerStateUnauthorized");
            break;
        default:
            break;
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI{
    if (!peripheral || !peripheral.name || ([peripheral.name isEqualToString:@""])) {
        return;
    }
    NSLog(@"name:%@",peripheral.name);
    NSLog(@"ad:%@",advertisementData);
    [self stopDiscover];
    self.peripheral = peripheral;
    peripheral.delegate = self;
    [self.centralManager connectPeripheral:self.peripheral options:nil];
    self.statusLabel.text = @"connecting";
    self.statusLabel.textColor = [UIColor blackColor];
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
//    if (!peripheral) {
//        return;
//    }
    NSLog(@"did connect peripheral");
    self.statusLabel.text = @"connected";
    self.statusLabel.textColor = [UIColor greenColor];
    self.nameTextField.text = peripheral.name;
    [self.peripheral discoverServices:nil];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    NSLog(@"fail to connect: %@",error);
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    NSLog(@"disconnect peripheral: %@",peripheral.name);
    self.statusLabel.text = @"disconnected";
    self.statusLabel.textColor = [UIColor redColor];
    self.nameTextField.text = @"";
}

#pragma mark - Peripheral Delegate
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    for (CBService *service in peripheral.services) {
        NSLog(@"discover service: %@", service);
        if ([service.UUID isEqual:[CBUUID UUIDWithString:TEMPERATURE_UUID]] ) {
            [peripheral discoverCharacteristics:nil forService:service];
            break;
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    for (CBCharacteristic *character in service.characteristics) {
        if ([character.UUID isEqual:[CBUUID UUIDWithString:TEMPERATURE_MEASUREMENT_UUID]]) {
            [peripheral setNotifyValue:YES forCharacteristic:character];
        }
        if ([character.UUID isEqual:[CBUUID UUIDWithString:TEMPERATURE_FEATURE_UUID]]) {
            [peripheral readValueForCharacteristic:character];
        }
        if ([character.UUID isEqual:[CBUUID UUIDWithString:DATE_TIME_UUID_]]) {
            [peripheral readValueForCharacteristic:character];
        }
        NSLog(@"discover charcteristic: %@",character);
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    if (error) {
        NSLog(@"%@",[error localizedDescription]);
    }else{
        NSData *data = characteristic.value;
        NSLog(@"data read: %@ UUID:%@",data,characteristic.UUID);
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:TEMPERATURE_MEASUREMENT_UUID]]) {
            const uint8_t *reportData = [data bytes];
            NSInteger temp = reportData[1];
            double temperature = 0.1 * temp + 25.6;
            if (temperature < 32.0 || temperature > 42.0) {
                self.temperatureTextField.text = @"error";
            }else{
                self.temperatureTextField.text = [NSString stringWithFormat:@"%.1f℃",temperature];
            }
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    if (error) {
        NSLog(@"%@",[error localizedDescription]);
    }else{
        NSData *data = characteristic.value;
        NSLog(@"data notify: %@ UUID:%@",data,characteristic.UUID);
    }
}

- (IBAction)touchScanButton:(id)sender {
    [self discoverDevices];
}

- (IBAction)touchStopButton:(id)sender {
    [self stopDiscover];
}

@end
