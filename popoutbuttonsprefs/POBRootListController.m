#import "POBRootListController.h"

@implementation POBRootListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];

        if (!([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad || [[UIDevice currentDevice].model isEqualToString:@"iPod touch"] || [self.modelString containsString:@"iPhone8,4"])) return _specifiers;

        const NSUInteger size = [_specifiers count];
        for (NSInteger i = size - 1; i >= 0; i--) {
            if ([[NSString stringWithFormat:@"%@", [_specifiers[i] propertyForKey:@"hideOnIpad"]] containsString:@"1"]) {
                [_specifiers removeObjectAtIndex:i];
            }
        }
        return _specifiers;
	}
	return _specifiers;
}

- (PSTableCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	PSTableCell *const cell = (PSTableCell *)[super tableView:tableView cellForRowAtIndexPath:indexPath];

    if ([cell.specifier propertyForKey:@"clearBackground"]) {
        cell.backgroundColor = [UIColor clearColor];
    }

	return cell;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.keyboardDismissalButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.keyboardDismissalButton.frame = CGRectMake(0, 0, 28, 28);
    [self.keyboardDismissalButton setImage:[UIImage systemImageNamed:@"keyboard.chevron.compact.down"] forState:UIControlStateNormal];
    [self.keyboardDismissalButton addTarget:self action:@selector(keyboardDismissalButtonPressed:) forControlEvents:UIControlEventTouchUpInside];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.keyboardDismissalButton];

    struct utsname systemInfo;
    const int status = uname(&systemInfo);
    
    if (status != -1) {
        self.modelString = [NSString stringWithUTF8String:systemInfo.machine]; // Thanks @Nightwind
    }
}

- (void)keyboardDismissalButtonPressed:(UIButton *)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:UIKeyboardWillHideNotification object:nil];    
}

- (void)debug {
    NSData *const data = [NSData dataWithContentsOfFile:JBROOT_PATH_NSSTRING(@"/Library/Application Support/PopOutButtonsResources/deviceVolumeButtonPositioning.plist")];
    NSDictionary *const deviceVolBtnPositionDict = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListMutableContainersAndLeaves format:nil error:nil];
    
    CGFloat const volUpDefaultY = [[NSString stringWithFormat:@"%@", [[deviceVolBtnPositionDict objectForKey:self.modelString] objectForKey:@"volumeUpButtonY"]] floatValue];
    CGFloat const volDownDefaultY = [[NSString stringWithFormat:@"%@", [[deviceVolBtnPositionDict objectForKey:self.modelString] objectForKey:@"volumeDownButtonY"]] floatValue];
    CGFloat const lockDefaultY = [[NSString stringWithFormat:@"%@", [[deviceVolBtnPositionDict objectForKey:self.modelString] objectForKey:@"powerButtonY"]] floatValue];

    UIAlertController *const alert = [UIAlertController
        alertControllerWithTitle:@"PopOutButtonsDEBUG"
        message:[NSString stringWithFormat:@"modelIDstr(%@) volUpDefaultY(%f) volDownDefaultY(%f) lockButtonDefaultY(%f) deviceVolBtnPositionDictIsNil(%d)", self.modelString, volUpDefaultY, volDownDefaultY, lockDefaultY, (deviceVolBtnPositionDict == nil) ]
        preferredStyle:UIAlertControllerStyleAlert
    ];

    [alert addAction:[UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleCancel handler:nil]];   
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)_returnKeyPressed:(id)arg1 {
    [self.view endEditing:YES];
}


