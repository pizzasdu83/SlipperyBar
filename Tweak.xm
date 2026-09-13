#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
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

static CGFloat HBTReadChannel(CFStringRef key, CGFloat fallback) {
    CFPropertyListRef ref = CFPreferencesCopyAppValue(key, HBT_DOMAIN);
    if (!ref) return fallback;
    CGFloat value = [(__bridge id)ref floatValue];
    CFRelease(ref);
    return value;
}

// Returns nil if the string isn't a valid 6-digit hex color, so callers can
// fall back to the RGB sliders instead.
static UIColor *HBTColorFromHex(NSString *hex) {
    if (!hex) return nil;
    NSString *s = [hex stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([s hasPrefix:@"#"]) s = [s substringFromIndex:1];
    if (s.length != 6) return nil;
    unsigned int rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:s];
    if (![scanner scanHexInt:&rgbValue] || !scanner.isAtEnd) return nil;
    CGFloat r = ((rgbValue & 0xFF0000) >> 16) / 255.0f;
    CGFloat g = ((rgbValue & 0x00FF00) >> 8) / 255.0f;
    CGFloat b = (rgbValue & 0x0000FF) / 255.0f;
    return [UIColor colorWithRed:r green:g blue:b alpha:1.0f];
}

static UIColor *HBTReadColor(CFStringRef hexKey, CFStringRef rKey, CFStringRef gKey,
                              CFStringRef bKey, CGFloat rDefault, CGFloat gDefault, CGFloat bDefault) {
    CFPropertyListRef hexRef = CFPreferencesCopyAppValue(hexKey, HBT_DOMAIN);
    UIColor *fromHex = hexRef ? HBTColorFromHex((__bridge NSString *)hexRef) : nil;
    if (hexRef) CFRelease(hexRef);
    if (fromHex) return fromHex;

    return [UIColor colorWithRed:HBTReadChannel(rKey, rDefault) / 255.0f
                            green:HBTReadChannel(gKey, gDefault) / 255.0f
                             blue:HBTReadChannel(bKey, bDefault) / 255.0f
                            alpha:1.0f];
}

static void HBTLoadPrefs(void) {
    CFPreferencesAppSynchronize(HBT_DOMAIN);

    CFPropertyListRef enabledRef = CFPreferencesCopyAppValue(CFSTR("Enabled"), HBT_DOMAIN);
    hbtEnabled = enabledRef ? [(__bridge id)enabledRef boolValue] : YES;
    if (enabledRef) CFRelease(enabledRef);

    CFPropertyListRef gradRef = CFPreferencesCopyAppValue(CFSTR("GradientEnabled"), HBT_DOMAIN);
    hbtIsGradient = gradRef ? [(__bridge id)gradRef boolValue] : NO;
    if (gradRef) CFRelease(gradRef);

    hbtColor1 = HBTReadColor(CFSTR("Color1Hex"), CFSTR("Color1R"), CFSTR("Color1G"), CFSTR("Color1B"), 255, 255, 255);
    hbtColor2 = HBTReadColor(CFSTR("Color2Hex"), CFSTR("Color2R"), CFSTR("Color2G"), CFSTR("Color2B"), 0, 122, 255);

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
        // Restore whatever native rendering subviews draw the stock pill.
        for (UIView *sub in pillView.subviews) sub.hidden = NO;
        return;
    }
    if (!overlay) {
        overlay = [CAGradientLayer layer];
        overlay.cornerRadius = pillView.layer.cornerRadius;
        overlay.opacity = 0.0f;
        [pillView.layer addSublayer:overlay];
        objc_setAssociatedObject(pillView, HBTOverlayKey, overlay, OBJC_ASSOCIATION_RETAIN);
        // Fade in rather than cutting straight to full color, closer to how
        // the system's own home indicator eases into view.
        CABasicAnimation *fadeIn = [CABasicAnimation animationWithKeyPath:@"opacity"];
        fadeIn.fromValue = @0.0;
        fadeIn.toValue = @1.0;
        fadeIn.duration = 0.25;
        fadeIn.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
        [overlay addAnimation:fadeIn forKey:@"hbtFadeIn"];
    }
    overlay.opacity = 1.0f;
    overlay.hidden = NO;
    // Force front-most regardless of when/how native content gets (re)added to
    // this layer on subsequent layout passes.
    overlay.zPosition = 1000;

    // Hide the native pill's own rendering subviews (whatever their class),
    // rather than only painting over them - otherwise the stock white/adaptive
    // pill stays visible underneath until its own fade-out finishes. These are
    // purely cosmetic child views; SBHomeGrabberView itself (not these
    // children) is what handles the system gesture, so hiding them is safe.
    for (UIView *sub in pillView.subviews) sub.hidden = YES;

    // SAFETY: never trust pillView.bounds directly. On-device, the hooked view
    // can temporarily grow far beyond the visible pill (e.g. to host a larger
    // touch-catching area for system gestures). If we ever painted that full
    // area, it would blank out whatever is behind it - including foreground
    // app content. So we always compute a small pill-shaped rect ourselves,
    // anchored at the bottom-center of whatever bounds we're given, capped at
    // a sane maximum size, and never larger than the view actually is.
    CGFloat maxPillWidth = 140.0f;
    CGFloat pillHeight = 5.0f;
    CGFloat viewW = pillView.bounds.size.width;
    CGFloat viewH = pillView.bounds.size.height;
    CGFloat w = MIN(maxPillWidth, viewW);
    CGFloat h = MIN(pillHeight, viewH);
    CGRect safeRect = CGRectMake((viewW - w) * 0.5f, MAX(0, viewH - h - 8.0f), w, h);

    overlay.frame = safeRect;
    overlay.cornerRadius = h * 0.5f;

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

