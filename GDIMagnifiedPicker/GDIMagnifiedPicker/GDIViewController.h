//
//  GDIViewController.h
//  GDIMagnifiedPicker
//
//  Created by Grant Davis on 2/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GDIMagnifiedPickerView.h"

@interface GDIViewController : UIViewController <GDIMagnifiedPickerViewDataSource, GDIMagnifiedPickerViewDelegate>

@property (weak, nonatomic) IBOutlet GDIMagnifiedPickerView *magnifiedPickerView;
@property (weak, nonatomic) IBOutlet UILabel *currentSelectionLabel;

@end
