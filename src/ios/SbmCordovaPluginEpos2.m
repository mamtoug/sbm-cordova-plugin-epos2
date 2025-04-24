#import "SbmCordovaPluginEpos2.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import <CoreImage/CoreImage.h>

@interface SbmCordovaPluginEpos2 () <Epos2DiscoveryDelegate>
// Private properties
@property (nonatomic) int textSizeWidth;
@property (nonatomic) int textSizeHeight;
@property (nonatomic) int qrCodeWidth;
@property (nonatomic) int qrCodeHeight;
@property (nonatomic) int alignText;
@property (nonatomic) int addFeedLine;
@property (nonatomic) int reverse;
@property (nonatomic) int ul;
@property (nonatomic) int em;
@property (nonatomic) int color;
@property (nonatomic) int lang;
@property (nonatomic) int printerSeries;
@property (nonatomic, strong) NSString *printerTarget;
@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) NSString *error;
@property (nonatomic, strong) NSString *method;
@property (nonatomic, strong) NSString *data;
@end

@implementation SbmCordovaPluginEpos2

- (void)pluginInitialize {
    // Initialize properties with default values (similar to Java constructor)
    self.lang = 0;
    self.method = @"";
    self.data = @"";
    self.alignText = 1;
    self.addFeedLine = 1;
    self.textSizeWidth = 1;
    self.textSizeHeight = 1;
    self.qrCodeWidth = 300;
    self.qrCodeHeight = 300;
    self.reverse = -2;
    self.ul = -2;
    self.em = 1;
    self.color = -2;
    self.printerTarget = @"";
    self.printerSeries = -1;
    self.printerList = [NSMutableArray array];
}

// Convert JSON array to NSArray
- (NSArray*)parseJSONArray:(NSString*)jsonArrayString {
    NSData *jsonData = [jsonArrayString dataUsingEncoding:NSUTF8StringEncoding];
    NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
    return jsonArray;
}

#pragma mark - Plugin Methods

- (void)coolMethod:(CDVInvokedUrlCommand*)command {
    NSString* message = [command.arguments objectAtIndex:0];
    CDVPluginResult* pluginResult = nil;

    if (message != nil && [message length] > 0) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:message];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Expected one non-empty string argument."];
    }

    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)printText:(CDVInvokedUrlCommand*)command {
    [self.commandDelegate runInBackground:^{
        if (command.arguments.count > 0) {
            NSDictionary *argsObject = [command.arguments objectAtIndex:0];

            // Get printer data
            if (![argsObject objectForKey:@"printer"]) {
                CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                                messageAsString:@"Printer data required"];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                return;
            }

            NSDictionary *printerData = [argsObject objectForKey:@"printer"];

            if (![printerData objectForKey:@"printerSeries"] || ![printerData objectForKey:@"printerTarget"]) {
                CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                                messageAsString:@"Printer data required"];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                return;
            }

            self.printerTarget = [printerData objectForKey:@"printerTarget"];
            self.printerSeries = [[printerData objectForKey:@"printerSeries"] intValue];

            if ([printerData objectForKey:@"lang"]) {
                self.lang = [[printerData objectForKey:@"lang"] intValue];
            }

            NSArray *values = [argsObject objectForKey:@"data"];
            self.currentCallbackCommand = command;

            [self runPrintSequence:values];
        }
    }];
}

