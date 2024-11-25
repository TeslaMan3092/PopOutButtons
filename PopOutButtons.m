#import "Tweak.h"

@implementation POBShapeLayer

- (instancetype)init {
    self = [super init];

    if (self) {
        self.disableUpdateMask = (1 << 1) | (1 << 4); // Hide the popouts when you screen capture, Thx -> https://nsantoine.dev/posts/CALayerCaptureHiding
        
        NSDictionary *const prefs = [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.teslaman3092.popoutbuttonsprefs"];
        self.defaultLineWidth = [prefs objectForKey:@"globalBorderWidth"] ? [[prefs valueForKey:@"globalBorderWidth"] floatValue] : 0;
        self.strokeColor = [GcColorPickerUtils colorFromDefaults:@"com.teslaman3092.popoutbuttonsprefs" withKey:@"globalBorderColor" fallback:@"1a1a1a"].CGColor;
        self.lineWidth = 0;
    }

    return self;
}

- (void)updateStateWithShowing:(BOOL)showing {
    self.isShowing = showing;

    [self setBorderWithShowing:showing];

    CABasicAnimation *const animation = [CABasicAnimation animationWithKeyPath:@"path"];
    animation.fromValue = (__bridge id)self.path;
    animation.toValue = (__bridge id)(showing ? self.showingPath.CGPath : self.hidingPath.CGPath);
    animation.duration = showing ? 0.1 : 0.2;
    
    [self addAnimation:animation forKey:@"pathAnimation"];
    self.path = showing ? self.showingPath.CGPath : self.hidingPath.CGPath;
}

- (void)updatePathsWithFrame:(CGRect)frame hidden:(BOOL)startHidden { // path creator
    CGFloat const height = frame.size.height;
    CGFloat const oneThird = (height * (1.0 / 3.0)); // one third of the layer's/popout's height
    CGFloat const oneOneThird = oneThird * (1.0 / 4.0); // one third of the popouts height
    CGFloat const twoOneThird = oneThird * (3.0 / 4.0); // two thirds of the popouts height
    CGFloat const popOutTo = (self.isBackwards ? -5 : 5); // how far, or backwards, should the popouts pop out to
    CGFloat const curvedness = self.curvedness; // option for how smooth or curvy user wants the popouts to be
    CGFloat const endPointsX = (self.isBackwards ? 2 : -2);

    self.showingPath = [UIBezierPath bezierPath];
    [self.showingPath moveToPoint:CGPointMake(endPointsX, -20)];
    [self.showingPath addCurveToPoint:CGPointMake(popOutTo, oneThird) controlPoint1:CGPointMake(0 , oneThird/2 + curvedness) controlPoint2:CGPointMake(popOutTo, oneThird/2 - curvedness)];   
    [self.showingPath addLineToPoint:CGPointMake(popOutTo, height - oneThird)];
    [self.showingPath addCurveToPoint:CGPointMake(endPointsX, height + 20) controlPoint1:CGPointMake(popOutTo, height - oneThird/2 + curvedness) controlPoint2:CGPointMake(0, height - oneThird/2 - curvedness)];   
	[self.showingPath closePath];

    self.hidingPath = [UIBezierPath bezierPath];
    [self.hidingPath moveToPoint:CGPointMake(endPointsX, -5)];
    [self.hidingPath addCurveToPoint:CGPointMake(0, oneThird) controlPoint1:CGPointMake(0 , twoOneThird) controlPoint2:CGPointMake(0, oneOneThird)];   
    [self.hidingPath addLineToPoint:CGPointMake(0, height - oneThird)];
    [self.hidingPath addCurveToPoint:CGPointMake(endPointsX, height + 5) controlPoint1:CGPointMake(0, height - oneOneThird) controlPoint2:CGPointMake(0, height - twoOneThird)];
    [self.hidingPath closePath];

    self.path = (startHidden ? self.hidingPath.CGPath : self.showingPath.CGPath);
    if(!startHidden) [self setBorderWithShowing:YES];
    self.isShowing = !startHidden;
}

- (void)setFrame:(CGRect)frame {
    [self updatePathsWithFrame:frame hidden:(CGRectEqualToRect(frame, self.frame) ? NO : YES)];
    [super setFrame:frame];
}

- (void)removeBorderWithTimer:(NSTimer *)timer {
    self.lineWidth = 0;
}

- (void)setBorderWithShowing:(BOOL)showing{
    [self.waitToRemoveBorderTimer invalidate];
    self.waitToRemoveBorderTimer = nil;

    if(showing){
        self.speed = 4;
        self.lineWidth = self.defaultLineWidth;
        self.speed = 1;
    }else{
        self.waitToRemoveBorderTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(removeBorderWithTimer:) userInfo:nil repeats:NO];
    }
}

@end

@implementation UIDevice (PopOutButtons) // Thx Nightwind. Gives the device ID which corresponds to Y values/offsets for the popouts

+ (NSString *)_pob_deviceMachine {
    struct utsname systemInfo;
    const int success = uname(&systemInfo);
    if (success == -1) {
        return nil;
    }
    return [NSString stringWithUTF8String:systemInfo.machine];
}

@end