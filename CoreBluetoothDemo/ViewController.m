//
//  ViewController.m
//  CoreBluetoothDemo
//
//  Created by LiuYiiyuan on 16/8/8.
//  Copyright © 2016年 LiuYiiyuan. All rights reserved.
//

#import "ViewController.h"

NSString * const BLOOD_PRESSURE_MEASUREMENT_UUID = @"2A35";
NSString * const BLOOD_PRESSURE_FEATURE_UUID = @"2A49";
NSString * const DATE_TIME_UUID = @"2A08";

@interface ViewController () <CBCentralManagerDelegate, CBPeripheralDelegate>
@property (strong, nonatomic) CBCentralManager *centralManager;
@property (strong, nonatomic) CBPeripheral *peripheral;
@property (weak, nonatomic) IBOutlet UITextField *deviceNameTextField;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *indicator;
@property (weak, nonatomic) IBOutlet UILabel *scanningLabel;
@property (weak, nonatomic) IBOutlet UITextField *sysTextField;
@property (weak, nonatomic) IBOutlet UITextField *diaTextField;
@property (weak, nonatomic) IBOutlet UITextField *pulTextField;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    //dispatch_queue_t centralQueue = dispatch_queue_create("central", DISPATCH_QUEUE_SERIAL);
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}

- (void)viewWillDisappear:(BOOL)animated{
    [self stopDiscover];
}

- (void)discoverDevices {
    NSLog(@"start scan");
    [self.centralManager scanForPeripheralsWithServices:[NSArray arrayWithObjects:[CBUUID UUIDWithString:@"1810"], nil] options:nil];
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
    [self.centralManager connectPeripheral:peripheral options:nil];
    self.statusLabel.text = @"connecting";
    self.statusLabel.textColor = [UIColor blackColor];
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    if (!peripheral) {
        return;
    }
    NSLog(@"did connect peripheral");
    self.statusLabel.text = @"connected";
    self.statusLabel.textColor = [UIColor greenColor];
    self.deviceNameTextField.text = peripheral.name;
    [self.peripheral discoverServices:nil];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    NSLog(@"fail to connect: %@",error);
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    NSLog(@"disconnect peripheral: %@",peripheral.name);
    self.statusLabel.text = @"disconnected";
    self.statusLabel.textColor = [UIColor redColor];
    self.deviceNameTextField.text = @"";
}

#pragma mark - Peripheral Delegate
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    for (CBService *service in peripheral.services) {
        NSLog(@"discover service: %@", service);
        if ([service.UUID isEqual:[CBUUID UUIDWithString:@"1810"]] ) {
            [peripheral discoverCharacteristics:nil forService:service];
            break;
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    for (CBCharacteristic *character in service.characteristics) {
        if ([character.UUID isEqual:[CBUUID UUIDWithString:BLOOD_PRESSURE_MEASUREMENT_UUID]]) {
            [peripheral setNotifyValue:YES forCharacteristic:character];
        }
        if ([character.UUID isEqual:[CBUUID UUIDWithString:BLOOD_PRESSURE_FEATURE_UUID]]) {
            [peripheral readValueForCharacteristic:character];
        }
        if ([character.UUID isEqual:[CBUUID UUIDWithString:DATE_TIME_UUID]]) {
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
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:BLOOD_PRESSURE_MEASUREMENT_UUID]] && data) {
            const uint8_t *reportData = [data bytes];
            NSInteger sys = reportData[1];
            NSInteger dia = reportData[3];
            NSInteger pul = reportData[7];
            NSLog(@"sys:%ld",(long)sys);
            NSLog(@"dia:%ld",(long)dia);
            NSLog(@"pul:%ld",(long)pul);
            if (sys == 255) {
                self.sysTextField.text = @"error";
                self.diaTextField.text = @"error";
                self.pulTextField.text = @"error";
            }else{
                self.sysTextField.text = [NSString stringWithFormat:@"%ld",sys];
                self.diaTextField.text = [NSString stringWithFormat:@"%ld",dia];
                self.pulTextField.text = [NSString stringWithFormat:@"%ld",pul];
            }
            
        }else{
            NSLog(@"data value: %@ UUID:%@",data, characteristic.UUID);
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    if (error) {
        NSLog(@"%@",[error localizedDescription]);
    }else{
        NSData *data = characteristic.value;
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:BLOOD_PRESSURE_MEASUREMENT_UUID]] && data) {
            const uint8_t *reportData = [data bytes];
            NSInteger sys = reportData[1];
            NSInteger dia = reportData[3];
            NSInteger pul = reportData[7];
            NSLog(@"sys:%ld",(long)sys);
            NSLog(@"dia:%ld",(long)dia);
            NSLog(@"pul:%ld",(long)pul);
            
            self.sysTextField.text = [NSString stringWithFormat:@"%ld",sys];
            self.diaTextField.text = [NSString stringWithFormat:@"%ld",dia];
            self.pulTextField.text = [NSString stringWithFormat:@"%ld",pul];
        }else{
            NSLog(@"data notify: %@ UUID:%@",data, characteristic.UUID);
        }
    }
}

#pragma mark - UI control
- (IBAction)touchScanButton:(UIButton *)sender {
//    NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:CBCentralManagerScanOptionAllowDuplicatesKey];
    [self discoverDevices];
}

- (IBAction)touchStopButton:(UIButton *)sender {
    [self stopDiscover];
}

@end
