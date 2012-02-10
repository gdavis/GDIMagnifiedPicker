//
//  GDIMagnifiedPickerView.h
//  GDIMagnifiedPicker
//
//  Created by Grant Davis on 2/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GDITouchProxyView.h"
#import "GDIMagnifiedPickerCell.h"

@protocol GDIMagnifiedPickerViewDataSource, GDIMagnifiedPickerViewDelegate;

@interface GDIMagnifiedPickerView : UIView <GDITouchProxyViewDelegate>

@property (strong,nonatomic) NSObject<GDIMagnifiedPickerViewDataSource> *dataSource;
@property (strong,nonatomic) NSObject<GDIMagnifiedPickerViewDelegate> *delegate;
@property (nonatomic) CGFloat friction;
@property (nonatomic) NSInteger currentIndex;
@property (strong,nonatomic) UIView *selectionBackgroundView;
- (NSArray *)visibleRows;
- (void)reloadData;
- (GDIMagnifiedPickerCell *)dequeueCellWithType:(GDIMagnifiedPickerCellType)type;

@end


@protocol GDIMagnifiedPickerViewDataSource

@required
- (NSUInteger)numberOfRowsInMagnifiedPickerView:(GDIMagnifiedPickerView*)pickerView;
- (CGFloat)heightForRowsInMagnifiedPickerView:(GDIMagnifiedPickerView *)pickerView;
- (CGFloat)heightForMagnificationViewInMagnifiedPickerView:(GDIMagnifiedPickerView *)pickerView;
- (GDIMagnifiedPickerCell *)magnifiedPickerView:(GDIMagnifiedPickerView *)pickerView cellForRowType:(GDIMagnifiedPickerCellType)type atRowIndex:(NSUInteger)rowIndex;

@end



@protocol GDIMagnifiedPickerViewDelegate

- (void)magnifiedPickerView:(GDIMagnifiedPickerView *)pickerView didSelectRowAtIndex:(NSUInteger)rowIndex;

@end