// ---- Track every live pill view so a polling fallback can re-apply colors
// even if the darwin notification never reaches SpringBoard (this device's
// SpringBoard log shows libSandy sandbox-extension issues, so cross-process
// notifications from a sandboxed Settings/TweakSettings process are not
// guaranteed to arrive). Weak references so we never keep a dead view alive.
static NSHashTable<UIView *> *hbtTrackedViews;

static void HBTTrackView(UIView *pillView) {
    if (!hbtTrackedViews) {
        hbtTrackedViews = [NSHashTable weakObjectsHashTable];
    }
    [hbtTrackedViews addObject:pillView];
}

// ---- Known hook target, confirmed present via on-device classdump ----
@interface SBHomeGrabberView : UIView
@end

%hook SBHomeGrabberView

- (void)layoutSubviews {
    %orig;
    HBTTrackView(self);
    HBTApplyOverlay(self);
}

- (void)didMoveToWindow {
    %orig;
    if (self.window) {
        HBTTrackView(self);
        HBTApplyOverlay(self);
    }
}

%end

// ---- Mirror the native view's own opacity onto our overlay every frame, so
// fades (inactivity dimming, hiding during video/Face ID, etc.) carry over.
// We only copy opacity - shape/position is still handled by HBTApplyOverlay.
@interface HBTDisplayLinkTarget : NSObject
@end

@implementation HBTDisplayLinkTarget

- (void)hbtTick:(CADisplayLink *)link {
    for (UIView *v in hbtTrackedViews) {
        CAGradientLayer *overlay = objc_getAssociatedObject(v, HBTOverlayKey);
        if (!overlay || overlay.hidden) continue;
        CALayer *presentation = v.layer.presentationLayer;
        overlay.opacity = presentation ? presentation.opacity : v.layer.opacity;
    }
}

@end

static HBTDisplayLinkTarget *hbtDisplayLinkTarget;

static void HBTReloadCallback(CFNotificationCenterRef center, void *observer,
                               CFStringRef name, const void *object,
                               CFDictionaryRef userInfo) {
    HBTLoadPrefs();
    // Force a re-layout pass on any live pill views next runloop turn.
}

static void HBTPollTick(CFRunLoopTimerRef timer, void *info) {
    HBTLoadPrefs();
    for (UIView *v in hbtTrackedViews) {
        HBTApplyOverlay(v);
    }
}

%ctor {
    HBTLoadPrefs();
    HBTDumpCandidateClasses();
    CFNotificationCenterAddObserver(
        CFNotificationCenterGetDarwinNotifyCenter(),
        NULL, HBTReloadCallback, CFSTR(HBT_NOTIFY), NULL,
        CFNotificationSuspensionBehaviorDeliverImmediately);

    // Fallback path: re-check preferences once a second regardless of whether
    // the darwin notification made it across. Cheap (a couple of CFPreferences
    // reads) and immune to sandbox/IPC issues that can drop the notification.
    CFRunLoopTimerRef pollTimer = CFRunLoopTimerCreate(
        kCFAllocatorDefault, CFAbsoluteTimeGetCurrent(), 1.0, 0, 0,
        HBTPollTick, NULL);
    CFRunLoopAddTimer(CFRunLoopGetMain(), pollTimer, kCFRunLoopCommonModes);

    // Per-frame opacity mirror (see HBTDisplayLinkTarget above).
    hbtDisplayLinkTarget = [HBTDisplayLinkTarget new];
    CADisplayLink *link = [CADisplayLink displayLinkWithTarget:hbtDisplayLinkTarget
                                                       selector:@selector(hbtTick:)];
    [link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}
