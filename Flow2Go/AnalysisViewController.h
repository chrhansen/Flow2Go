//
//  AnalysisViewController.h
//  Flow2Go
//
//  Created by Christian Hansen on 21/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import <UIKit/UIKit.h>
@class Analysis;
@class Measurement;

@interface AnalysisViewController : UICollectionViewController <UICollectionViewDataSource, UICollectionViewDelegate>

- (void)showAnalysis:(Analysis *)analysis forMeasurement:(Measurement *)measurement;

@end
