//
//  GDIMagnifiedPickerView.m
//  GDIMagnifiedPicker
//
//  Created by Grant Davis on 2/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GDIMagnifiedPickerView.h"
#import <QuartzCore/QuartzCore.h>

#define kAnimationInterval 1.f/60.f

@interface GDIMagnifiedPickerView()

@property (strong,nonatomic) NSMutableArray *currentCells;
@property (strong,nonatomic) UIView *contentView;
@property (nonatomic) CGFloat contentHeight;
@property (nonatomic) NSInteger indexOfFirstRow;
@property (nonatomic) NSInteger indexOfLastRow;
@property (nonatomic) NSUInteger numberOfRows;
@property (nonatomic) CGFloat currentOffset;
@property (nonatomic) CGFloat targetYOffset;
@property (strong,nonatomic) GDITouchProxyView *touchProxyView;
@property (nonatomic) CGPoint lastTouchPoint;
@property (nonatomic) CGFloat velocity;
@property(strong,nonatomic) NSTimer *decelerationTimer;
@property(strong,nonatomic) NSTimer *moveToNearestRowTimer;

- (void)setDefaults;
- (void)initContentHeight;

- (void)build;
- (void)buildContentView;
- (void)buildTouchProxyView;
- (void)buildVisibleRows;
- (void)buildMagnificationView;

- (void)updateVisibleRows;

- (void)addTopRow;
- (void)addBottomRow;

- (void)removeTopRow;
- (void)removeBottomRow;

- (void)scrollToNearestRow;
- (void)beginScrollingToNearestRow;
- (void)endScrollingToNearestRow;

- (void)beginDeceleration;
- (void)endDeceleration;
- (void)handleDecelerateTick;

- (void)scrollContentByValue:(CGFloat)value;
- (void)trackTouchPoint:(CGPoint)point inView:(UIView*)view;

@end


@implementation GDIMagnifiedPickerView
@synthesize dataSource = _dataSource;
@synthesize delegate = _delegate;
@synthesize magnificationView = _magnificationView;
@synthesize friction = _friction;

@synthesize currentCells = _currentCells;
@synthesize contentView = _contentView;
@synthesize contentHeight = _contentHeight;
@synthesize indexOfFirstRow = _indexOfFirstRow;
@synthesize indexOfLastRow = _indexOfLastRow;
@synthesize numberOfRows = _numberOfRows;
@synthesize currentOffset = _currentOffset;
@synthesize targetYOffset = _targetYOffset;
@synthesize touchProxyView = _touchProxyView;
@synthesize lastTouchPoint = _lastTouchPoint;
@synthesize velocity = _velocity;
@synthesize decelerationTimer = _decelerationTimer;
@synthesize moveToNearestRowTimer = _moveToNearestRowTimer;


#pragma mark - Instance Methods

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setDefaults];
    }
    return self;
}


- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setDefaults];
}


- (NSArray *)visibleRows
{
    return [NSArray arrayWithArray:_currentCells];
}

- (void)setDataSource:(NSObject<GDIMagnifiedPickerViewDataSource> *)dataSource
{
    _dataSource = dataSource;
    if (_dataSource != nil) {
        [self build];
    }
}


#pragma mark - Initialization Methods

- (void)setDefaults
{
    _friction = .95f;
    _currentOffset = 0;
}

- (void)initContentHeight
{
    _contentHeight = 0;
    _numberOfRows = [_dataSource numberOfRowsInMagnifiedPickerView:self];
    for (int i=0; i<_numberOfRows; i++) {
        _contentHeight += [_dataSource magnifiedPickerView:self heightForRowAtIndex:i];
    }
}


#pragma mark - Build Methods

- (void)build
{
    [self initContentHeight];
    [self buildContentView];
    [self buildTouchProxyView];
    [self buildVisibleRows];
    [self buildMagnificationView];
}