- (void)discoverPrinters:(CDVInvokedUrlCommand*)command {
    [self.commandDelegate runInBackground:^{
        // Check Bluetooth status using CoreBluetooth
        CBCentralManager *bluetoothManager = [[CBCentralManager alloc] initWithDelegate:nil queue:nil];

        if (bluetoothManager.state != CBManagerStatePoweredOn) {
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                            messageAsString:@"Bluetooth is not enabled"];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            return;
        }

        // Clear existing printers list
        self.printerList = [NSMutableArray array];

        // Start discovery
        self.filterOption = [[Epos2FilterOption alloc] init];
        [self.filterOption setDeviceType:EPOS2_TYPE_ALL];
        [self.filterOption setEpsonFilter:EPOS2_FILTER_NAME];

        NSError *error = nil;
        [Epos2Discovery start:self.filterOption delegate:self error:&error];

        if (error != nil) {
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                            messageAsString:@"Error on start discover"];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            return;
        }

        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                        messageAsString:@"success"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (void)onDiscovery:(Epos2DeviceInfo *)deviceInfo {
    // Called when a printer is discovered
    NSMutableDictionary *item = [NSMutableDictionary dictionary];
    [item setObject:deviceInfo.deviceName forKey:@"PrinterName"];
    [item setObject:deviceInfo.target forKey:@"Target"];

    [self.printerList addObject:item];
}

- (void)getPrintersList:(CDVInvokedUrlCommand*)command {
    [self.commandDelegate runInBackground:^{
        NSError *error = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self.printerList
                                                          options:0
                                                            error:&error];

        if (error != nil) {
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                            messageAsString:@"Error serializing printer list"];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            return;
        }

        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:jsonString];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (void)stopDiscoverPrinters:(CDVInvokedUrlCommand*)command {
    [self.commandDelegate runInBackground:^{
        NSError *error = nil;
        [Epos2Discovery stop:&error];

        if (error != nil) {
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                            messageAsString:@"Error on stop discover"];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            return;
        }

        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                        messageAsString:@"success"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

#pragma mark - Printer Operations

- (BOOL)initializePrinter:(int)printerSeries lang:(int)lang target:(NSString*)printerTarget {
    NSError *error = nil;

    self.printer = [[Epos2Printer alloc] initWithPrinterSeries:printerSeries lang:lang];
    if (self.printer == nil) {
        self.error = @"Printer is null";
        return NO;
    }

    Epos2PrinterStatusInfo *status = [self.printer getStatus:&error];
    if (error != nil) {
        self.error = @"Get status error";
        return NO;
    }

    if ([status getPaper] == EPOS2_PAPER_NEAR_END) {
        self.error = @"PAPER_NEAR_END";
        return NO;
    }

    if ([status getBatteryLevel] == EPOS2_BATTERY_LEVEL_1) {
        self.error = @"BATTERY_LEVEL_1";
        return NO;
    }

    // Connect to printer
    [self.printer connect:printerTarget timeout:EPOS2_PARAM_DEFAULT];
    if (error != nil) {
        self.error = [NSString stringWithFormat:@"Error connection %d %d %@",
                     printerSeries, lang, printerTarget];
        return NO;
    }

    [self.printer clearCommandBuffer];

    [self.printer beginTransaction:&error];
    if (error != nil) {
        self.error = @"beginTransaction error";
        return NO;
    }

    return YES;
}

- (UIImage*)encodeAsQRCode:(NSString*)str width:(int)width height:(int)height {
    CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    [filter setDefaults];

    NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
    [filter setValue:data forKey:@"inputMessage"];
    [filter setValue:@"H" forKey:@"inputCorrectionLevel"]; // High error correction

    CIImage *outputImage = [filter outputImage];

    // Scale the image
    CGRect extent = CGRectIntegral(outputImage.extent);
    CGFloat scale = MIN(width/CGRectGetWidth(extent), height/CGRectGetHeight(extent));

    size_t scaledWidth = CGRectGetWidth(extent) * scale;
    size_t scaledHeight = CGRectGetHeight(extent) * scale;

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    CGContextRef bitmapContext = CGBitmapContextCreate(nil, scaledWidth, scaledHeight, 8, 0, colorSpace, kCGImageAlphaNone);
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef bitmapImage = [context createCGImage:outputImage fromRect:extent];

    CGContextSetInterpolationQuality(bitmapContext, kCGInterpolationNone);
    CGContextScaleCTM(bitmapContext, scale, scale);
    CGContextDrawImage(bitmapContext, extent, bitmapImage);

    CGImageRef scaledImage = CGBitmapContextCreateImage(bitmapContext);
    UIImage *result = [UIImage imageWithCGImage:scaledImage];

    CGColorSpaceRelease(colorSpace);
    CGContextRelease(bitmapContext);
    CGImageRelease(bitmapImage);
    CGImageRelease(scaledImage);

    return result;
}

- (BOOL)createData:(NSArray*)values {
    NSError *error = nil;

    for (int i = 0; i < [values count]; i++) {
        NSDictionary *jsonObject = [values objectAtIndex:i];
        NSString *textData = @"";

        if ([jsonObject objectForKey:@"type"]) {
            self.type = [jsonObject objectForKey:@"type"];

            if ([jsonObject objectForKey:@"alignText"]) {
                self.alignText = [[jsonObject objectForKey:@"alignText"] intValue];
            }

            if ([jsonObject objectForKey:@"addFeedLine"]) {
                self.addFeedLine = [[jsonObject objectForKey:@"addFeedLine"] intValue];
            }

            if ([jsonObject objectForKey:@"textSizeWidth"]) {
                self.textSizeWidth = [[jsonObject objectForKey:@"textSizeWidth"] intValue];
            }

            if ([jsonObject objectForKey:@"textSizeHeight"]) {
                self.textSizeHeight = [[jsonObject objectForKey:@"textSizeHeight"] intValue];
            }

            if ([jsonObject objectForKey:@"styles"]) {
                NSDictionary *styles = [jsonObject objectForKey:@"styles"];

                self.reverse = [[styles objectForKey:@"reverse"] intValue];
                self.ul = [[styles objectForKey:@"ul"] intValue];
                self.em = [[styles objectForKey:@"em"] intValue];
                self.color = [[styles objectForKey:@"color"] intValue];
            }

            if ([jsonObject objectForKey:@"data"]) {
                self.data = [jsonObject objectForKey:@"data"];
                textData = self.data;
            }

            if ([jsonObject objectForKey:@"qrCodeWidth"]) {
                self.qrCodeWidth = [[jsonObject objectForKey:@"qrCodeWidth"] intValue];
            }

            if ([jsonObject objectForKey:@"qrCodeHeight"]) {
                self.qrCodeHeight = [[jsonObject objectForKey:@"qrCodeHeight"] intValue];
            }

            // Add commands to printer
            self.method = @"addTextAlign";
            [self.printer addTextAlign:self.alignText];

            self.method = @"addTextSize";
            [self.printer addTextSize:self.textSizeWidth height:self.textSizeHeight];

            self.method = @"addTextStyle";
            [self.printer addTextStyle:self.reverse ul:self.ul em:self.em color:self.color];

            if ([self.type isEqualToString:@"qrCode"]) {
                self.method = @"addImage";
                UIImage *qrImage = [self encodeAsQRCode:textData width:self.qrCodeWidth height:self.qrCodeHeight];

                if (qrImage != nil) {
                    [self.printer addImage:qrImage x:0 y:0 width:self.qrCodeWidth height:self.qrCodeHeight
                                   color:EPOS2_PARAM_DEFAULT mode:EPOS2_PARAM_DEFAULT halftone:EPOS2_PARAM_DEFAULT
                                 brightness:3 compress:EPOS2_PARAM_DEFAULT];
                } else {
                    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                                messageAsString:@"Cannot create QR code"];
                    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.currentCallbackCommand.callbackId];
                    return NO;
                }
            } else {
                self.method = @"addText";
                [self.printer addText:textData];
            }

            self.method = @"addFeedLine";
            [self.printer addFeedLine:self.addFeedLine];
        }
    }

    return YES;
}

- (BOOL)isPrintable:(Epos2PrinterStatusInfo*)status {
    if (status == nil) {
        return NO;
    }

    if ([status getConnection] == EPOS2_FALSE) {
        return NO;
    } else if ([status getOnline] == EPOS2_FALSE) {
        return NO;
    }

    return YES;
}

- (BOOL)connectPrinter {
    BOOL isBeginTransaction = NO;
    NSError *error = nil;

    if (self.printer == nil) {
        return NO;
    }

    [self.printer connect:self.printerTarget timeout:EPOS2_PARAM_DEFAULT];
    if (error != nil) {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                        messageAsString:@"Connect to printer failed"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.currentCallbackCommand.callbackId];
        return NO;
    }

    [self.printer beginTransaction:&error];
    if (error == nil) {
        isBeginTransaction = YES;
    } else {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                        messageAsString:@"beginTransaction problem"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.currentCallbackCommand.callbackId];
    }

    if (!isBeginTransaction) {
        [self.printer disconnect];
        return NO;
    }

    return YES;
}

