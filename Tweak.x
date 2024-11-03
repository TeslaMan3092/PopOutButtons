#import "Tweak.h"

static SBHUDWindow *hudWindow = nil;

const static CGFloat defaultButtonHeight = 85;

static CGFloat volUpButtonYOffset = 0.0f;
static CGFloat volUpButtonSizeOffset = 0.0f;
static CGFloat volUpCurvedness = 0.0f;
static UIColor *volUpPopoutColor = nil;

static CGFloat volDownButtonYOffset = 0.0f;
static CGFloat volDownButtonSizeOffset = 0.0f;
static CGFloat volDownCurvedness = 0.0f;
static UIColor *volDownPopoutColor = nil;

static CGFloat lockButtonYOffset = 0.0f;
static CGFloat lockButtonSizeOffset = 0.0f;
static CGFloat lockButtonCurvedness = 0.0f;
static UIColor *lockPopoutColor = nil;

static CGFloat globalBorderWidth = 0.0f;
static UIColor *globalBorderColor = nil;

static unsigned int invisibleToScreenCaptures = 0;

static void updatePrefs(void) {	
	NSDictionary *const prefs = [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.teslaman3092.popoutbuttonsprefs"];

	invisibleToScreenCaptures = (prefs && [prefs objectForKey:@"invisibleToScreenCaptures"] ? [[prefs valueForKey:@"invisibleToScreenCaptures"] boolValue] : YES ) ? (1 << 1) | (1 << 4) : 0;
	globalBorderColor = [GcColorPickerUtils colorFromDefaults:@"com.teslaman3092.popoutbuttonsprefs" withKey:@"globalBorderColor" fallback:@"5C5C5CFF"];
	globalBorderWidth = [prefs objectForKey:@"globalBorderWidth"] ? [[prefs valueForKey:@"globalBorderWidth"] floatValue] : 0.2;

	volUpPopoutColor = [GcColorPickerUtils colorFromDefaults:@"com.teslaman3092.popoutbuttonsprefs" withKey:@"volUpPopoutColor" fallback:@"000000"];
	volDownPopoutColor = [GcColorPickerUtils colorFromDefaults:@"com.teslaman3092.popoutbuttonsprefs" withKey:@"volDownPopoutColor" fallback:@"000000"];
	lockPopoutColor = [GcColorPickerUtils colorFromDefaults:@"com.teslaman3092.popoutbuttonsprefs" withKey:@"lockPopoutColor" fallback:@"000000"];

	SpringBoard *const springBoard = (SpringBoard *)[%c(SpringBoard) sharedApplication];
	POBRootViewContoller *const pobRootVC = (POBRootViewContoller *)[springBoard _pobWindow].rootViewController;
	[pobRootVC handlePrefsUpdate]; 
}

%hook SBLockHardwareButton

- (void)buttonDown:(id)arg0 {
	%orig;
	SpringBoard *const springBoard = (SpringBoard *)[%c(SpringBoard) sharedApplication];
	POBRootViewContoller *const pobRootVC = (POBRootViewContoller *)[springBoard _pobWindow].rootViewController;
	[pobRootVC.lockButtonLayer updateStateWithShowing:self.isButtonDown];
}

%end

%hook SBVolumeControl

- (void)handleVolumeButtonWithType:(NSInteger)buttonType down:(BOOL)down {
	%orig;

	BOOL reverseButtons = NO;
	SpringBoard *const springBoard = (SpringBoard *)[%c(SpringBoard) sharedApplication];
	POBRootViewContoller *const pobRootVC = (POBRootViewContoller *)[springBoard _pobWindow].rootViewController;

	if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
		SBVolumeButtonEventMapper *const eventMapper = [springBoard volumeButtonEventMapper];
		reverseButtons = (eventMapper.effectiveInterfaceOrientation == 2 || eventMapper.effectiveInterfaceOrientation == 3);
	}

	if (buttonType == (reverseButtons ? 103 : 102)) [pobRootVC.volUpLayer updateStateWithShowing:down];
	if (buttonType == (reverseButtons ? 102 : 103)) [pobRootVC.volDownLayer updateStateWithShowing:down];


	if((pobRootVC.volUpLayer.isShowing || pobRootVC.volDownLayer.isShowing) && !down) return;

	SBHUDController *const HUDController = [self valueForKey:@"_hudController"];
	if([HUDController anyHUDsVisible]){
		[[HUDController hudWindow] _pob_setHUDShiftOut:down];
	}else{
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.05 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{    
			if([HUDController anyHUDsVisible]) [[HUDController hudWindow] _pob_setHUDShiftOut:down];
		});
	}
}

%end

%subclass POBWindow : SBSecureWindow

- (BOOL)shouldAutorotate {
    return NO;
}

- (void)setAutorotates:(BOOL)autorotates {
    %orig(NO);
}

