#import <Cordova/CDV.h>
#import <ePOS2/ePOS2.h>

@interface SbmCordovaPluginEpos2 : CDVPlugin <Epos2PtrReceiveDelegate>

// Properties equivalent to the Java implementation
@property (nonatomic, strong) NSMutableArray *printerList;
@property (nonatomic, strong) Epos2FilterOption *filterOption;
@property (nonatomic, strong) CDVInvokedUrlCommand *currentCallbackCommand;
@property (nonatomic, strong) Epos2Printer *printer;

// Methods that match your Android implementation
- (void)coolMethod:(CDVInvokedUrlCommand*)command;
- (void)printText:(CDVInvokedUrlCommand*)command;
- (void)discoverPrinters:(CDVInvokedUrlCommand*)command;
- (void)getPrintersList:(CDVInvokedUrlCommand*)command;
- (void)stopDiscoverPrinters:(CDVInvokedUrlCommand*)command;

// Helper methods (private in implementation)
- (BOOL)initializePrinter:(int)printerSeries lang:(int)lang target:(NSString*)printerTarget;
- (BOOL)createData:(NSArray*)values;
- (BOOL)connectPrinter;
- (void)disconnectPrinter;
- (void)finalizeObject;
- (BOOL)initializeObject;
- (BOOL)printData;
- (NSString*)makeErrorMessage:(Epos2PrinterStatusInfo*)status;
- (BOOL)runPrintSequence;
- (BOOL)isPrintable:(Epos2PrinterStatusInfo*)status;
- (UIImage*)encodeAsQRCode:(NSString*)str width:(int)width height:(int)height;

@end
