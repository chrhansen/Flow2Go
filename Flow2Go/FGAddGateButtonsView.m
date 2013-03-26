//
//  FGAddGateButtonsView.m
//  Flow2Go
//
//  Created by Christian Hansen on 26/03/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import "FGAddGateButtonsView.h"

@implementation FGAddGateButtonsView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

#define RECTANGLE_GATE 1
#define POLYGON_GATE 2
#define ELLIPSE_GATE 3
#define QUADRANT_GATE 4
#define SINGLE_RANGE_GATE 5
#define TRIPLE_RANGE_GATE 6


- (IBAction)addGateButtonTapped:(UIButton *)sender
{
    switch (sender.tag)
    {
        case POLYGON_GATE:
            [self.delegate addGateButtonsView:self didSelectGate:kGateTypePolygon];
            break;
            
        case SINGLE_RANGE_GATE:
            [self.delegate addGateButtonsView:self didSelectGate:kGateTypeSingleRange];
            break;
            
        case TRIPLE_RANGE_GATE:
            [self.delegate addGateButtonsView:self didSelectGate:kGateTypeTripleRange];
            break;
            
        case RECTANGLE_GATE:
            [self.delegate addGateButtonsView:self didSelectGate:kGateTypeRectangle];
            break;
            
        case QUADRANT_GATE:
            [self.delegate addGateButtonsView:self didSelectGate:kGateTypeQuadrant];
            break;
            
        case ELLIPSE_GATE:
            [self.delegate addGateButtonsView:self didSelectGate:kGateTypeEllipse];
            break;
            
        default:
            break;
    }
}


- (void)updateButtons;
{
    FGPlotType plotType = [self.delegate addGateButtonsViewCurrentPlotType:self];
    if (plotType == kPlotTypeDot
        || plotType == kPlotTypeDensity)
    {
        [UIView animateWithDuration:0.5 animations:^{
            self.rectGateButton.alpha = 1.0f;
            self.polyGateButton.alpha = 1.0f;
            self.ovalGateButton.alpha = 1.0f;
            self.quadrantGateButton.alpha = 1.0f;
            self.singleRangeGateButton.alpha = 0.0f;
            self.tripleRangeGateButton.alpha = 0.0f;
        }];
    }
    else if (plotType == kPlotTypeHistogram)
    {
        [UIView animateWithDuration:0.5 animations:^{
            self.rectGateButton.alpha = 0.0f;
            self.polyGateButton.alpha = 0.0f;
            self.ovalGateButton.alpha = 0.0f;
            self.quadrantGateButton.alpha = 0.0f;
            self.singleRangeGateButton.alpha = 1.0f;
            self.tripleRangeGateButton.alpha = 1.0f;
        }];
    }
}


@end
