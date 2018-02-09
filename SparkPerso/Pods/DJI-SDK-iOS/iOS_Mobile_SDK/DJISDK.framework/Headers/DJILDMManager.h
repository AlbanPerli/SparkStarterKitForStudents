//
//  DJILDMManager.h
//  DJISDK
//
//  Copyright © 2017 DJI. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


/**
 *  Notification if LDM support has changed. If LDM support changes from `YES` to
 *  `NO`, and LDM is enabled, then LDM will be disabled after 5 minutes (300s) if
 *  `isLDMSupported` remains `NO`.
 */
extern NSString *DJILDMManagerSupportedChangedNotification;


/**
 *  Notification for when LDM transitions between enabled and disabled (and vise
 *  versa).
 */
extern NSString *DJILDMManagerEnabledChangedNotification;


/**
 *  Local Data Mode (LDM) manager. When Local Data Mode is enabled, the SDK's access
 *  to the internet is  restricted. Only application registration (confirming the
 *  app key is valid) will be unrestricted.  All other SDK services will be
 *  restricted. When the SDK's internet access is restricted, all SDK  services that
 *  require an internet connection will not be available or able to update. For
 *  instance,  the Fly Zone manager will not be able to update the fly zone data
 *  base, retrieve the latest TFRs  (temporary flight restrictions) or unlock fly
 *  zones. LDM is therefore most appropriate for users  that have very stringent
 *  data requirements, and are able to accomodate this restricted functionality.
 *  `*DJILDMManagerSupportedChangedNotification` and
 *  `*DJILDMManagerEnabledChangedNotification`  can be used to monitor changes in
 *  state for availabiltiy of LDM support and whether LDM is enabled or not. LDM is
 *  not available when operating in China.
 */
@interface DJILDMManager : NSObject


/**
 *  `YES` if LDM is supported in the current context. LDM is not supported in China.
 *  The SDK locally uses a combination of IP address, GPS location and MCC (mobile
 *  country code) to determine the country of operation.
 *  
 *  @return A bool value to check if LDM is supported.
 */
@property (readonly, nonatomic) BOOL isLDMSupported;


/**
 *  `YES` if LDM is already enabled.
 *  
 *  @return A boolean value to check if LDM is enabled.
 */
@property (readonly, nonatomic) BOOL isLDMEnabled;

- (instancetype)init OBJC_UNAVAILABLE("You must use the singleton");

+ (instancetype)new OBJC_UNAVAILABLE("You must use the singleton");

/*********************************************************************************/
#pragma mark - Local Data Mode (LDM)
/*********************************************************************************/


/**
 *  Enables LDM. Can only be enabled if `isLDMSupported` is `YES`.
 *  
 *  @return The error occured. NULL if LDM is enabled successfully.
 */
- (nullable NSError *)enableLDM;


/**
 *  Disables LDM.
 */
- (void)disableLDM;

@end

NS_ASSUME_NONNULL_END
