//
//  GDIMagnifiedPickerView.m
//  GDIMagnifiedPicker
//
//  Created by Grant Davis on 2/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GDIMagnifiedPickerView.h"
#import <QuartzCore/QuartzCore.h>

@interface GDIMagnifiedPickerView()

@property (strong,nonatomic) NSMutableArray *currentCells;
@property (nonatomic) CGFloat contentHeight;
@property (nonatomic) NSInteger indexOfFirstRow;
@property (nonatomic) NSInteger indexOfLastRow;
@property (nonatomic) NSUInteger totalRows;
@property (nonatomic) CGFloat targetYOffset;

- (void)initContentHeight;

- (void)build;
- (void)buildScrollView;
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

@end


@implementation GDIMagnifiedPickerView
@synthesize dataSource = _dataSource;
@synthesize delegate = _delegate;
@synthesize scrollView = _scrollView;
@synthesize magnificationView = _magnificationView;

@synthesize currentCells = _currentCells;
@synthesize contentHeight = _contentHeight;
@synthesize indexOfFirstRow = _indexOfFirstRow;
@synthesize indexOfLastRow = _indexOfLastRow;
@synthesize totalRows = _totalRows;
@synthesize targetYOffset = _targetYOffset;


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


#pragma mark - Private Methods

- (void)initContentHeight
{
    _contentHeight = 0;
    _totalRows = [_dataSource numberOfRowsInMagnifiedPickerView:self];
    for (int i=0; i<_totalRows; i++) {
        _contentHeight += [_dataSource magnifiedPickerView:self heightForRowAtIndex:i];
    }
}


#pragma mark - Build Methods

- (void)build
{
    [self initContentHeight];
    [self buildScrollView];
    [self buildVisibleRows];
    [self buildMagnificationView];
}

- (void)buildScrollView 
{
    _scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
    _scrollView.delegate = self;
    _scrollView.contentSize = CGSizeMake(self.bounds.size.width, _contentHeight);
    _scrollView.clipsToBounds = NO;
    _scrollView.showsVerticalScrollIndicator = NO;
    [self addSubview:_scrollView];
}

- (void)buildVisibleRows
{
    _currentCells = [NSMutableArray array];
    _indexOfFirstRow = 0;
    
    CGFloat currentHeight = 0.f;
    
    for (int i=0; i<_totalRows; i++) {
        
        UIView *cellView = [_dataSource magnifiedPickerView:self viewForRowAtIndex:i];
        cellView.frame = CGRectMake(0, currentHeight, self.frame.size.width, [_dataSource magnifiedPickerView:self heightForRowAtIndex:i]);
        
        
        [_scrollView addSubview:cellView];
        [_currentCells addObject:cellView];
        
        currentHeight += cellView.frame.size.height;
        
        if (currentHeight >= self.frame.size.height) {
            _indexOfLastRow = i;
            break;
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
    if (firstRowView.frame.origin.y + firstRowView.frame.size.height < _scrollView.contentOffset.y) {
//        NSLog(@"remove top row");
        [self removeTopRow];
        [self updateVisibleRows];
    }
    else if (firstRowView.frame.origin.y - _scrollView.contentOffset.y >= 0 && _indexOfFirstRow > 0) {
//        NSLog(@"add top row");
        [self addTopRow];
        [self updateVisibleRows];
    }
    
    UIView *lastRowView = [_currentCells lastObject];
    if (lastRowView.frame.origin.y + lastRowView.frame.size.height - _scrollView.contentOffset.y < self.bounds.size.height && _indexOfLastRow+1 < _totalRows) {
//        NSLog(@"add bottom row");
        [self addBottomRow];
        [self updateVisibleRows];
    }
    else if (lastRowView.frame.origin.y - _scrollView.contentOffset.y > self.bounds.size.height && _indexOfLastRow-1 >= 0) {
//        NSLog(@"remove bottom row");
        [self removeBottomRow];
        [self updateVisibleRows];
    }
}


- (void)addTopRow
{
    _indexOfFirstRow--;
    
    UIView *curFirstRowView = [_currentCells objectAtIndex:0];
    CGFloat cellRowHeight = [_dataSource magnifiedPickerView:self heightForRowAtIndex:_indexOfFirstRow];
    CGFloat currentHeight = curFirstRowView.frame.origin.y - cellRowHeight;
    
    UIView *cellView = [_dataSource magnifiedPickerView:self viewForRowAtIndex:_indexOfFirstRow];
    cellView.frame = CGRectMake(0, currentHeight, self.frame.size.width, cellRowHeight);
    
    [_scrollView addSubview:cellView];
    [_currentCells insertObject:cellView atIndex:0];
}


- (void)addBottomRow
{
    _indexOfLastRow++;
    
    UIView *curLastRowView = [_currentCells lastObject];
    CGFloat cellRowHeight = [_dataSource magnifiedPickerView:self heightForRowAtIndex:_indexOfLastRow];
    CGFloat currentHeight = curLastRowView.frame.origin.y + curLastRowView.frame.size.height;
    
    UIView *cellView = [_dataSource magnifiedPickerView:self viewForRowAtIndex:_indexOfLastRow];
    cellView.frame = CGRectMake(0, currentHeight, self.frame.size.width, cellRowHeight);
    
    [_scrollView addSubview:cellView];
    [_currentCells addObject:cellView];
}


- (void)removeTopRow
{
    UIView *firstRowView = [_currentCells objectAtIndex:0];
    [firstRowView removeFromSuperview];
    [_currentCells removeObject:firstRowView];
    
    _indexOfFirstRow++;
}


- (void)removeBottomRow
{
    UIView *lastRowView = [_currentCells lastObject];
    [lastRowView removeFromSuperview];
    [_currentCells removeObject:lastRowView];
    
    _indexOfLastRow--;
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
        CGFloat distance = (cellCenter - _scrollView.contentOffset.y) - centerY;
        
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


#pragma mark - UIScrollView Delegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self updateVisibleRows];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    
}

@end