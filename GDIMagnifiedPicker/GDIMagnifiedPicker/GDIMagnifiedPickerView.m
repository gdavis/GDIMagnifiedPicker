//
//  GDIMagnifiedPickerView.m
//  GDIMagnifiedPicker
//
//  Created by Grant Davis on 2/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GDIMagnifiedPickerView.h"

#define kAnimationInterval 1.f/60.f

@interface GDIMagnifiedPickerView()

@property (strong,nonatomic) NSMutableArray *currentCells;
@property (strong,nonatomic) NSMutableArray *currentMagnifiedCells;
@property (strong,nonatomic) NSMutableArray *rowPositions;
@property (strong,nonatomic) UIView *contentView;
@property (strong,nonatomic) UIView *magnificationView;
@property (strong,nonatomic) UIView *magnifiedCellContainerView;
@property (nonatomic) CGFloat rowHeight;
@property (nonatomic) CGFloat magnificationViewHeight;
@property (nonatomic) CGFloat magnification;
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
@property (nonatomic) CGFloat nearestRowStartValue;
@property (nonatomic) CGFloat nearestRowDelta;
@property (nonatomic) CGFloat nearestRowDuration;
@property (strong,nonatomic) NSDate *nearestRowStartTime;

- (void)setDefaults;
- (void)initDataSourceProperties;

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

- (void)scrollContentByValue:(CGFloat)value;
- (void)trackTouchPoint:(CGPoint)point inView:(UIView*)view;

- (CGFloat)easeInOutWithCurrentTime:(CGFloat)t start:(CGFloat)b change:(CGFloat)c duration:(CGFloat)d;

@end


@implementation GDIMagnifiedPickerView
@synthesize dataSource = _dataSource;
@synthesize delegate = _delegate;
@synthesize friction = _friction;
@synthesize currentIndex = _currentIndex;
@synthesize selectionBackgroundView = _selectionBackgroundView;

@synthesize currentCells = _currentCells;
@synthesize currentMagnifiedCells = _currentMagnifiedCells;
@synthesize rowPositions = _rowPositions;
@synthesize contentView = _contentView;
@synthesize magnification = _magnification;
@synthesize magnificationView = _magnificationView;
@synthesize magnifiedCellContainerView = _magnifiedCellContainerView;
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
@synthesize nearestRowStartValue = _nearestRowStartValue;
@synthesize nearestRowDelta = _nearestRowDelta;
@synthesize nearestRowDuration = _nearestRowDuration;
@synthesize nearestRowStartTime = _nearestRowStartTime;

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
        [self initDataSourceProperties];
        [self build];
        [self scrollToNearestRowWithAnimation:NO];
    }
}

- (void)setSelectionBackgroundView:(UIView *)selectionBackgroundView
{
    if (_selectionBackgroundView) {
        [_selectionBackgroundView removeFromSuperview];
    }
    _selectionBackgroundView = selectionBackgroundView;
    
    CGFloat containerY = roundf(self.bounds.size.height * .5 - _selectionBackgroundView.frame.size.height * .5);
    _selectionBackgroundView.frame = CGRectMake(0, containerY, _selectionBackgroundView.frame.size.width, _selectionBackgroundView.frame.size.height);
    [self insertSubview:_selectionBackgroundView belowSubview:_magnificationView];
}


#pragma mark - Initialization Methods

- (void)setDefaults
{
    _friction = .85f;
    _currentOffset = 0;
}


- (void)initDataSourceProperties
{
    _magnification = [_dataSource heightForMagnificationViewInMagnifiedPickerView:self] / [_dataSource heightForRowsInMagnifiedPickerView:self];
    _numberOfRows = [_dataSource numberOfRowsInMagnifiedPickerView:self];
    _rowHeight = [_dataSource heightForRowsInMagnifiedPickerView:self];
    _magnificationViewHeight = [_dataSource heightForMagnificationViewInMagnifiedPickerView:self];
}


#pragma mark - Build Methods

