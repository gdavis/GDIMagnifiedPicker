//
//  GDIMagnifiedPickerView.m
//  GDIMagnifiedPicker
//
//  Created by Grant Davis on 2/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GDIMagnifiedPickerView.h"

@interface GDIMagnifiedPickerView()

@property (strong,nonatomic) NSMutableArray *currentCells;
@property (nonatomic) CGFloat contentHeight;
@property (nonatomic) NSInteger indexOfFirstRow;
@property (nonatomic) NSInteger indexOfLastRow;
@property (nonatomic) NSUInteger totalRows;

- (void)initContentHeight;
- (void)build;
- (void)buildScrollView;
- (void)buildVisibleRows;
- (void)updateVisibleRows;

- (void)addTopRow;
- (void)addBottomRow;

- (void)removeTopRow;
- (void)removeBottomRow;

@end


@implementation GDIMagnifiedPickerView
@synthesize dataSource = _dataSource;
@synthesize delegate = _delegate;
@synthesize scrollView = _scrollView;

@synthesize currentCells = _currentCells;
@synthesize contentHeight = _contentHeight;
@synthesize indexOfFirstRow = _indexOfFirstRow;
@synthesize indexOfLastRow = _indexOfLastRow;
@synthesize totalRows = _totalRows;


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


- (void)build
{
    [self initContentHeight];
    [self buildScrollView];
    [self buildVisibleRows];
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


#pragma mark - UIScrollView Delegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self updateVisibleRows];
}

@end