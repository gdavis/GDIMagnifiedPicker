//
//  GDIMagnifiedPickerView.h
//  GDIMagnifiedPicker
//
//  Created by Grant Davis on 2/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol GDIMagnifiedPickerViewDataSource, GDIMagnifiedPickerViewDelegate;

@interface GDIMagnifiedPickerView : UIView <UIScrollViewDelegate>

@property (strong,nonatomic) NSObject<GDIMagnifiedPickerViewDataSource> *dataSource;
@property (strong,nonatomic) NSObject<GDIMagnifiedPickerViewDelegate> *delegate;
@property (strong,nonatomic,readonly) UIScrollView *scrollView;

- (NSArray *)visibleRows;

@end


@protocol GDIMagnifiedPickerViewDataSource

@required
- (NSUInteger)numberOfRowsInMagnifiedPickerView:(GDIMagnifiedPickerView*)pickerView;
- (CGFloat)magnifiedPickerView:(GDIMagnifiedPickerView *)pickerView heightForRowAtIndex:(NSUInteger)rowIndex;
- (UIView *)magnifiedPickerView:(GDIMagnifiedPickerView *)pickerView viewForRowAtIndex:(NSUInteger)rowIndex;

@end



@protocol GDIMagnifiedPickerViewDelegate

- (void)magnifiedPickerView:(GDIMagnifiedPickerView *)pickerView didSelectRowAtIndex:(NSUInteger)rowIndex;

@end