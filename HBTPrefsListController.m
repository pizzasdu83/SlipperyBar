#import "HBTPrefsListController.h"
#import "HBTColorPickerController.h"
#import <Preferences/PSSpecifier.h>

#define HBT_SUITE @"com.pizzasdu83.homebartint"
#define HBT_NOTIFY CFSTR("com.pizzasdu83.homebartint/reload")

@implementation HBTPrefsListController

- (NSArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
    }
    return _specifiers;
}

- (void)hbtPostReload {
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:HBT_SUITE];
    [defaults synchronize];
    CFNotificationCenterPostNotification(
        CFNotificationCenterGetDarwinNotifyCenter(), HBT_NOTIFY, NULL, NULL, YES);
}

- (void)hbtPresentPickerForKey:(NSString *)key defaultColor:(UIColor *)fallback {
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:HBT_SUITE];
    NSString *stored = [defaults stringForKey:key];
    UIColor *current = fallback;
    if (stored) {
        NSArray<NSString *> *p = [stored componentsSeparatedByString:@","];
        if (p.count == 4) {
            current = [UIColor colorWithRed:p[0].floatValue green:p[1].floatValue
                                        blue:p[2].floatValue alpha:p[3].floatValue];
        }
    }

    __weak HBTPrefsListController *weakSelf = self;
    HBTColorPickerController *picker = [[HBTColorPickerController alloc] initWithColor:current
        onPick:^(UIColor *picked) {
            CGFloat r, g, b, a;
            [picked getRed:&r green:&g blue:&b alpha:&a];
            NSString *encoded = [NSString stringWithFormat:@"%f,%f,%f,%f", r, g, b, a];
            NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:HBT_SUITE];
            [d setObject:encoded forKey:key];
            [d synchronize];
            [weakSelf hbtPostReload];
        }];
    [self.navigationController pushViewController:picker animated:YES];
}

- (void)hbtPickColor1 {
    [self hbtPresentPickerForKey:@"Color1" defaultColor:[UIColor whiteColor]];
}

- (void)hbtPickColor2 {
    [self hbtPresentPickerForKey:@"Color2" defaultColor:[UIColor systemBlueColor]];
}

@end