- (void)disconnectPrinter {
    if (self.printer == nil) {
        return;
    }

    NSError *error = nil;
    [self.printer endTransaction:&error];

    [self.printer disconnect];

    [self finalizeObject];
}

- (void)finalizeObject {
    if (self.printer == nil) {
        return;
    }

    [self.printer clearCommandBuffer];
    self.printer = nil;
}

- (BOOL)initializeObject {
    NSError *error = nil;

    self.printer = [[Epos2Printer alloc] initWithPrinterSeries:self.printerSeries lang:self.lang];
    if (self.printer == nil) {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                        messageAsString:@"Cannot create object Printer"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.currentCallbackCommand.callbackId];
        return NO;
    }

    [self.printer setReceiveEventDelegate:self];

    return YES;
}

- (BOOL)printData {
    if (self.printer == nil) {
        return NO;
    }

    if (![self connectPrinter]) {
        return NO;
    }

    NSError *error = nil;
    Epos2PrinterStatusInfo *status = [self.printer getStatus:&error];

    if (![self isPrintable:status]) {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                        messageAsString:[self makeErrorMessage:status]];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.currentCallbackCommand.callbackId];

        [self.printer disconnect];
        return NO;
    }

    [self.printer sendData:EPOS2_PARAM_DEFAULT];
    if (error != nil) {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                        messageAsString:@"Error on sendData to Printer"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.currentCallbackCommand.callbackId];

        [self.printer disconnect];
        return NO;
    }

    return YES;
}

