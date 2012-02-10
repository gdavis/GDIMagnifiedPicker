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
#import "GDIMagnifiedPickerCell.h"

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

- (GDIMagnifiedPickerCell *)magnifiedPickerView:(GDIMagnifiedPickerView *)pickerView cellForRowType:(GDIMagnifiedPickerCellType)type atRowIndex:(NSUInteger)rowIndex
{
    GDIMagnifiedPickerCell *rowView = (GDIMagnifiedPickerCell *)[pickerView dequeueCellWithType:type];
    
    if (rowView == nil) {
        
        if (type == GDIMagnifiedPickerCellTypeStandard) {
            rowView = [[GDIMagnifiedPickerCell alloc] initWithFrame:CGRectMake(0, 0, pickerView.frame.size.width, kRowHeight) cellType:type];
            rowView.backgroundColor = [UIColor clearColor];
            rowView.opaque = NO;
            
            NSUInteger padding = 12;
            CALayer *bottomLine = [CALayer layer];
            bottomLine.frame = CGRectMake(padding, kRowHeight-1, pickerView.frame.size.width - padding*2, 1);
            bottomLine.backgroundColor = [[UIColor colorWithRed:85.f green:79.f blue:75.f alpha:.43f rgbDivisor:255.f] CGColor];
            [rowView.layer addSublayer:bottomLine];
            
            rowView.label.textAlignment = UITextAlignmentCenter;
            rowView.label.backgroundColor = [UIColor clearColor];
            rowView.label.textColor = [UIColor colorWithRed:106.f green:106.f blue:106.f alpha:1.f rgbDivisor:255.f];
            rowView.label.opaque = NO;
            rowView.label.font = [UIFont boldSystemFontOfSize:13.f];
        }
        else {
            
            rowView = [[GDIMagnifiedPickerCell alloc] initWithFrame:CGRectMake(0, 0, pickerView.frame.size.width, kMagnificationRowHeight) cellType:type];
            rowView.backgroundColor = [UIColor clearColor];
            rowView.opaque = NO;
                    
            rowView.label.textAlignment = UITextAlignmentCenter;
            rowView.label.backgroundColor = [UIColor clearColor];
            rowView.label.opaque = NO;
            rowView.label.font = [UIFont boldSystemFontOfSize:28.f];
        }
    }
    
    rowView.label.text = [NSString stringWithFormat:@"OPTION %i", rowIndex];
    
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
