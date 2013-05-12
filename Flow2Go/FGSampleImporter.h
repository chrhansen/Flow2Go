//
//  FGSampleImporter.h
//  Flow2Go
//
//  Created by Christian Hansen on 12/05/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FGFolder.h"
#import "FGMeasurement+Management.h"
#import "FGAnalysis+Management.h"

@interface FGSampleImporter : NSObject

+ (void)importSamplesIfFirstLaunch;

@end