- (NSString*)makeErrorMessage:(Epos2PrinterStatusInfo*)status {
    NSMutableString *msg = [NSMutableString string];

    if ([status getOnline] == EPOS2_FALSE) {
        [msg appendString:@"online"];
    }
    if ([status getConnection] == EPOS2_FALSE) {
        [msg appendString:@"getConnection"];
    }
    if ([status getCoverOpen] == EPOS2_TRUE) {
        [msg appendString:@"getCoverOpen"];
    }
    if ([status getPaper] == EPOS2_PAPER_EMPTY) {
        [msg appendString:@"PAPER_EMPTY"];
    }
    if ([status getPaperFeed] == EPOS2_TRUE || [status getPanelSwitch] == EPOS2_SWITCH_ON) {
        [msg appendString:@"SWITCH_ON"];
    }
    if ([status getErrorStatus] == EPOS2_MECHANICAL_ERR || [status getErrorStatus] == EPOS2_AUTOCUTTER_ERR) {
        [msg appendString:@"AUTOCUTTER_ERR"];
    }
    if ([status getErrorStatus] == EPOS2_UNRECOVER_ERR) {
        [msg appendString:@"UNRECOVER_ERR"];
    }
    if ([status getErrorStatus] == EPOS2_AUTORECOVER_ERR) {
        [msg appendString:@"AUTORECOVER_ERR"];
    }
    if ([status getBatteryLevel] == EPOS2_BATTERY_LEVEL_0) {
        [msg appendString:@"BATTERY_LEVEL_0"];
    }

    return msg;
}

- (BOOL)runPrintSequence:(NSArray*)values {
    if (![self initializeObject]) {
        return NO;
    }

    if (![self createData:values]) {
        [self finalizeObject];
        return NO;
    }

    if (![self printData]) {
        [self finalizeObject];
        return NO;
    }

    return YES;
}

#pragma mark - Epos2PtrReceiveDelegate implementation

- (void)onPtrReceive:(Epos2Printer *)printerObj code:(int)code status:(Epos2PrinterStatusInfo *)status printJobId:(NSString *)printJobId {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *msg = [self makeErrorMessage:status];

        if ([msg length] == 0) {
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                            messageAsString:@"PRINT_SUCCESS"];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:self.currentCallbackCommand.callbackId];
        } else {
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                            messageAsString:msg];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:self.currentCallbackCommand.callbackId];
        }

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self disconnectPrinter];
        });
    });
}

@end