%end

%subclass POBRootViewContoller : SBFTouchPassThroughViewController
%property (nonatomic, strong) POBShapeLayer *volUpLayer;
%property (nonatomic, strong) POBShapeLayer *volDownLayer;
%property (nonatomic, strong) POBShapeLayer *lockButtonLayer;
%property (nonatomic, assign) CGFloat volUpDefaultY;
%property (nonatomic, assign) CGFloat volDownDefaultY;
%property (nonatomic, assign) CGFloat lockButtonDefaultY;
%property (nonatomic, strong) NSTimer *hidePopoutsTimer;

- (instancetype)init {
    self = %orig;
	
    UIView *const view = [UIView new];
	view.backgroundColor = [UIColor clearColor];

	self.volUpLayer = [[POBShapeLayer alloc] init];
	self.volUpLayer.fillColor = volUpPopoutColor.CGColor;
	self.volUpLayer.disableUpdateMask = invisibleToScreenCaptures;

	self.volDownLayer = [[POBShapeLayer alloc] init];
	self.volDownLayer.fillColor = volDownPopoutColor.CGColor;
	self.volDownLayer.disableUpdateMask = invisibleToScreenCaptures;

	self.lockButtonLayer = [[POBShapeLayer alloc] init];
	self.lockButtonLayer.fillColor = lockPopoutColor.CGColor;
	self.lockButtonLayer.disableUpdateMask = invisibleToScreenCaptures;

	if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
		self.volUpLayer.isBackwards = YES;// lets the path creator know it need to reverse/mirror the path. in popoutButtons.m
		self.volUpLayer.frame = CGRectMake(0,-5,5,defaultButtonHeight + volUpButtonSizeOffset);
		self.volUpDefaultY = -5;

		self.volDownLayer.isBackwards = YES; 
		self.volDownLayer.frame = CGRectMake(0,85,5,defaultButtonHeight + volDownButtonSizeOffset);
		self.volDownDefaultY = 85;

		view.frame = CGRectMake(UIScreen.mainScreen._referenceBounds.size.width, -2, 10, 200); // put the popout view on the other side of the screen where the physical buttons are on an ipad
	} else {
		NSData *const data = [NSData dataWithContentsOfFile:JBROOT_PATH_NSSTRING(@"/Library/Application Support/PopOutButtonsResources/deviceVolumeButtonPositioning.plist")];
		NSDictionary *const deviceVolBtnPositionDict = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListMutableContainersAndLeaves format:nil error:nil];
        NSString *const modelIDstr = [UIDevice _pob_deviceMachine];

		self.volUpDefaultY = [[NSString stringWithFormat:@"%@",[[deviceVolBtnPositionDict objectForKey:modelIDstr] objectForKey:@"volumeUpButtonY"]] floatValue];
		self.volDownDefaultY = [[NSString stringWithFormat:@"%@",[[deviceVolBtnPositionDict objectForKey:modelIDstr] objectForKey:@"volumeDownButtonY"]] floatValue];
		self.lockButtonDefaultY = [[NSString stringWithFormat:@"%@",[[deviceVolBtnPositionDict objectForKey:modelIDstr] objectForKey:@"powerButtonY"]] floatValue];

		self.volUpLayer.frame = CGRectMake(0, self.volUpDefaultY - 2 + volUpButtonYOffset, 5, defaultButtonHeight + volUpButtonSizeOffset);
		self.volDownLayer.frame = CGRectMake(0, self.volDownDefaultY - 2 + volDownButtonYOffset, 5, defaultButtonHeight + volDownButtonSizeOffset);

		self.lockButtonLayer.isBackwards = YES;
		self.lockButtonLayer.frame = CGRectMake(UIScreen.mainScreen._referenceBounds.size.width, self.lockButtonDefaultY - 12 + lockButtonYOffset, 5, 136 + lockButtonSizeOffset);

		view.frame = CGRectMake(0, 0, 5, 200);
		
		if ([[UIDevice currentDevice].model isEqualToString:@"iPod touch"] || [modelIDstr containsString:@"iPhone8,4"]) {
			self.lockButtonLayer.hidden = YES;
		}
	}

    [view.layer addSublayer:self.volUpLayer];
	[view.layer addSublayer:self.volDownLayer];
	[view.layer addSublayer:self.lockButtonLayer];
	[self.view addSubview:view];

	[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePrefsUpdateWithNotification:) name:@"com.teslaman3092.popoutbuttons-updatePopoutsWithValues" object:nil];

    return self;
}

- (void)viewDidLoad {
	%orig;

	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{  
		POBWindow *const window = (POBWindow *)[(SpringBoard *)[%c(SpringBoard) sharedApplication] _pobWindow];
		[window setAutorotates:NO];
		[window _rotateWindowToOrientation:1 updateStatusBar:0 duration:1 skipCallbacks:1]; // if ipad resprings not into portrait mode, this fixes it
	});
}

