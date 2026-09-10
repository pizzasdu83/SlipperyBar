#import <UIKit/UIKit.h>
#import <CoreFoundation/CoreFoundation.h>
#import <objc/runtime.h>

#define HBT_DOMAIN CFSTR("com.pizzasdu83.homebartint")
#define HBT_NOTIFY "com.pizzasdu83.homebartint/reload"
#define HBT_LOGPATH @"/var/mobile/Documents/HomeBarTint-classdump.txt"

// ---- Preference state (refreshed on darwin notification) ----
static BOOL hbtEnabled = YES;
static BOOL hbtIsGradient = NO;
static UIColor *hbtColor1;
static UIColor *hbtColor2;
static CGFloat hbtAngleDegrees = 0.0f;

static UIColor *HBTColorFromString(NSString *s, UIColor *fallback) {
    if (!s) return fallback;
    NSArray<NSString *> *parts = [s componentsSeparatedByString:@","];
    if (parts.count != 4) return fallback;
    CGFloat r = parts[0].floatValue, g = parts[1].floatValue,
            b = parts[2].floatValue, a = parts[3].floatValue;
    return [UIColor colorWithRed:r green:g blue:b alpha:a];
}

static void HBTLoadPrefs(void) {
    CFPreferencesAppSynchronize(HBT_DOMAIN);

    CFPropertyListRef enabledRef = CFPreferencesCopyAppValue(CFSTR("Enabled"), HBT_DOMAIN);
    hbtEnabled = enabledRef ? [(__bridge id)enabledRef boolValue] : YES;
    if (enabledRef) CFRelease(enabledRef);

    CFPropertyListRef modeRef = CFPreferencesCopyAppValue(CFSTR("Mode"), HBT_DOMAIN);
    NSString *mode = modeRef ? (__bridge NSString *)modeRef : @"solid";
    hbtIsGradient = [mode isEqualToString:@"gradient"];
    if (modeRef) CFRelease(modeRef);

    CFPropertyListRef c1Ref = CFPreferencesCopyAppValue(CFSTR("Color1"), HBT_DOMAIN);
    hbtColor1 = HBTColorFromString(c1Ref ? (__bridge NSString *)c1Ref : nil, [UIColor whiteColor]);
    if (c1Ref) CFRelease(c1Ref);

    CFPropertyListRef c2Ref = CFPreferencesCopyAppValue(CFSTR("Color2"), HBT_DOMAIN);
    hbtColor2 = HBTColorFromString(c2Ref ? (__bridge NSString *)c2Ref : nil, [UIColor systemBlueColor]);
    if (c2Ref) CFRelease(c2Ref);

    CFPropertyListRef angleRef = CFPreferencesCopyAppValue(CFSTR("Angle"), HBT_DOMAIN);
    hbtAngleDegrees = angleRef ? [(__bridge id)angleRef floatValue] : 0.0f;
    if (angleRef) CFRelease(angleRef);
}

// Converts an angle in degrees to CAGradientLayer start/end points (unit square).
static void HBTGradientPointsForAngle(CGFloat degrees, CGPoint *start, CGPoint *end) {
    CGFloat radians = degrees * (CGFloat)M_PI / 180.0f;
    CGFloat dx = cosf(radians), dy = sinf(radians);
    *start = CGPointMake(0.5f - dx * 0.5f, 0.5f - dy * 0.5f);
    *end   = CGPointMake(0.5f + dx * 0.5f, 0.5f + dy * 0.5f);
}

// ---- Overlay that paints the pill shape ----
static const void *HBTOverlayKey = &HBTOverlayKey;

static void HBTApplyOverlay(UIView *pillView) {
    if (!pillView) return;

    CAGradientLayer *overlay = objc_getAssociatedObject(pillView, HBTOverlayKey);
    if (!hbtEnabled) {
        overlay.hidden = YES;
        return;
    }
    if (!overlay) {
        overlay = [CAGradientLayer layer];
        overlay.cornerRadius = pillView.layer.cornerRadius;
        [pillView.layer addSublayer:overlay];
        objc_setAssociatedObject(pillView, HBTOverlayKey, overlay, OBJC_ASSOCIATION_RETAIN);
    }
    overlay.hidden = NO;
    overlay.frame = pillView.bounds;
    overlay.cornerRadius = pillView.layer.cornerRadius;

    if (hbtIsGradient) {
        overlay.colors = @[(id)hbtColor1.CGColor, (id)hbtColor2.CGColor];
        CGPoint start, end;
        HBTGradientPointsForAngle(hbtAngleDegrees, &start, &end);
        overlay.startPoint = start;
        overlay.endPoint = end;
    } else {
        overlay.colors = @[(id)hbtColor1.CGColor, (id)hbtColor1.CGColor];
        overlay.startPoint = CGPointMake(0, 0.5f);
        overlay.endPoint = CGPointMake(1, 0.5f);
    }
}

// ---- Diagnostic: dump candidate class names once at launch ----
static void HBTDumpCandidateClasses(void) {
    int count = objc_getClassList(NULL, 0);
    Class *classes = (Class *)malloc(sizeof(Class) * (unsigned long)count);
    count = objc_getClassList(classes, count);
    NSMutableString *log = [NSMutableString string];
    for (int i = 0; i < count; i++) {
        NSString *name = NSStringFromClass(classes[i]);
        if ([name rangeOfString:@"Home" options:NSCaseInsensitiveSearch].location != NSNotFound &&
            ([name rangeOfString:@"Grabber"].location != NSNotFound ||
             [name rangeOfString:@"Affordance"].location != NSNotFound ||
             [name rangeOfString:@"Indicator"].location != NSNotFound ||
             [name rangeOfString:@"Pill"].location != NSNotFound)) {
            [log appendFormat:@"%@\n", name];
        }
    }
    free(classes);
    [log writeToFile:HBT_LOGPATH atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

// ---- Known hook target (may not exist on all iOS versions - safe no-op if absent) ----
%hook SBHomeGrabberView

- (void)layoutSubviews {
    %orig;
    HBTApplyOverlay(self);
}

- (void)didMoveToWindow {
    %orig;
    if (self.window) HBTApplyOverlay(self);
}

%end

// Historically the actual pill drawing lives one level down; hook it too so the
// overlay sits above the luma-dodge blend view and fully replaces its color.
%hook MTLumaDodgePillView

- (void)layoutSubviews {
    %orig;
    HBTApplyOverlay(self.superview ?: self);
}

%end

static void HBTReloadCallback(CFNotificationCenterRef center, void *observer,
                               CFStringRef name, const void *object,
                               CFDictionaryRef userInfo) {
    HBTLoadPrefs();
    // Force a re-layout pass on any live pill views next runloop turn.
}

%ctor {
    HBTLoadPrefs();
    HBTDumpCandidateClasses();
    CFNotificationCenterAddObserver(
        CFNotificationCenterGetDarwinNotifyCenter(),
        NULL, HBTReloadCallback, CFSTR(HBT_NOTIFY), NULL,
        CFNotificationSuspensionBehaviorDeliverImmediately);
}
