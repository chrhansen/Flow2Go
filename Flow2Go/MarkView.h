//
//  MarkView.h
//  MarkTester
//
//  Created by Christian Hansen on 12/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MarkView;

@protocol MarkViewDelegate <NSObject>
// Datasource methods
- (NSUInteger)numberOfPathsInMarkView:(id)sender;
- (NSArray *)verticesForPath:(NSUInteger)pathNo inView:(id)sender;

// Delegate methods
- (void)markView:(MarkView *)markView didDrawGate:(GateType)gateType withPoints:(NSArray *)pathPoints infoButton:(UIButton *)infoButton;
- (void)markView:(MarkView *)markView didTapInfoButtonForPath:(UIButton *)buttonWithTagNumber;

@end

@interface MarkView : UIView 

- (void)reloadPaths;

- (void)setReadyForGateOfType:(GateType)gateType;

@property (nonatomic, weak) id<MarkViewDelegate> delegate;

@end