- (void)showRespringAlert {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Rspring" message:@"Respring Now?" preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"Respring" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleRegular];
        UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:blur];
        blurView.frame = self.view.bounds;
        blurView.alpha = 0;
        
        [self.view addSubview:blurView];

        [UIView animateWithDuration:0.45 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            [blurView setAlpha:1.0];
        } completion:^(BOOL finished) {
            if (finished){
                [self performKillallSpringBoard];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{       
                    [blurView removeFromSuperview];
                });
            }
        }];
    }];
    [alert addAction:defaultAction];

    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];   

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)resetPrefs {
    UIAlertController *alert = [UIAlertController 
        alertControllerWithTitle:@"Reset preferances to default?" 
        message:@"This will revert any and all changes you have made"
        preferredStyle:UIAlertControllerStyleAlert
    ];

    UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"Reset" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:@"com.teslaman3092.popoutbuttonsprefs"];
        NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.teslaman3092.popoutbuttonsprefs"];

        [userDefaults synchronize];

        UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleRegular];
            UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:blur];
            blurView.frame = self.view.bounds;
            blurView.alpha = 0;
        [self.view addSubview:blurView];

        [UIView animateWithDuration:0.45 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            [blurView setAlpha:1.0];
        } completion:^(BOOL finished) {
            if(finished){
                [self performSbreload];
            }
        }];
    }];
    
    [alert addAction:defaultAction];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];   

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)contact{
    UIAlertController *alert = [UIAlertController 
        alertControllerWithTitle:@"Contact tesla_man" 
        message:@"Choose your method for contacting me"
        preferredStyle:UIAlertControllerStyleAlert
    ];

    UIAlertAction *openMyTwitter = [UIAlertAction actionWithTitle:@"Open My Twitter" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
       [self openURL:@"https://x.com/tesla_man3092"];
    }];

    UIAlertAction *emailMe = [UIAlertAction actionWithTitle:@"Email Me" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
       [self openURL:@"mailto:computerman939+POBsupport@gmail.com"];
    }];

    UIAlertAction *openMyDiscordProfile = [UIAlertAction actionWithTitle:@"Open My Discord Profile" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = @"tesla_man";
        [self openURL:@"discord://-/users/755485349060280351"]; // Thx https://gist.github.com/ghostrider-05/8f1a0bfc27c7c4509b4ea4e8ce718af0
    }];

    UIAlertAction *copyMyDiscordTag = [UIAlertAction actionWithTitle:@"Copy My Discord Tag" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = @"tesla_man";
    }];

    UIAlertAction *copyMyRedditUser = [UIAlertAction actionWithTitle:@"Copy My Reddit Username" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
       UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = @"u/computerman3092";
    }];

    [alert addAction:openMyTwitter];
    [alert addAction:emailMe];
    [alert addAction:openMyDiscordProfile];
    [alert addAction:copyMyDiscordTag];
    [alert addAction:copyMyRedditUser];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];   

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)performKillallSpringBoard {
    pid_t pid;
    const char *args[] = {"killall", "SpringBoard", NULL};
	posix_spawn(&pid, JBROOT_PATH_CSTRING("/usr/bin/killall"), NULL, NULL, (char *const *)args, NULL);
}

- (void)performSbreload {
    pid_t pid;
	const char *args[] = {"sbreload", NULL, NULL, NULL};
    posix_spawn(&pid, JBROOT_PATH_CSTRING("/usr/bin/sbreload"), NULL, NULL, (char *const *)args, NULL);
}

- (void)openURL:(NSString *)url {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url] options:@{} completionHandler:nil];
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
    NSString *prefKey = specifier.properties[@"key"];
    NSString *valueStr = [NSString stringWithFormat:@"%@",value];
    
    if([prefKey isEqualToString:@"globalHapticsWithID"] && ![valueStr isEqualToString:@"0"]) AudioServicesPlaySystemSound([valueStr floatValue]);

    [super setPreferenceValue:value specifier:specifier];
}

@end

// ---- Custom Cells... ----