- (void)buildContentView 
{
    _contentView = [[UIView alloc] initWithFrame:self.bounds];
    _contentView.clipsToBounds = YES;
    [self addSubview:_contentView];
}


- (void)buildTouchProxyView
{
    _touchProxyView = [[GDITouchProxyView alloc] initWithFrame:self.bounds];
    _touchProxyView.delegate = self;
    [self addSubview:_touchProxyView];
}


- (void)buildVisibleRows
{
    _currentCells = [NSMutableArray array];
    _indexOfFirstRow = 0;
    
    CGFloat currentHeight = 0.f;
    
    for (int i=0; i<_numberOfRows; i++) {
        
        UIView *cellView = [_dataSource magnifiedPickerView:self viewForRowAtIndex:i];
        cellView.frame = CGRectMake(0, currentHeight, self.frame.size.width, [_dataSource magnifiedPickerView:self heightForRowAtIndex:i]);
        
        [_contentView addSubview:cellView];
        [_currentCells addObject:cellView];
        
        currentHeight += cellView.frame.size.height;
        
        // stop making rows when we have filled the view
        if (currentHeight >= self.frame.size.height) {
            _indexOfLastRow = i;
            break;
        }
        
        // start repeating rows if we don't have enough to fill the view
        if (i == _numberOfRows-1) {
            i = -1;
        }
    }
}


- (void)buildMagnificationView
{
    CGFloat magViewHeight = 47.f;
    _magnificationView = [[UIView alloc] initWithFrame:CGRectMake(0, self.bounds.size.height * .5 - magViewHeight*.5, self.bounds.size.width, magViewHeight)];
    _magnificationView.userInteractionEnabled = NO;
    
    _magnificationView.layer.borderColor = [[UIColor redColor] CGColor];
    _magnificationView.layer.borderWidth = 1.f;
    
    [self addSubview:_magnificationView];
}

#pragma mark - Row Update Methods

- (void)updateVisibleRows
{
    UIView *firstRowView = [_currentCells objectAtIndex:0];    
    if (firstRowView.frame.origin.y + firstRowView.frame.size.height < 0) {
        [self removeTopRow];
        [self updateVisibleRows];
    }
    else if (firstRowView.frame.origin.y > 0) {
        [self addTopRow];
        [self updateVisibleRows];
    }
    
    UIView *lastRowView = [_currentCells lastObject];
    if (lastRowView.frame.origin.y + lastRowView.frame.size.height < self.bounds.size.height) {
        [self addBottomRow];
        [self updateVisibleRows];
    }
    else if (lastRowView.frame.origin.y > self.bounds.size.height) {
        [self removeBottomRow];
        [self updateVisibleRows];
    }
}


- (void)addTopRow
{
    _indexOfFirstRow--;
    if (_indexOfFirstRow < 0) {
        _indexOfFirstRow = _numberOfRows-1;
    }
    
    UIView *curFirstRowView = [_currentCells objectAtIndex:0];
    CGFloat cellRowHeight = [_dataSource magnifiedPickerView:self heightForRowAtIndex:_indexOfFirstRow];
    CGFloat currentY = curFirstRowView.frame.origin.y - cellRowHeight;
    
    UIView *cellView = [_dataSource magnifiedPickerView:self viewForRowAtIndex:_indexOfFirstRow];
    cellView.frame = CGRectMake(0, currentY, self.frame.size.width, cellRowHeight);
    
    [_contentView addSubview:cellView];
    [_currentCells insertObject:cellView atIndex:0];
}


- (void)addBottomRow
{
    _indexOfLastRow++;
    if (_indexOfLastRow >= _numberOfRows) {
        _indexOfLastRow = 0;
    }
    
    UIView *curLastRowView = [_currentCells lastObject];
    CGFloat cellRowHeight = [_dataSource magnifiedPickerView:self heightForRowAtIndex:_indexOfLastRow];
    CGFloat currentHeight = curLastRowView.frame.origin.y + curLastRowView.frame.size.height;
    
    UIView *cellView = [_dataSource magnifiedPickerView:self viewForRowAtIndex:_indexOfLastRow];
    cellView.frame = CGRectMake(0, currentHeight, self.frame.size.width, cellRowHeight);
    
    [_contentView addSubview:cellView];
    [_currentCells addObject:cellView];
}


