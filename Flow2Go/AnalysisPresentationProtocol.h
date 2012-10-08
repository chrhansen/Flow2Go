//
//  AnalysisPresentationProtocol.h
//  Flow2Go
//
//  Created by Christian Hansen on 20/09/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import <Foundation/Foundation.h>
@class Analysis;

@protocol AnalysisPresentationProtocol <NSObject>

- (void)presentAnalysis:(Analysis *)analysis;

- (void)measurementViewController:(id)measurementViewController hasItemsSelected:(BOOL)hasItemsSelected;

@end