@implementation POBBannerCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)identifier specifier:(PSSpecifier *)specifier {
    self = [super initWithStyle:style reuseIdentifier:identifier specifier:specifier];

    if (self) {
        self.userInteractionEnabled = NO;
        self.backgroundColor = [UIColor clearColor];

        UIImage *const tweakLogoImage = [UIImage imageNamed:@"icon@3x.png" inBundle:[NSBundle bundleForClass:self.class] compatibleWithTraitCollection:nil];
        UIImageView *const tweakIcon = [[UIImageView alloc] initWithImage:tweakLogoImage];
        tweakIcon.layer.cornerRadius = 8.0f;
        tweakIcon.layer.masksToBounds = YES;
        tweakIcon.clipsToBounds = YES;
        tweakIcon.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:tweakIcon];

        UILabel *const tweakName = [UILabel new];
        tweakName.text = @"PopOutButtons";
        tweakName.font = [UIFont boldSystemFontOfSize:35];
        tweakName.translatesAutoresizingMaskIntoConstraints = NO;
        tweakName.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:tweakName];

        UILabel *const tweakVersion = [UILabel new];
        tweakVersion.text = @"@tesla_man";
        tweakVersion.textColor = UIColor.secondaryLabelColor;
        tweakVersion.font = [UIFont systemFontOfSize:20];
        tweakVersion.textAlignment = NSTextAlignmentCenter;
        tweakVersion.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:tweakVersion];
    
        [NSLayoutConstraint activateConstraints:@[
            [tweakIcon.widthAnchor constraintEqualToConstant: 50],
            [tweakIcon.heightAnchor constraintEqualToConstant: 50],
            
            [tweakName.centerXAnchor constraintLessThanOrEqualToAnchor:self.contentView.centerXAnchor constant:30], 
            [tweakIcon.trailingAnchor constraintEqualToAnchor:tweakName.leadingAnchor constant:-10], 

            [tweakIcon.bottomAnchor constraintEqualToAnchor:tweakVersion.topAnchor constant:-8],
            [tweakName.topAnchor constraintLessThanOrEqualToAnchor:tweakIcon.topAnchor], 
            [tweakName.bottomAnchor constraintGreaterThanOrEqualToAnchor:tweakIcon.bottomAnchor],

            [tweakVersion.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],   
            [tweakVersion.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor constant:29],
        ]];
    }

    return self;
}

- (void)setSeparatorStyle:(UITableViewCellSeparatorStyle)style {
    [super setSeparatorStyle:UITableViewCellSeparatorStyleNone];
}

- (void)setBackgroundColor:(UIColor *)color {
    [super setBackgroundColor:[UIColor clearColor]];
}

@end

@implementation POBSlider // delete this

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    [super endTrackingWithTouch:touch withEvent:event];
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.teslaman3092.popoutbuttonsprefs-updated"), nil, nil, true);
}

@end

