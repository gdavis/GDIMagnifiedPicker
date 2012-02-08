//
//  GDIViewController.m
//  GDIMagnifiedPicker
//
//  Created by Grant Davis on 2/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GDIViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "UIColor+GDIAdditions.h"

#define kRowHeight 35.f
#define kMagnificationRowHeight 47.f

@implementation GDIViewController
@synthesize magnifiedPickerView;
@synthesize currentSelectionLabel;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.magnifiedPickerView.delegate = self;
    self.magnifiedPickerView.dataSource = self;
    
    UIImageView *selectionView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"grill-guide-picker-selection-bg"]];
    self.magnifiedPickerView.selectionBackgroundView = selectionView;
}

- (void)viewDidUnload
{
    [self setMagnifiedPickerView:nil];
    [self setCurrentSelectionLabel:nil];
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
    rowView.backgroundColor = [UIColor clearColor];
    rowView.opaque = NO;
    
    NSUInteger padding = 12;
    CALayer *bottomLine = [CALayer layer];
    bottomLine.frame = CGRectMake(padding, kRowHeight-1, pickerView.frame.size.width - padding*2, 1);
    bottomLine.backgroundColor = [[UIColor colorWithRed:85.f green:79.f blue:75.f alpha:.43f rgbDivisor:255.f] CGColor];
    [rowView.layer addSublayer:bottomLine];
    
    UILabel *label = [[UILabel alloc] initWithFrame:rowView.bounds];
    label.textAlignment = UITextAlignmentCenter;
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor colorWithRed:106.f green:106.f blue:106.f alpha:1.f rgbDivisor:255.f];
    label.opaque = NO;
    label.text = [NSString stringWithFormat:@"OPTION %i", rowIndex];
    label.font = [UIFont boldSystemFontOfSize:13.f];
    [rowView addSubview:label];
    
    return rowView;
}

- (UIView *)magnifiedPickerView:(GDIMagnifiedPickerView *)pickerView magnifiedViewForRowAtIndex:(NSUInteger)rowIndex
{
    UIView *rowView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, pickerView.frame.size.width, kMagnificationRowHeight)];
    rowView.backgroundColor = [UIColor clearColor];
    rowView.opaque = NO;
    
    UILabel *label = [[UILabel alloc] initWithFrame:rowView.bounds];
    label.textAlignment = UITextAlignmentCenter;
    label.backgroundColor = [UIColor clearColor];
    label.opaque = NO;
    label.text = [NSString stringWithFormat:@"OPTION %i", rowIndex];
    label.font = [UIFont boldSystemFontOfSize:28.f];
    [rowView addSubview:label];
    
    return rowView;
}


#pragma mark - GDIMagnifiedPickerView Delegate

- (void)magnifiedPickerView:(GDIMagnifiedPickerView *)pickerView didSelectRowAtIndex:(NSUInteger)rowIndex
{
    self.currentSelectionLabel.text = [NSString stringWithFormat:@"Current row: %i", rowIndex];
}


- (IBAction)reloadPicker:(id)sender {
    [self.magnifiedPickerView reloadData];
}
@end
