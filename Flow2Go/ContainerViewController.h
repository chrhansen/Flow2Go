//
//  ContainerViewController.h
//  Flow2Go
//
//  Created by Christian Hansen on 20/09/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AnalysisPresentationProtocol.h"

@class Folder;

@interface ContainerViewController : UIViewController <AnalysisPresentationProtocol>

@property (strong, nonatomic) IBOutlet UIView *analysisContainerView;
@property (strong, nonatomic) IBOutlet UIView *measurementContainerView;
@property (strong, nonatomic) Folder *folder;


@end
