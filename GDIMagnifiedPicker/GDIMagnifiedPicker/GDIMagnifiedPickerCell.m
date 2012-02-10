//
//  GDIMagnifiedPickerCell.m
//  GDIMagnifiedPicker
//
//  Created by Grant Davis on 2/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GDIMagnifiedPickerCell.h"

@implementation GDIMagnifiedPickerCell
@synthesize label = _label;
@synthesize cellType = _cellType;

- (id)initWithFrame:(CGRect)frame cellType:(GDIMagnifiedPickerCellType)type
{
    self = [self initWithFrame:frame];
    if (self) {
        _cellType = type;
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        // settings for performance optimization
        self.clearsContextBeforeDrawing = NO;
        self.clipsToBounds = YES;
        self.autoresizesSubviews = NO;
        
        _label = [[UILabel alloc] initWithFrame:self.bounds];
        [self addSubview:_label];
    }
    return self;
}

@end
