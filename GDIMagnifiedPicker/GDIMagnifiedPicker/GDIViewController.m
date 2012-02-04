//
//  GDIViewController.m
//  GDIMagnifiedPicker
//
//  Created by Grant Davis on 2/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GDIViewController.h"
#import "UIColor+GDIAdditions.h"

#define kRowHeight 34.f
#define kMagnificationRowHeight 48.f

@implementation GDIViewController
@synthesize magnifiedPickerView;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.magnifiedPickerView.magnification = kMagnificationRowHeight / kRowHeight;
    self.magnifiedPickerView.dataSource = self;
    self.magnifiedPickerView.delegate = self;
}

- (void)viewDidUnload
{
    [self setMagnifiedPickerView:nil];
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - GDIMagnifiedPickerView Data Source


- (NSUInteger)numberOfRowsInMagnifiedPickerView:(GDIMagnifiedPickerView*)pickerView
{
    return 6;
}

- (CGFloat)heightForRowsInMagnifiedPickerView:(GDIMagnifiedPickerView *)pickerView
{
    return kRowHeight;
}

- (CGFloat)heightForMagnificationViewInMagnifiedPickerView:(GDIMagnifiedPickerView *)pickerView
{
    return kMagnificationRowHeight;
}

- (UIView *)magnifiedPickerView:(GDIMagnifiedPickerView *)pickerView viewForRowAtIndex:(NSUInteger)rowIndex
{
    UIView *rowView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, pickerView.frame.size.width, kRowHeight)];
    rowView.backgroundColor = [UIColor randomColorWithAlpha:.5f];
    rowView.opaque = NO;
    
    UILabel *label = [[UILabel alloc] initWithFrame:rowView.bounds];
    label.textAlignment = UITextAlignmentCenter;
    label.backgroundColor = [UIColor clearColor];
    label.opaque = NO;
    label.text = [NSString stringWithFormat:@"Row %i", rowIndex];
    [rowView addSubview:label];
    
    return rowView;
}


#pragma mark - GDIMagnifiedPickerView Delegate

- (void)magnifiedPickerView:(GDIMagnifiedPickerView *)pickerView didSelectRowAtIndex:(NSUInteger)rowIndex
{
    
}


@end
