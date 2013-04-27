//
//  FGFCSAnalysis.h
//  Flow2Go
//
//  Created by Christian Hansen on 26/04/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FGFCSAnalysis : NSObject

@property (nonatomic, strong) NSDictionary *analysisKeywords;

- (NSError *)parseAnalysisSegmentFromData:(NSData *)analysisData seperator:(NSCharacterSet *)seperatorCharacterset;

@end