- (void)removeTopRow
{
    UIView *firstRowView = [_currentCells objectAtIndex:0];
    [firstRowView removeFromSuperview];
    [_currentCells removeObject:firstRowView];
    
    _indexOfFirstRow++;
    if (_indexOfFirstRow > _numberOfRows-1) {
        _indexOfFirstRow = 0;
    }
}


- (void)removeBottomRow
{
    UIView *lastRowView = [_currentCells lastObject];
    [lastRowView removeFromSuperview];
    [_currentCells removeObject:lastRowView];
    
    _indexOfLastRow--;
    if (_indexOfLastRow < 0) {
        _indexOfLastRow = _numberOfRows-1;
    }
}

#pragma mark - Touch Tracking


- (void)trackTouchPoint:(CGPoint)point inView:(UIView*)view
{
    CGFloat deltaY = point.y - _lastTouchPoint.y;
    
    [self scrollContentByValue:deltaY];
    
    _velocity = deltaY;
    _lastTouchPoint = point;
}

#pragma mark - Scrolling

- (void)scrollContentByValue:(CGFloat)value
{
    _currentOffset += value;
    
    for (UIView *rowView in _currentCells) {
        rowView.frame = CGRectMake(rowView.frame.origin.x, rowView.frame.origin.y + value, rowView.frame.size.width, rowView.frame.size.height);
    }
    
    [self updateVisibleRows];
}


#pragma mark - Decelerate Methods

- (void)beginDeceleration
{
    [_decelerationTimer invalidate];
    _decelerationTimer = [NSTimer scheduledTimerWithTimeInterval:kAnimationInterval target:self selector:@selector(handleDecelerateTick) userInfo:nil repeats:YES];
}

- (void)endDeceleration
{
    [_decelerationTimer invalidate];
    _decelerationTimer = nil;
}

- (void)handleDecelerateTick
{
    _velocity *= _friction;
    
    if ( fabsf(_velocity) < .001f) {
        [self endDeceleration];
//        [self scrollToNearestRow];
    }
    else {
        [self scrollContentByValue:_velocity];
    }
}

#pragma mark - Nearest Row Scroll Methods


- (void)scrollToNearestRow
{
    // find the row nearest to the center
    CGFloat indexOfNearestRow;
    CGFloat closestDistance = FLT_MAX;
    CGFloat centerY = self.bounds.size.height * .5;
    
    for (int i=0; i<_currentCells.count; i++) {
        
        UIView *currentRowCell = [_currentCells objectAtIndex:i];
        
        CGFloat cellCenter = currentRowCell.frame.origin.y + currentRowCell.frame.size.height * .5;
        CGFloat distance = (cellCenter - _currentOffset) - centerY;
        
        if (fabsf(distance) < fabsf(closestDistance)) {
            closestDistance = distance;
            indexOfNearestRow = i;
        }
    }
    
}


- (void)beginScrollingToNearestRow
{
    
}


- (void)endScrollingToNearestRow
{
    
}


#pragma mark - Gesture View Delegate


- (void)gestureView:(GDITouchProxyView *)gv touchBeganAtPoint:(CGPoint)point
{
    // reset the last point to where we start from.
    _lastTouchPoint = point;
    
    [self endScrollingToNearestRow];
    [self trackTouchPoint:point inView:gv];
}


- (void)gestureView:(GDITouchProxyView *)gv touchMovedToPoint:(CGPoint)point
{
    [self trackTouchPoint:point inView:gv];
}


- (void)gestureView:(GDITouchProxyView *)gv touchEndedAtPoint:(CGPoint)point
{
    [self beginDeceleration];
}


@end