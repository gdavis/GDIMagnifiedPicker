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
@property (strong,nonatomic) NSMutableArray *rowPositions;
@property (strong,nonatomic) UIView *contentView;
@property (nonatomic) CGFloat rowHeight;
@property (nonatomic) CGFloat magnificationViewHeight;
@property (nonatomic) NSInteger indexOfFirstRow;
@property (nonatomic) NSInteger indexOfLastRow;
@property (nonatomic) NSUInteger numberOfRows;
@property (nonatomic) CGFloat currentOffset;
@property (nonatomic) CGFloat targetYOffset;
@property (strong,nonatomic) GDITouchProxyView *touchProxyView;
@property (nonatomic) CGPoint lastTouchPoint;
@property (nonatomic) CGFloat velocity;
@property (strong,nonatomic) NSTimer *decelerationTimer;
@property (strong,nonatomic) NSTimer *moveToNearestRowTimer;

- (void)setDefaults;

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

- (void)scrollToNearestRowWithAnimation:(BOOL)animate;
- (void)beginScrollingToNearestRow;
- (void)endScrollingToNearestRow;

- (void)beginDeceleration;
- (void)endDeceleration;
- (void)handleDecelerateTick;

- (NSUInteger)indexOfNearestRow;

- (void)scrollContentByValue:(CGFloat)value;
- (void)trackTouchPoint:(CGPoint)point inView:(UIView*)view;

@end


@implementation GDIMagnifiedPickerView
@synthesize dataSource = _dataSource;
@synthesize delegate = _delegate;
@synthesize magnificationView = _magnificationView;
@synthesize friction = _friction;
@synthesize currentIndex = _currentIndex;
@synthesize magnification = _magnification;

@synthesize currentCells = _currentCells;
@synthesize rowPositions = _rowPositions;
@synthesize contentView = _contentView;
@synthesize rowHeight = _rowHeight;
@synthesize magnificationViewHeight = _magnificationViewHeight;
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
        [self scrollToNearestRowWithAnimation:NO];
    }
}


#pragma mark - Initialization Methods

- (void)setDefaults
{
    _friction = .95f;
    _currentOffset = 0;
    _magnification = 2.f;
}


#pragma mark - Build Methods

