#import "HBTPrefsListController.h"
#import <SlipperyUIKit/SlipperyPrefsHeaderView.h>
#import <SlipperyUIKit/SlipperyPrefsFooterView.h>
#import <SlipperyUIKit/SlipperyLink.h>

@interface HBTPrefsListController ()
@property (nonatomic, strong) SlipperyPrefsHeaderView *hbtHeaderView;
@property (nonatomic, strong) SlipperyPrefsFooterView *hbtFooterView;
@end

@implementation HBTPrefsListController

- (NSArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
    }
    return _specifiers;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    NSBundle *bundle = [NSBundle bundleForClass:self.class];

    self.hbtHeaderView = [[SlipperyPrefsHeaderView alloc] initWithTitle:@"Slippery Bar"
                                                                iconName:@"HeaderIcon"
                                                                  bundle:bundle];
    self.table.tableHeaderView = self.hbtHeaderView;

    self.hbtFooterView = [SlipperyPrefsFooterView standardFooterView];
    self.table.tableFooterView = self.hbtFooterView;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    UITableView *table = self.table;
    CGFloat width = table.bounds.size.width;
    if (width <= 0.0) return;

    if (table.tableHeaderView == self.hbtHeaderView) {
        CGFloat height = [self.hbtHeaderView sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)].height;
        CGRect frame = self.hbtHeaderView.frame;
        if (fabs(frame.size.width - width) > 0.5 || fabs(frame.size.height - height) > 0.5) {
            self.hbtHeaderView.frame = CGRectMake(0.0, 0.0, width, height);
            table.tableHeaderView = self.hbtHeaderView;
        }
    }

    if (table.tableFooterView == self.hbtFooterView) {
        CGFloat height = [self.hbtFooterView sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)].height;
        CGRect frame = self.hbtFooterView.frame;
        if (fabs(frame.size.width - width) > 0.5 || fabs(frame.size.height - height) > 0.5) {
            self.hbtFooterView.frame = CGRectMake(0.0, 0.0, width, height);
            table.tableFooterView = self.hbtFooterView;
        }
    }
}

- (void)confirmResetSettings {
    NSIndexPath *selected = self.table.indexPathForSelectedRow;
    if (selected) [self.table deselectRowAtIndexPath:selected animated:YES];

    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:@"Reset All Settings?"
        message:@"This restores Slippery Bar to its default colors, opacity and mode."
        preferredStyle:UIAlertControllerStyleAlert];

    __weak HBTPrefsListController *weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Reset" style:UIAlertActionStyleDestructive
        handler:^(UIAlertAction *action) {
            [weakSelf hbtPerformReset];
        }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)hbtPerformReset {
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.pizzasdu83.homebartint"];
    NSArray<NSString *> *keys = @[
        @"Enabled", @"GradientEnabled",
        @"Color1R", @"Color1G", @"Color1B", @"Color1Hex",
        @"Color2R", @"Color2G", @"Color2B", @"Color2Hex",
        @"Angle", @"NormalOpacity", @"DimmedOpacity", @"BarWidth",
    ];
    for (NSString *key in keys) [defaults removeObjectForKey:key];
    [defaults synchronize];

    CFNotificationCenterPostNotification(
        CFNotificationCenterGetDarwinNotifyCenter(),
        CFSTR("com.pizzasdu83.homebartint/reload"), NULL, NULL, YES);

    // Force this page to rebuild its rows from scratch so the sliders/switches
    // reflect the restored defaults immediately instead of stale values.
    _specifiers = nil;
    [self reloadSpecifiers];
}

@end
