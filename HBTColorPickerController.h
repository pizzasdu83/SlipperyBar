#import <UIKit/UIKit.h>

@interface HBTColorPickerController : UIColorPickerViewController
- (instancetype)initWithColor:(UIColor *)color onPick:(void (^)(UIColor *picked))onPick;
@end
