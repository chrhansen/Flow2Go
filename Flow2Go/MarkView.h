//
//  MarkView.h
//  MarkTester
//
//  Created by Christian Hansen on 12/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol MarkViewDelegate <NSObject>

- (void)didDrawPath:(CGPathRef)pathRef withPoints:(NSArray *)pathPoints insideRect:(CGRect)boundingRect sender:(id)sender;

@end

@interface MarkView : UIView 

- (void)drawPathWithPoints:(NSArray *)pathPoints;

@property (nonatomic, weak) id<MarkViewDelegate> delegate;

@end