- (BOOL)shouldAutorotate {
    return NO;
}

%new
- (void)handlePrefsUpdateWithNotification:(NSNotification *)notification {
	NSString *const sliderKey = notification.userInfo[@"key"];
	CGFloat const sliderValue = [notification.userInfo[@"value"] floatValue];

	if ([sliderKey isEqualToString:@"volUpButtonYOffset"]) {
		volUpButtonYOffset = sliderValue;
	} else if ([sliderKey isEqualToString:@"volUpButtonSizeOffset"]) {
		volUpButtonSizeOffset = sliderValue;
	} else if ([sliderKey isEqualToString:@"volDownButtonYOffset"]) {
		volDownButtonYOffset = sliderValue;
	} else if ([sliderKey isEqualToString:@"volDownButtonSizeOffset"]) {
		volDownButtonSizeOffset = sliderValue;
	} else if ([sliderKey isEqualToString:@"lockButtonYOffset"]) {
		lockButtonYOffset = sliderValue;
	} else if ([sliderKey isEqualToString:@"lockButtonSizeOffset"]) {
		lockButtonSizeOffset = sliderValue;
	} else if ([sliderKey isEqualToString:@"volUpCurvedness"]) {
		volUpCurvedness = sliderValue;
	} else if ([sliderKey isEqualToString:@"volDownCurvedness"]) {
		volDownCurvedness = sliderValue;
	} else if ([sliderKey isEqualToString:@"lockButtonCurvedness"]) {
		lockButtonCurvedness = sliderValue;
	} else if ([sliderKey isEqualToString:@"globalBorderWidth"]) {
		globalBorderWidth = sliderValue;
	}

	[self.hidePopoutsTimer invalidate];
	self.hidePopoutsTimer = nil;
	self.hidePopoutsTimer = [NSTimer scheduledTimerWithTimeInterval:1.5 target:self selector:@selector(hidePopoutsFromTimer:) userInfo:nil repeats:NO];
	
	self.volUpLayer.frame = CGRectMake(0, self.volUpDefaultY - 2 + volUpButtonYOffset,5,defaultButtonHeight + volUpButtonSizeOffset);
	self.volUpLayer.curvedness = volUpCurvedness;
	[self.volUpLayer updatePathsWithFrame:self.volUpLayer.frame hidden:NO];
	self.volUpLayer.defaultLineWidth = globalBorderWidth;

	self.volDownLayer.frame = CGRectMake(0, self.volDownDefaultY - 2 + volDownButtonYOffset,5,defaultButtonHeight + volDownButtonSizeOffset);
	self.volDownLayer.curvedness = volDownCurvedness;
	[self.volDownLayer updatePathsWithFrame:self.volDownLayer.frame hidden:NO];
	self.volDownLayer.defaultLineWidth = globalBorderWidth;

	self.lockButtonLayer.frame = CGRectMake(UIScreen.mainScreen._referenceBounds.size.width, self.lockButtonDefaultY - 2 + lockButtonYOffset,5,100 + lockButtonSizeOffset);
	self.lockButtonLayer.curvedness = lockButtonCurvedness;
	[self.lockButtonLayer updatePathsWithFrame:self.lockButtonLayer.frame hidden:NO];
	self.lockButtonLayer.defaultLineWidth = globalBorderWidth;
}

%new
- (void)handlePrefsUpdate {	
	[self.hidePopoutsTimer invalidate];
	self.hidePopoutsTimer = nil;
	self.hidePopoutsTimer = [NSTimer scheduledTimerWithTimeInterval:1.5 target:self selector:@selector(hidePopoutsFromTimer:) userInfo:nil repeats:NO];

	self.volUpLayer.fillColor = volUpPopoutColor.CGColor;
	self.volDownLayer.fillColor = volDownPopoutColor.CGColor;
	self.lockButtonLayer.fillColor = lockPopoutColor.CGColor;
	
	[self.volDownLayer updatePathsWithFrame:self.volDownLayer.frame hidden:NO]; // Show popouts after pref change
	[self.volUpLayer updatePathsWithFrame:self.volUpLayer.frame hidden:NO];
	[self.lockButtonLayer updatePathsWithFrame:self.lockButtonLayer.frame hidden:NO];

	self.volUpLayer.disableUpdateMask = invisibleToScreenCaptures;
	self.volDownLayer.disableUpdateMask = invisibleToScreenCaptures;
	self.lockButtonLayer.disableUpdateMask = invisibleToScreenCaptures;

	self.volUpLayer.strokeColor = globalBorderColor.CGColor;
	self.volDownLayer.strokeColor = globalBorderColor.CGColor;
	self.lockButtonLayer.strokeColor = globalBorderColor.CGColor;
}