// Thx flora - https://github.com/acquitelol/flora/blob/main/Preferences/Cells/FloraSliderCell.m , also thx 16Player
@implementation POBSliderCell {
    NSUserDefaults *_preferences;
    UISlider *_slider;
    UITextField *_numLabel;
    NSString *_preferencesKey;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)identifier specifier:(PSSpecifier *)specifier {
    self = [super initWithStyle:style reuseIdentifier:identifier specifier:specifier];

    if (self) {
        _preferences = [[NSUserDefaults alloc] initWithSuiteName:@"com.teslaman3092.popoutbuttonsprefs"];

        if ([specifier propertyForKey:@"postRedularNotif"] != nil && [[specifier propertyForKey:@"postRedularNotif"] boolValue]) {
            self.shouldSendNormalNotifForUpdate = YES;
        }
        
        _preferencesKey = [specifier propertyForKey:@"key"];

        const id specifierPrefKeyValue = [_preferences objectForKey:_preferencesKey];
        const double sliderNum = specifierPrefKeyValue ? [specifierPrefKeyValue floatValue] : [[specifier propertyForKey:@"default"] floatValue];

        _numLabel = [[UITextField alloc] initWithFrame:CGRectZero];
        _numLabel.text = [self formatFloat:sliderNum];
        _numLabel.textAlignment = NSTextAlignmentRight;
        _numLabel.textColor = [UIColor grayColor];
        _numLabel.font = [UIFont systemFontOfSize:15.0];
        _numLabel.keyboardType = UIKeyboardTypeDecimalPad;
        _numLabel.delegate = self;
        [_numLabel addTarget:self action:@selector(didEditNumLabel) forControlEvents:UIControlEventEditingChanged];
        [self.contentView addSubview:_numLabel];

        _slider = [[POBSlider alloc] initWithFrame:CGRectZero];
        _slider.minimumValue = [[specifier propertyForKey:@"min"] floatValue];
        _slider.maximumValue = [[specifier propertyForKey:@"max"] floatValue];
        _slider.continuous = YES;
        [_slider addTarget:self action:@selector(didChangeSlider) forControlEvents:UIControlEventValueChanged];

        if (![specifier propertyForKey:@"enabled"] == NO) { // don't ask
            _slider.enabled = NO;
        }

        [self.contentView addSubview:_slider];
        [_slider setValue:sliderNum];

        if ([specifier propertyForKey:@"iconImageSystem"]) {
            NSDictionary *const iconImageSystem = [specifier propertyForKey:@"iconImageSystem"];
            _slider.minimumValueImage = [[UIImage systemImageNamed:[iconImageSystem objectForKey:@"name"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        }
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    }

    return self;
}

- (void)didChangeSlider {
    CGFloat const currentSliderValue = _slider.value;
    _numLabel.text = [self formatFloat:currentSliderValue];
    if(self.shouldSendNormalNotifForUpdate){
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.teslaman3092.popoutbuttonsprefs-updated"), nil, nil, true);
    }else{
        [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"com.teslaman3092.popoutbuttons-updatePopoutsWithValues" object:nil userInfo:@{@"key" : _preferencesKey, @"value" : @(currentSliderValue) }];
    }
    [_preferences setObject:[self formatFloat:_slider.value] forKey:self.specifier.properties[@"key"]];
}

- (void)didEditNumLabel {
    NSString *const numTextValue = _numLabel.text;
    CGFloat const newSliderValue = ([numTextValue floatValue] < [[self.specifier propertyForKey:@"max"] floatValue]) ? [numTextValue floatValue] : [[self.specifier propertyForKey:@"max"] floatValue];
    [_slider setValue:newSliderValue animated:YES];
    if(self.shouldSendNormalNotifForUpdate){
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.teslaman3092.popoutbuttonsprefs-updated"), nil, nil, true);
    }else{
        [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"com.teslaman3092.popoutbuttons-updatePopoutsWithValues" object:nil userInfo:@{@"key" : _preferencesKey, @"value" : @(newSliderValue) }];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat const numLabelWidth = 35;
    CGFloat const numLabelX = self.contentView.bounds.size.width - numLabelWidth - 16.0;
    _numLabel.frame = CGRectMake(numLabelX, 0, numLabelWidth, self.contentView.bounds.size.height);

    CGFloat const sliderWidth = numLabelX - 16 - 8.0;
    CGFloat const sliderY = (self.contentView.bounds.size.height - 31)/2.0;
    _slider.frame = CGRectMake(16, sliderY, sliderWidth, 31);
}

- (NSString *) formatFloat:(CGFloat)number {
    NSString *newLabelValue = number > 99 ? [NSString stringWithFormat:@"%.0f", number] : [NSString stringWithFormat:@"%.1f", number];

    if (number > 99) {
        newLabelValue = [NSString stringWithFormat:@"%.0f", number];
    } else if(number > 9) {
        newLabelValue = [NSString stringWithFormat:@"%.1f", number];
    } else if (number > 1) {
        newLabelValue = [NSString stringWithFormat:@"%.2f", number];
    } else if (number > -1) {
        newLabelValue = [NSString stringWithFormat:@"%.1f", number];
    } else if (number < -10) {
        newLabelValue = [NSString stringWithFormat:@"%.0f", number];
    }

    return newLabelValue;
}

- (UILabel *)detailTextLabel { 
    return nil;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    NSString *const textInputValue = _numLabel.text;
    CGFloat const textNumValue = [textInputValue floatValue];
    CGFloat const maxCheckedValue = (textNumValue < [[self.specifier propertyForKey:@"max"] floatValue]) ? textNumValue : [[self.specifier propertyForKey:@"max"] floatValue];;
    CGFloat const minMaxCheckedValue = (maxCheckedValue > [[self.specifier propertyForKey:@"min"] floatValue]) ? maxCheckedValue : [[self.specifier propertyForKey:@"min"] floatValue];

    _numLabel.text = [self formatFloat:minMaxCheckedValue];
    [_numLabel resignFirstResponder];
    [_preferences setObject:[NSString stringWithFormat:@"%.1f", minMaxCheckedValue] forKey:self.specifier.properties[@"key"]];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [textField selectAll:nil];
}

@end 