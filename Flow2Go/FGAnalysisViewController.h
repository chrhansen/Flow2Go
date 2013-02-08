//
//  AnalysisViewController.h
//  Flow2Go
//
//  Created by Christian Hansen on 21/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import <UIKit/UIKit.h>
@class FGAnalysis;
@class FGMeasurement;

@interface FGAnalysisViewController : UICollectionViewController <UICollectionViewDataSource, UICollectionViewDelegate, UISplitViewControllerDelegate>

- (void)showAnalysis:(FGAnalysis *)analysis;

@property (nonatomic, strong) FGAnalysis *analysis;

@end
