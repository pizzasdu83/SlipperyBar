#import "HBTColorPickerController.h"

@interface HBTColorPickerController () <UIColorPickerViewControllerDelegate>
@property (nonatomic, copy) void (^onPick)(UIColor *picked);
@end

@implementation HBTColorPickerController

- (instancetype)initWithColor:(UIColor *)color onPick:(void (^)(UIColor *picked))onPick {
    self = [super init];
    if (self) {
        self.selectedColor = color;
        self.supportsAlpha = YES;
        self.delegate = self;
        self.onPick = onPick;
        self.title = @"Choose Color";
    }
    return self;
}

// Live preview while the user drags in the picker.
- (void)colorPickerViewController:(UIColorPickerViewController *)viewController
           didSelectColor:(UIColor *)color {
    if (self.onPick) self.onPick(color);
}

// Final value when the picker is dismissed / navigated away from.
- (void)colorPickerViewControllerDidFinish:(UIColorPickerViewController *)viewController {
    if (self.onPick) self.onPick(self.selectedColor);
}

@end
