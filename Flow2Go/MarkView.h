//
//  MarkView.h
//  MarkTester
//
//  Created by Christian Hansen on 12/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol MarkViewDelegate <NSObject>

// Datasource methods
- (NSUInteger)numberOfPathsInMarkView:(id)sender;
- (NSArray *)verticesForPath:(NSUInteger)pathNo inView:(id)sender;

// Delegate methods
- (void)didDrawPath:(CGPathRef)pathRef withPoints:(NSArray *)pathPoints insideRect:(CGRect)boundingRect sender:(id)sender;
- (void)didDoubleTapPathNumber:(NSUInteger)pathNumber;
- (void)didDoubleTapAtPoint:(CGPoint)point;


@end

@interface MarkView : UIView 

- (void)reloadPaths;

@property (nonatomic, weak) id<MarkViewDelegate> delegate;

@end
