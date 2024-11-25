#import <AudioToolbox/AudioToolbox.h>
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <math.h>
#import <rootless.h>
#import <sys/utsname.h>
#import <Foundation/NSDistributedNotificationCenter.h>
#import <GcUniversal/GcColorPickerUtils.h>

@interface UIDevice (PopOutButtons)
+ (NSString *)_pob_deviceMachine;
@end

@interface CALayer (Undocumented)
@property (atomic, assign) unsigned int disableUpdateMask;
@end

@interface UIWindow (Undocumented)
- (void)setAutorotates:(BOOL)autorotates forceUpdateInterfaceOrientation:(BOOL)forceUpdateInterfaceOrientation;
- (void)setAutorotates:(BOOL)autorotates;
- (void)_rotateWindowToOrientation:(NSInteger)orientation updateStatusBar:(BOOL)updateStatusBar duration:(CGFloat)duration skipCallbacks:(BOOL)skipCallbacks;
@end

@interface UIScreen (Undocumented)
@property (nonatomic, assign) CGRect _referenceBounds;
@end

@interface UIBezierPath (Undocumented)
- (void)_addRoundedCornerWithTrueCorner:(CGPoint)cornerPoint radius:(CGSize)radius corner:(NSUInteger)corner clockwise:(BOOL)clockwise leadInIsContinuous:(BOOL)leadInIsContinuous leadOutIsContinuous:(BOOL)leadOutIsContinuous;
@end 

@interface SBHUDWindow : UIWindow
- (void)_pob_setHUDShiftOut:(BOOL)shift;
@end

@interface SBSecureWindow : UIWindow
- (instancetype)initWithScreen:(UIScreen *)screen debugName:(NSString *)name;
- (instancetype)initWithScreen:(UIScreen *)screen role:(id)role debugName:(NSString *)name;
- (instancetype)initWithWindowScene:(UIWindowScene *)scene role:(id)role debugName:(NSString *)name;
- (instancetype)initWithScreen:(UIScreen *)screen debugName:(NSString *)debugName rootViewController:(UIViewController *)rootViewController;
@end

@interface SBFTouchPassThroughViewController : UIViewController
@end

@interface POBShapeLayer : CAShapeLayer
@property (nonatomic, strong) UIBezierPath *showingPath;
@property (nonatomic, strong) UIBezierPath *hidingPath;
@property (nonatomic, assign) BOOL isBackwards;
@property (nonatomic, assign) CGFloat curvedness;
@property (nonatomic, strong) NSTimer *waitToRemoveBorderTimer;
@property (nonatomic, assign) CGFloat defaultLineWidth;
@property (nonatomic, assign) BOOL isShowing;
- (void)setBorderWithShowing:(BOOL)showing;
- (void)removeBorderWithTimer:(NSTimer *)timer;
- (void)updateStateWithShowing:(BOOL)showing;
- (void)updatePathsWithFrame:(CGRect)frame hidden:(BOOL)startHidden;
@end

@interface POBWindow : SBSecureWindow
@end

@interface SBVolumeButtonEventMapper : NSObject
@property (nonatomic, assign) NSInteger effectiveInterfaceOrientation;
@end

@interface SpringBoard : UIApplication
@property (nonatomic, retain) POBWindow *_pobWindow;
@property (nonatomic, retain) SBHUDWindow *_pob_SBHUDWindow;
- (SBVolumeButtonEventMapper *)volumeButtonEventMapper;
@end

@interface POBRootViewContoller : SBFTouchPassThroughViewController
@property (nonatomic, strong) POBShapeLayer *volUpLayer;
@property (nonatomic, strong) POBShapeLayer *volDownLayer;
@property (nonatomic, strong) POBShapeLayer *lockButtonLayer;
@property (nonatomic, assign) CGFloat volUpDefaultY;
@property (nonatomic, assign) CGFloat volDownDefaultY;
@property (nonatomic, assign) CGFloat lockButtonDefaultY;
@property (nonatomic, strong) NSTimer *hidePopoutsTimer;
- (void)handlePrefsUpdateWithNotification:(NSNotification *)notification;
- (void)handlePrefsUpdate;
@end

@interface SBVolumeControl : NSObject
@end

@interface SBHUDController : NSObject
- (SBHUDWindow *)hudWindow;
- (BOOL)anyHUDsVisible;
@end

@interface SBLockHardwareButton : NSObject
- (BOOL)isButtonDown;
@end