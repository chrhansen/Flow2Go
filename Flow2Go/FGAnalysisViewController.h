//
//  AnalysisViewController.h
//  Flow2Go
//
//  Created by Christian Hansen on 21/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import <UIKit/UIKit.h>
@class FGAnalysis;

@interface FGAnalysisViewController : UICollectionViewController <UICollectionViewDataSource, UICollectionViewDelegate>

- (void)showAnalysis:(FGAnalysis *)analysis;
- (void)addNavigationPaneBarbuttonWithTarget:(id)barButtonResponder selector:(SEL)barButtonSelector;

@property (nonatomic, strong) FGAnalysis *analysis;

@end
