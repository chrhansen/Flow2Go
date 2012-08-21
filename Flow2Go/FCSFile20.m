//
//  FCSFile20.m
//  FCSViewer
//
//  Created by Christian Hansen on 2/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FCSFile20.h"

@interface FCSFile20 ()

@property (nonatomic) NSUInteger numberOfEventsListedInTextSection;

@end

@implementation FCSFile20

+ (FCSFile20 *)fcsFileWithPath:(NSString *)path loadData:(BOOL)loadDataSection;
{
    FCSFile20 *newFCSFile = [[super alloc] init];
    
    FCSFile20Header *fcsHeader = [FCSFile20Header headerWithFCSFile:path];
    newFCSFile.header = fcsHeader;
    
    NSLog(@"path: %@", path);
    NSLog(@"textRange: %@", NSStringFromRange(fcsHeader.textRange));
    
    FCSFile20Text *fcsText = [FCSFile20Text textWithFCSFile:path inRange:fcsHeader.textRange];
    newFCSFile.text = fcsText;
    newFCSFile.numberOfEventsListedInTextSection = [[newFCSFile.text.dictionary valueForKey:@"$TOT"] integerValue];
    fcsText = nil;
        
    if (loadDataSection) 
    {
        NSLog(@"Start reading data section in FCS-file");

        FCSFile20Data *fcsData = [FCSFile20Data dataWithFCSFile:path 
                                                        inRange:fcsHeader.dataRange 
                                                 noOfParameters:[[newFCSFile.text.dictionary valueForKey:@"$PAR"] integerValue] 
                                                     noOfEvents:[[newFCSFile.text.dictionary valueForKey:@"$TOT"] integerValue]
                                             andTextDescription:newFCSFile.text];
        NSLog(@"End reading data section in FCS-file");

        newFCSFile.data = fcsData;
        fcsData = nil;
    } 
    else 
    {
        newFCSFile.data = nil;
    }
    
    
    NSError *error;
    
    newFCSFile.fileContent = [NSString stringWithContentsOfFile:path encoding:NSASCIIStringEncoding error:&error];
    newFCSFile.initError = error;
    
    return newFCSFile;
}


- (NSUInteger)numOfEvents
{
    return _numberOfEventsListedInTextSection;
}


@end
