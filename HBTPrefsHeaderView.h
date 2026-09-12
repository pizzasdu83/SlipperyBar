#import <UIKit/UIKit.h>

// Icon and title shown above the first group of the settings page — a simple,
// static version of the "app header" pattern (no tap/animation, unlike more
// elaborate versions of this idea).
@interface HBTPrefsHeaderView : UIView

- (instancetype)initWithTitle:(NSString *)title;

@end
