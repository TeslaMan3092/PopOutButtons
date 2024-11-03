#import <Foundation/Foundation.h>
#import <Foundation/NSDistributedNotificationCenter.h>
#import <Preferences/PSListController.h>
#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <Preferences/PSTableCell.h>
#import <Preferences/PSControlTableCell.h>
#import <Preferences/PSSwitchTableCell.h>
#import <sys/utsname.h>
#import <rootless.h>
#include <spawn.h>

@interface POBRootListController : PSListController
@property (nonatomic, strong) UIButton *keyboardDismissalButton;
@property (nonatomic, strong) NSString *modelString;
- (void)openURL:(NSString *)url;
@end

@interface POBBannerCell : PSTableCell
@end

@interface POBSliderCell : PSTableCell <UITextFieldDelegate>
- (NSString *)formatFloat:(CGFloat)number;
@property (nonatomic, assign) BOOL shouldSendNormalNotifForUpdate;
@end

@interface POBSlider : UISlider
@end