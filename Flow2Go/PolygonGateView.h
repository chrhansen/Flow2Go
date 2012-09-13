//
//  PolygonGateView.h
//  GatesLayout
//
//  Created by Christian Hansen on 13/09/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GateView.h"

@interface PolygonGateView : GateView

- (PolygonGateView *)initWithFrame:(CGRect)frame polygonGateVertices:(NSArray *)vertices;



@end
