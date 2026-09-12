#import "HBTPrefsHeaderView.h"

static const CGFloat kHBTIconSide   = 96.0;
static const CGFloat kHBTPadTop     = 24.0;
static const CGFloat kHBTIconToName = 12.0;
static const CGFloat kHBTPadBottom  = 20.0;

@implementation HBTPrefsHeaderView {
    UIImageView *_iconView;
    UILabel *_titleLabel;
}

- (instancetype)initWithTitle:(NSString *)title {
    self = [super initWithFrame:CGRectZero];
    if (!self) return nil;

    UIImage *icon = [UIImage imageNamed:@"HeaderIcon"
                               inBundle:[NSBundle bundleForClass:self.class]
          compatibleWithTraitCollection:nil];
    _iconView = [[UIImageView alloc] initWithImage:icon];
    _iconView.contentMode = UIViewContentModeScaleAspectFit;
    _iconView.layer.cornerRadius = kHBTIconSide * 0.22;
    _iconView.layer.masksToBounds = YES;
    [self addSubview:_iconView];

    _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _titleLabel.text = title;
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    _titleLabel.textColor = UIColor.labelColor;
    _titleLabel.font = [UIFont systemFontOfSize:22 weight:UIFontWeightBold];
    [self addSubview:_titleLabel];

    return self;
}

- (CGSize)sizeThatFits:(CGSize)size {
    CGFloat height = kHBTPadTop + kHBTIconSide + kHBTIconToName;
    height += [_titleLabel sizeThatFits:CGSizeMake(size.width, CGFLOAT_MAX)].height;
    return CGSizeMake(size.width, height + kHBTPadBottom);
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat width = self.bounds.size.width;

    CGRect iconRect = CGRectMake((width - kHBTIconSide) / 2.0, kHBTPadTop, kHBTIconSide, kHBTIconSide);
    _iconView.frame = iconRect;

    CGFloat y = CGRectGetMaxY(iconRect) + kHBTIconToName;
    CGFloat titleHeight = [_titleLabel sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)].height;
    _titleLabel.frame = CGRectMake(0, y, width, titleHeight);
}

@end
