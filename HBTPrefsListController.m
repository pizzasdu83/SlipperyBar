#import "HBTPrefsListController.h"
#import "HBTPrefsHeaderView.h"
#import <Preferences/PSSpecifier.h>

@interface HBTPrefsListController ()
@property (nonatomic, strong) HBTPrefsHeaderView *hbtHeaderView;
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
    self.hbtHeaderView = [[HBTPrefsHeaderView alloc] initWithTitle:@"Slippery Bar"];
    self.table.tableHeaderView = self.hbtHeaderView;
    [self hbtUpdateGithubIconForTraitCollection:self.traitCollection];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self hbtUpdateGithubIconForTraitCollection:self.traitCollection];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            [self hbtUpdateGithubIconForTraitCollection:self.traitCollection];
        }
    }
}

// Swaps the "Source Code" row icon between github.png (light) and
// nogithub.png (dark, white version) depending on the system appearance.
- (void)hbtUpdateGithubIconForTraitCollection:(UITraitCollection *)traitCollection {
    BOOL isDark = NO;
    if (@available(iOS 13.0, *)) {
        isDark = (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark);
    }
    NSString *iconName = isDark ? @"nogithub.png" : @"github.png";

    for (PSSpecifier *specifier in self.specifiers) {
        if ([[specifier propertyForKey:@"label"] isEqualToString:@"Source Code"]) {
            NSString *currentIcon = [specifier propertyForKey:@"icon"];
            if (![currentIcon isEqualToString:iconName]) {
                [specifier setProperty:iconName forKey:@"icon"];
                [self.table reloadData];
            }
            break;
        }
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    UITableView *table = self.table;
    if (table.tableHeaderView != self.hbtHeaderView) return;

    CGFloat width = table.bounds.size.width;
    if (width <= 0.0) return;
    CGFloat height = [self.hbtHeaderView sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)].height;
    CGRect frame = self.hbtHeaderView.frame;
    if (fabs(frame.size.width - width) > 0.5 || fabs(frame.size.height - height) > 0.5) {
        self.hbtHeaderView.frame = CGRectMake(0.0, 0.0, width, height);
        table.tableHeaderView = self.hbtHeaderView;
    }
}

- (void)openSourceRepository {
    NSURL *url = [NSURL URLWithString:@"https://github.com/pizzasdu83/SlipperyBar"];
    if (url) [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    NSIndexPath *selected = self.table.indexPathForSelectedRow;
    if (selected) [self.table deselectRowAtIndexPath:selected animated:YES];
}

- (void)openButterfly {
    NSURL *url = [NSURL URLWithString:@"https://youtu.be/dtCZMge7oHQ"];
    if (url) [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    NSIndexPath *selected = self.table.indexPathForSelectedRow;
    if (selected) [self.table deselectRowAtIndexPath:selected animated:YES];
}

- (void)openMeInHalf {
    NSURL *url = [NSURL URLWithString:@"https://discord.gg/e4zY6NrX"];
    if (url) [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    NSIndexPath *selected = self.table.indexPathForSelectedRow;
    if (selected) [self.table deselectRowAtIndexPath:selected animated:YES];
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