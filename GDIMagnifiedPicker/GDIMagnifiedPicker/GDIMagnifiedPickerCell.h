//
//  GDIMagnifiedPickerCell.h
//  GDIMagnifiedPicker
//
//  Created by Grant Davis on 2/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum GDIMagnifiedPickerCellType {
    GDIMagnifiedPickerCellTypeStandard = 0,
    GDIMagnifiedPickerCellTypeMagnified
} GDIMagnifiedPickerCellType;

@interface GDIMagnifiedPickerCell : UIView

@property (strong, nonatomic, readonly) UILabel *label;
@property (nonatomic) GDIMagnifiedPickerCellType cellType;

- (id)initWithFrame:(CGRect)frame cellType:(GDIMagnifiedPickerCellType)type;

@end
