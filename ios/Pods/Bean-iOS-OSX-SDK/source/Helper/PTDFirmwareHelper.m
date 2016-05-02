#import "PTDFirmwareHelper.h"
#import "PTDUtils.h"
#import "PTDBean.h"

@implementation PTDFirmwareHelper

+ (FirmwareStatus)firmwareUpdateRequiredForBean:(PTDBean *)bean availableFirmware:(NSInteger)version withError:(NSError * __autoreleasing *)error
{
    // OAD images always need an update
    if ([self oadImageRunningOnBean:bean]) {
        return FirmwareStatusBeanNeedsUpdate;
    }
    
    NSNumber *onBeanNumber = [PTDUtils parseLeadingInteger:bean.firmwareVersion];
    if (!onBeanNumber) {
        *error = [self errorForNonIntegerVersion:bean.firmwareVersion deviceName:@"Bean"];
        return FirmwareStatusCouldNotDetermine;
    }
    
    NSInteger available = version;
    NSInteger onBean = [onBeanNumber integerValue];

    if (available > onBean) {
        return FirmwareStatusBeanNeedsUpdate;
    } else if (onBean > available) {
        return FirmwareStatusBeanIsNewerThanAvailable;
    } else {
        return FirmwareStatusUpToDate;
    }
}

+ (BOOL)oadImageRunningOnBean:(PTDBean *)bean
{
    NSError *error;
    NSRegularExpression *rx = [NSRegularExpression regularExpressionWithPattern:@"\\bOAD\\b" options:0 error:&error];
    if (error) {
        PTDLog(@"WARNING: Could not create OAD regex: %@", error);
        return NO;
    }

    NSTextCheckingResult *match = [rx firstMatchInString:bean.firmwareVersion options:0 range:NSMakeRange(0, bean.firmwareVersion.length)];
    if (match) {
        return YES;
    } else {
        return NO;
    }
}

+ (NSError *)errorForNonIntegerVersion:(NSString *)version deviceName:(NSString *)name
{
    NSString *message = @"Firmware version string for %@ could not be parsed as an integer: \"%@\"";
    NSString *desc = [NSString stringWithFormat:message, name, version];
    return [NSError errorWithDomain:@"FirmwareVersionInvalid"
                               code:-1
                           userInfo:@{@"localizedDescription": desc}];
}

@end