- (void)build
{    
    [self buildContentView];
    [self buildTouchProxyView];
    [self buildMagnificationView];
    [self buildVisibleRows];
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


- (void)buildMagnificationView
{
    _magnificationView = [[UIView alloc] initWithFrame:CGRectMake(0, self.bounds.size.height * .5 - _magnificationViewHeight*.5, self.bounds.size.width, _magnificationViewHeight)];
    _magnificationView.userInteractionEnabled = NO;
    _magnificationView.clipsToBounds = YES;
    _magnificationView.opaque = NO;
    [self addSubview:_magnificationView];
    
    CGFloat magnificationRowOverlap = _magnificationViewHeight - _rowHeight;
    CGFloat availableHeight = ( self.bounds.size.height - magnificationRowOverlap ) * _magnification;
    CGFloat containerY = _magnificationViewHeight * .5 - availableHeight * .5;
    _magnifiedCellContainerView = [[UIView alloc] initWithFrame:CGRectMake(0, containerY, self.bounds.size.width, availableHeight)];
    _magnifiedCellContainerView.userInteractionEnabled = NO;
    _magnifiedCellContainerView.opaque = NO;
    [_magnificationView addSubview:_magnifiedCellContainerView];
}


- (void)buildVisibleRows
{
    _currentCells = [NSMutableArray array];
    _currentMagnifiedCells = [NSMutableArray array];
    _rowPositions = [NSMutableArray array];
    
    NSUInteger numberOfDisplayedCells = floorf(self.bounds.size.height / _rowHeight);    
    CGFloat currentY = 0.f;
    CGFloat currentMagY = 0.f;
    
    _indexOfFirstRow = 0;
    _indexOfLastRow = numberOfDisplayedCells-1;
    
    for (int i=0; i<numberOfDisplayedCells; i++) {
        
        // build the standard sized cells
        UIView *cellView = [_dataSource magnifiedPickerView:self viewForRowAtIndex:i];
        cellView.frame = CGRectMake(0, currentY, self.bounds.size.width, _rowHeight);
        
        [_contentView addSubview:cellView];
        [_currentCells addObject:cellView];
        
        
        // build the magnified cells
        UIView *magnifiedCellView = [_dataSource magnifiedPickerView:self magnifiedViewForRowAtIndex:i];
        magnifiedCellView.frame = CGRectMake(0, currentMagY, self.bounds.size.width, _magnificationViewHeight);
        [_magnifiedCellContainerView addSubview:magnifiedCellView];
        [_currentMagnifiedCells addObject:magnifiedCellView];
        
        // store the position of this cell
        [_rowPositions addObject:[NSNumber numberWithFloat:currentY]];
        
        // increment position
        currentY += _rowHeight;
        currentMagY += _magnificationViewHeight;
        
        // start repeating rows if we don't have enough to fill the view
        if (i == _numberOfRows-1) {
            i = -1;
        }
    }
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
    [_rowPositions insertObject:[NSNumber numberWithFloat:currentY] atIndex:0];
    
    // build the standard cell
    UIView *cellView = [_dataSource magnifiedPickerView:self viewForRowAtIndex:_indexOfFirstRow];
    cellView.frame = CGRectMake(0, currentY, self.frame.size.width, _rowHeight);
    
    [_contentView addSubview:cellView];
    [_currentCells insertObject:cellView atIndex:0];
    
    // build the magnified cell
    UIView *magnifiedCellView = [_dataSource magnifiedPickerView:self magnifiedViewForRowAtIndex:_indexOfFirstRow];
    magnifiedCellView.frame = CGRectMake(0, firstRowPos - _magnificationViewHeight, self.bounds.size.width, _magnificationViewHeight);
    [_magnifiedCellContainerView addSubview:magnifiedCellView];
    [_currentMagnifiedCells insertObject:magnifiedCellView atIndex:0];
}


- (void)addBottomRow
{
    _indexOfLastRow++;
    if (_indexOfLastRow >= _numberOfRows) {
        _indexOfLastRow = 0;
    }
    
    CGFloat lastRowPos = [(NSNumber *)[_rowPositions lastObject] floatValue];
    CGFloat magnificationRowOverlap = _magnificationViewHeight - _rowHeight;
    CGFloat currentY = lastRowPos + _rowHeight;
    
    [_rowPositions addObject:[NSNumber numberWithFloat:currentY]];
    
    // build the standard cell
    UIView *cellView = [_dataSource magnifiedPickerView:self viewForRowAtIndex:_indexOfLastRow];
    cellView.frame = CGRectMake(0, currentY + magnificationRowOverlap, self.frame.size.width, _rowHeight);
    [_contentView addSubview:cellView];
    [_currentCells addObject:cellView];
    
    // build the magnified cell
    UIView *magnifiedCellView = [_dataSource magnifiedPickerView:self magnifiedViewForRowAtIndex:_indexOfLastRow];
    magnifiedCellView.frame = CGRectMake(0, lastRowPos + _magnificationViewHeight, self.bounds.size.width, _magnificationViewHeight);
    [_magnifiedCellContainerView addSubview:magnifiedCellView];
    [_currentMagnifiedCells addObject:magnifiedCellView];
}


- (void)removeTopRow
{
    UIView *firstRowView = [_currentCells objectAtIndex:0];
    [firstRowView removeFromSuperview];
    [_currentCells removeObject:firstRowView];
    [_rowPositions removeObjectAtIndex:0];
    
    UIView *firstRowMagView = [_currentMagnifiedCells objectAtIndex:0];
    [firstRowMagView removeFromSuperview];
    [_currentMagnifiedCells removeObject:firstRowMagView];
    
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
    
    UIView *lastRowMagView = [_currentMagnifiedCells lastObject];
    [lastRowMagView removeFromSuperview];
    [_currentMagnifiedCells removeLastObject];
    
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
    
    // reposition the normal sized cells.
    for (int i=0; i<_currentCells.count; i++) {

        UIView *rowView = [_currentCells objectAtIndex:i];
        
        CGFloat dx = 0, dy = 0;
        dy = [(NSNumber *)[_rowPositions objectAtIndex:i] floatValue];
        
        CGFloat rowCenter = dy + _rowHeight*.5;
        CGFloat distanceFromCenter = centerY - rowCenter;
        
        CGFloat offset = 0;

        if (fabsf(distanceFromCenter) <= _rowHeight) {
            CGFloat offsetFactor =  1-(distanceFromCenter / _rowHeight);
            offset = offsetFactor * (magnificationRowOverlap * .5);
        }
        else if (dy >= bottomMagY) {
            offset = magnificationRowOverlap;
        }

        rowView.frame = CGRectMake(dx, dy + offset, rowView.frame.size.width, rowView.frame.size.height);
    }
    
    // reposition the magnified cells
    for (int i=0; i<_currentMagnifiedCells.count; i++) {
        
        UIView *magnifiedRowView = [_currentMagnifiedCells objectAtIndex:i];
        CGFloat dy = [(NSNumber *)[_rowPositions objectAtIndex:i] floatValue] * _magnification;
        magnifiedRowView.frame = CGRectMake(0, dy, magnifiedRowView.frame.size.width, magnifiedRowView.frame.size.height);
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
    CGFloat delta1 = (_targetYOffset - _currentOffset);
    CGFloat delta2 = (_targetYOffset - _currentOffset) + self.bounds.size.height;
    
    if (fabsf(delta1) < fabsf(delta2)) {
        _nearestRowDelta = delta1;
    }
    else {
        _nearestRowDelta = delta2;
    }
    
    _nearestRowStartValue = _currentOffset;
    _nearestRowStartTime = [NSDate date];
    _nearestRowDuration = [[_nearestRowStartTime dateByAddingTimeInterval:.666f] timeIntervalSinceDate:_nearestRowStartTime];
    
    [_moveToNearestRowTimer invalidate];
    _moveToNearestRowTimer = [NSTimer scheduledTimerWithTimeInterval:kAnimationInterval target:self selector:@selector(handleMoveToNearestRowTick) userInfo:nil repeats:YES];
}


- (void)endScrollingToNearestRow
{
    _nearestRowStartTime = nil;
    [_moveToNearestRowTimer invalidate];
    _moveToNearestRowTimer = nil;
}


- (void)handleMoveToNearestRowTick
{
    // see what our current duration is
    CGFloat currentTime = fabsf([_nearestRowStartTime timeIntervalSinceNow]);
    
    // stop scrolling if we are past our duration
    if (currentTime >= _nearestRowDuration) {
        [self scrollContentByValue:_targetYOffset - _currentOffset];
        [self endScrollingToNearestRow];
    }
    // otherwise, calculate how much we should be scrolling our content by
    else {
        CGFloat dy = [self easeInOutWithCurrentTime:currentTime start:_nearestRowStartValue change:_nearestRowDelta duration:_nearestRowDuration];
        [self scrollContentByValue:dy - _currentOffset];
    }
}


#pragma mark - Gesture View Delegate


- (void)gestureView:(GDITouchProxyView *)gv touchBeganAtPoint:(CGPoint)point
{
    // reset the last point to where we start from.
    _lastTouchPoint = point;
    _velocity = 0;
    
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


/*
 static function easeIn (t:Number, b:Number, c:Number, d:Number):Number {
 return (t==0) ? b : c * Math.pow(2, 10 * (t/d - 1)) + b;
 }
 static function easeOut (t:Number, b:Number, c:Number, d:Number):Number {
 return (t==d) ? b+c : c * (-Math.pow(2, -10 * t/d) + 1) + b;
 }
 static function easeInOut (t:Number, b:Number, c:Number, d:Number):Number {
 if (t==0) return b;
 if (t==d) return b+c;
 if ((t/=d/2) < 1) return c/2 * Math.pow(2, 10 * (t - 1)) + b;
 return c/2 * (-Math.pow(2, -10 * --t) + 2) + b;
 }
 
 Easing equations taken with permission under the BSD license from Robert Penner.
 
 Copyright © 2001 Robert Penner
 All rights reserved.
 */

- (CGFloat)easeInOutWithCurrentTime:(CGFloat)t start:(CGFloat)b change:(CGFloat)c duration:(CGFloat)d
{
    if (t==0) {
        return b;
    }
    if (t==d) {
        return b+c;
    }
    if ((t/=d/2) < 1) {
        return c/2 * powf(2, 10 * (t-1)) + b;
    }
    return c/2 * (-powf(2, -10 * --t) + 2) + b;
}


@end