%new
- (void)hidePopoutsFromTimer:(NSTimer *)timer {
    [self.volUpLayer updateStateWithShowing:NO];
	[self.volDownLayer updateStateWithShowing:NO];
	[self.lockButtonLayer updateStateWithShowing:NO];
}

%end

%hook SpringBoard 
%property (nonatomic, retain) POBWindow *_pobWindow;
%property (nonatomic, retain) SBHUDWindow *_pob_SBHUDWindow;

- (void)applicationDidFinishLaunching:(id)application {
	%orig;

	if (@available(iOS 16.0, *)) { // Thx Sushi... https://github.com/Skittyblock/Sushi/blob/2ce0056cb38894cd122cd0559ce614f618f2f8be/tweak/Tweak.x#L87
		UIWindowScene *windowScene = nil;

		for (UIScene *scene in self.connectedScenes) {
			if ([scene isKindOfClass:%c(UIWindowScene)]) {
				windowScene = (UIWindowScene *)scene;
			}
		}
		
		if (!windowScene) return;

		self._pobWindow = [[%c(POBWindow) alloc] initWithWindowScene:windowScene role:nil debugName:@"POBWindow"];
		self._pobWindow.rootViewController = [[%c(POBRootViewContoller) alloc] init];
	} else if (@available(iOS 15.0, *)) {
		self._pobWindow = [[%c(POBWindow) alloc] initWithScreen:[UIScreen mainScreen] role:nil debugName:@"POBWindow"];	
		self._pobWindow.rootViewController = [[%c(POBRootViewContoller) alloc] init];
	} else {
		self._pobWindow = [[%c(POBWindow) alloc] initWithScreen:[UIScreen mainScreen] debugName:@"POBWindow" rootViewController:[%c(POBRootViewContoller) new]];
	}

	self._pobWindow.backgroundColor = nil;
	self._pobWindow.userInteractionEnabled = NO;
	self._pobWindow.windowLevel = UIWindowLevelAlert + 1;
	[self._pobWindow setAutorotates:NO];

	[self._pobWindow makeKeyAndVisible];
}

%end

%hook SBHUDWindow

%new
- (void)_pob_setHUDShiftOut:(BOOL)shiftOut{
	if(shiftOut){
		[UIView animateWithDuration:0.1 animations:^{
			self.rootViewController.view.transform = CGAffineTransformMakeTranslation(5, 0);
		}];
	}else{
		[UIView animateWithDuration:0.2 animations:^{
			self.rootViewController.view.transform = CGAffineTransformMakeTranslation(0, 0);
		}];
	}
}

%end


%ctor {
	NSDictionary *const prefs = [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.teslaman3092.popoutbuttonsprefs"];

	if (!(prefs && [prefs objectForKey:@"tweakEnabled"] ? [[prefs valueForKey:@"tweakEnabled"] boolValue] : YES)) return;
	
	// Volume Up Button
	volUpButtonYOffset = [prefs objectForKey:@"volUpButtonYOffset"] ? [[prefs valueForKey:@"volUpButtonYOffset"] floatValue] : 0;
	volUpButtonSizeOffset = [prefs objectForKey:@"volUpButtonSizeOffset"] ? [[prefs valueForKey:@"volUpButtonSizeOffset"] floatValue] : 0;
	volUpCurvedness = [prefs objectForKey:@"volUpCurvedness"] ? [[prefs valueForKey:@"volUpCurvedness"] floatValue] : 0;

	// Volume Down Button
	volDownButtonYOffset = [prefs objectForKey:@"volDownButtonYOffset"] ? [[prefs valueForKey:@"volDownButtonYOffset"] floatValue] : 0;
	volDownButtonSizeOffset = [prefs objectForKey:@"volDownButtonSizeOffset"] ? [[prefs valueForKey:@"volDownButtonSizeOffset"] floatValue] : 0;
	volDownCurvedness = [prefs objectForKey:@"volDownCurvedness"] ? [[prefs valueForKey:@"volDownCurvedness"] floatValue] : 0;

	// Lock/Power Button
	lockButtonYOffset = [prefs objectForKey:@"lockButtonYOffset"] ? [[prefs valueForKey:@"lockButtonYOffset"] floatValue] : 0;
	lockButtonSizeOffset = [prefs objectForKey:@"lockButtonSizeOffset"] ? [[prefs valueForKey:@"lockButtonSizeOffset"] floatValue] : 0;
	lockButtonCurvedness = [prefs objectForKey:@"lockButtonCurvedness"] ? [[prefs valueForKey:@"lockButtonCurvedness"] floatValue] : 0;

	updatePrefs();
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)updatePrefs, CFSTR("com.teslaman3092.popoutbuttonsprefs-updated"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
	
	%init;
}