- (void)build
{
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
    _rowPositions = [NSMutableArray array];
    
    _indexOfFirstRow = 0;
    
    _numberOfRows = [_dataSource numberOfRowsInMagnifiedPickerView:self];
    _rowHeight = [_dataSource heightForRowsInMagnifiedPickerView:self];
    _magnificationViewHeight = [_dataSource heightForMagnificationViewInMagnifiedPickerView:self];
    
    NSUInteger numberOfDisplayedCells = floorf(self.bounds.size.height / _rowHeight);    
    CGFloat currentHeight = 0.f;
    
    for (int i=0; i<numberOfDisplayedCells; i++) {
        
        UIView *cellView = [_dataSource magnifiedPickerView:self viewForRowAtIndex:i];
        cellView.frame = CGRectMake(0, currentHeight, self.frame.size.width, _rowHeight);
        
        [_contentView addSubview:cellView];
        [_currentCells addObject:cellView];
        [_rowPositions addObject:[NSNumber numberWithFloat:currentHeight]];
        
        currentHeight += cellView.frame.size.height;
        
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
    CGFloat firstRowPos = [(NSNumber *)[_rowPositions objectAtIndex:0] floatValue];
    if (firstRowPos + _rowHeight < 0) {
        [self removeTopRow];
        [self updateVisibleRows];
    }
    else if (firstRowPos > 0) {
        [self addTopRow];
        [self updateVisibleRows];
    }
    
    CGFloat lastRowPos = [(NSNumber *)[_rowPositions lastObject] floatValue];
    CGFloat availableHeight = self.bounds.size.height - (_magnificationViewHeight - _rowHeight);
    
    if (lastRowPos + _rowHeight < availableHeight) {
        [self addBottomRow];
        [self updateVisibleRows];
    }
    else if (lastRowPos > availableHeight) {
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
    
    CGFloat firstRowPos = [(NSNumber *)[_rowPositions objectAtIndex:0] floatValue];
    CGFloat currentY = firstRowPos - _rowHeight;
    
    UIView *cellView = [_dataSource magnifiedPickerView:self viewForRowAtIndex:_indexOfFirstRow];
    cellView.frame = CGRectMake(0, currentY, self.frame.size.width, _rowHeight);
    
    [_contentView addSubview:cellView];
    [_currentCells insertObject:cellView atIndex:0];
    [_rowPositions insertObject:[NSNumber numberWithFloat:currentY] atIndex:0];
}


- (void)addBottomRow
{
    _indexOfLastRow++;
    if (_indexOfLastRow >= _numberOfRows) {
        _indexOfLastRow = 0;
    }
    
    CGFloat lastRowPos = [(NSNumber *)[_rowPositions lastObject] floatValue];
    CGFloat currentY = lastRowPos + _rowHeight;
    
    UIView *cellView = [_dataSource magnifiedPickerView:self viewForRowAtIndex:_indexOfLastRow];
    cellView.frame = CGRectMake(0, currentY, self.frame.size.width, _rowHeight);
    
    [_contentView addSubview:cellView];
    [_currentCells addObject:cellView];
    [_rowPositions addObject:[NSNumber numberWithFloat:currentY]];
}


- (void)removeTopRow
{
    UIView *firstRowView = [_currentCells objectAtIndex:0];
    [firstRowView removeFromSuperview];
    [_currentCells removeObject:firstRowView];
    [_rowPositions removeObjectAtIndex:0];
    
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
    [_rowPositions removeLastObject];
    
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

    // first, we adjust the stored positions of the cells
    for (int i=0; i<_rowPositions.count; i++) {
        NSNumber *pos = [_rowPositions objectAtIndex:i];
        [_rowPositions replaceObjectAtIndex:i withObject:[NSNumber numberWithFloat:pos.floatValue + value]];
    }
    
    CGFloat magnificationRowOverlap = _magnificationViewHeight - _rowHeight;
    CGFloat availableHeight = self.bounds.size.height - magnificationRowOverlap;
    CGFloat centerY = availableHeight * .5;
    CGFloat bottomMagY = centerY - (self.bounds.size.height - availableHeight) * .5;

    for (int i=0; i<_currentCells.count; i++) {

        UIView *rowView = [_currentCells objectAtIndex:i];
        
        CGFloat dx = 0, dy = 0;
        dy = [(NSNumber *)[_rowPositions objectAtIndex:i] floatValue];
        
        CGFloat rowCenter = dy + _rowHeight*.5;
        CGFloat distanceFromCenter = centerY - rowCenter;
        
        CGFloat offset = 0;
        
        CGAffineTransform transform = CGAffineTransformIdentity;        
        
        if (fabsf(distanceFromCenter) <= _rowHeight) {
            CGFloat offsetFactor =  1-(distanceFromCenter / _rowHeight);
            offset = offsetFactor * (magnificationRowOverlap * .5);
            
            
            CGFloat scaleFactor = 1-(fabsf(distanceFromCenter) / _rowHeight);
            float scale = fmaxf(1, scaleFactor * _magnification);
            NSLog(@"distanceFromCenter: %.2f, offsetFactor = %.2f, scaleFactor = %.2f, scale = %.2f", distanceFromCenter, offsetFactor, scaleFactor, scale);
            
            CGFloat scaledWidth = self.bounds.size.width * scale;
            CGFloat scaledHeight = _rowHeight * scale;
            
            dx += (self.bounds.size.width - scaledWidth) * .5;
            dy += (_rowHeight - scaledHeight) * .5;
            
            transform = CGAffineTransformMakeScale(scale, scale);
        }
        else if (dy >= bottomMagY) {
            offset = magnificationRowOverlap;
        }
        
        rowView.transform = transform;
        rowView.frame = CGRectMake(dx, dy + offset, rowView.frame.size.width, rowView.frame.size.height);
        [rowView setNeedsDisplay];
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
    
    if ( fabsf(_velocity) < .1f) {
        [self endDeceleration];
        [self scrollToNearestRowWithAnimation:YES];
    }
    else {
        [self scrollContentByValue:_velocity];
    }
}

#pragma mark - Nearest Row Scroll Methods

- (NSUInteger)indexOfNearestRow
{
    NSUInteger indexOfNearestRow;
    CGFloat closestDistance = FLT_MAX;
    CGFloat availableHeight = self.bounds.size.height - (_magnificationViewHeight - _rowHeight);
    CGFloat centerY = availableHeight * .5;
    
    for (int i=0; i<_rowPositions.count; i++) {
        
        CGFloat rowPos = [(NSNumber *)[_rowPositions objectAtIndex:i] floatValue];
        CGFloat cellCenter = rowPos + _rowHeight * .5;
        CGFloat distance = cellCenter - centerY;
        
        if (fabsf(distance) < fabsf(closestDistance)) {
            closestDistance = distance;
            indexOfNearestRow = i;
        }
    }
    return indexOfNearestRow;
}

- (void)scrollToNearestRowWithAnimation:(BOOL)animate
{
    // find the row nearest to the center
    NSUInteger indexOfNearestRow;
    CGFloat closestDistance = FLT_MAX;
    CGFloat availableHeight = self.bounds.size.height - (_magnificationViewHeight - _rowHeight);
    CGFloat centerY = availableHeight * .5;
    
    for (int i=0; i<_rowPositions.count; i++) {
        
        CGFloat rowPos = [(NSNumber *)[_rowPositions objectAtIndex:i] floatValue];        
        CGFloat cellCenter = rowPos + _rowHeight * .5;
        CGFloat distance = cellCenter - centerY;
        
        if (fabsf(distance) < fabsf(closestDistance)) {
            closestDistance = distance;
            indexOfNearestRow = i;
            _targetYOffset = _currentOffset - closestDistance;
        }
    }
    
    // determine the current index of the selected slice
    _currentIndex = _indexOfFirstRow + indexOfNearestRow;
    
    if (_currentIndex > _numberOfRows-1) {
        _currentIndex = fmodf(_currentIndex, _numberOfRows);
    }
    
    if ([_delegate respondsToSelector:@selector(magnifiedPickerView:didSelectRowAtIndex:)]) {
        [_delegate magnifiedPickerView:self didSelectRowAtIndex:_currentIndex];
    }
    
    if (animate) {
        [self beginScrollingToNearestRow];
    }
    else {
        [self scrollContentByValue:_targetYOffset - _currentOffset];
    }
}


- (void)beginScrollingToNearestRow
{
    [_moveToNearestRowTimer invalidate];
    _moveToNearestRowTimer = [NSTimer scheduledTimerWithTimeInterval:kAnimationInterval target:self selector:@selector(handleMoveToNearestRowTick) userInfo:nil repeats:YES];
}


- (void)endScrollingToNearestRow
{
    [_moveToNearestRowTimer invalidate];
    _moveToNearestRowTimer = nil;
}


- (void)handleMoveToNearestRowTick
{
    CGFloat delta1 = (_targetYOffset - _currentOffset);
    CGFloat delta2 = (_targetYOffset - _currentOffset) + self.bounds.size.height;
    CGFloat delta;
    
    if (fabsf(delta1) < fabsf(delta2)) {
        delta = delta1 * (1 - _friction);
    }
    else {
        delta = delta2 * (1 - _friction);
    }
    
    if (fabsf(delta) < .01) {
        [self scrollContentByValue:_targetYOffset - _currentOffset];
        [self endScrollingToNearestRow];
    }
    else {
        [self scrollContentByValue:delta];
    }
}


#pragma mark - Gesture View Delegate


- (void)gestureView:(GDITouchProxyView *)gv touchBeganAtPoint:(CGPoint)point
{
    // reset the last point to where we start from.
    _lastTouchPoint = point;
    
    [self endDeceleration];
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