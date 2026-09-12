#import "HBTPrefsListController.h"
#import "HBTPrefsHeaderView.h"

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

@end
