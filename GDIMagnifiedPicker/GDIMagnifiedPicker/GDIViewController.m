//
//  GDIViewController.m
//  GDIMagnifiedPicker
//
//  Created by Grant Davis on 2/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GDIViewController.h"
#import "UIColor+GDIAdditions.h"

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
    return 10;
}

- (CGFloat)magnifiedPickerView:(GDIMagnifiedPickerView *)pickerView heightForRowAtIndex:(NSUInteger)rowIndex
{
    return 32.f;
}

- (UIView *)magnifiedPickerView:(GDIMagnifiedPickerView *)pickerView viewForRowAtIndex:(NSUInteger)rowIndex
{
    UIView *rowView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, pickerView.frame.size.width, 32.f)];
    rowView.backgroundColor = [UIColor randomColorWithAlpha:.5f];
    return rowView;
}


#pragma mark - GDIMagnifiedPickerView Delegate

- (void)magnifiedPickerView:(GDIMagnifiedPickerView *)pickerView didSelectRowAtIndex:(NSUInteger)rowIndex
{
    
}


@end
