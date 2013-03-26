//
//  FGAddGateButtonsView.h
//  Flow2Go
//
//  Created by Christian Hansen on 26/03/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FGGateButtonsViewDelegate <NSObject>

- (FGPlotType)addGateButtonsViewCurrentPlotType:(id)sender;
- (void)addGateButtonsView:(id)sender didSelectGate:(FGGateType)gateType;

@end

@interface FGAddGateButtonsView : UIView

- (IBAction)addGateButtonTapped:(UIButton *)sender;
- (void)updateButtons;

@property (nonatomic, weak) IBOutlet UIButton *rectGateButton;
@property (nonatomic, weak) IBOutlet UIButton *polyGateButton;
@property (nonatomic, weak) IBOutlet UIButton *ovalGateButton;
@property (nonatomic, weak) IBOutlet UIButton *quadrantGateButton;
@property (nonatomic, weak) IBOutlet UIButton *singleRangeGateButton;
@property (nonatomic, weak) IBOutlet UIButton *tripleRangeGateButton;
@property (nonatomic, weak) id<FGGateButtonsViewDelegate> delegate;

@end
