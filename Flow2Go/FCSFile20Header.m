//
//  FCSFile20Header.m
//  FCSViewer
//
//  Created by Christian Hansen on 2/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FCSFile20Header.h"

@implementation FCSFile20Header

@synthesize fcsVersion = _fcsVersion;
@synthesize text = _text;
@synthesize textRange = _textRange;
@synthesize dataRange = _dataRange;
@synthesize analysisRange = _analysisRange;
@synthesize byteOrder = _byteOrder;

+ (FCSFile20Header *)headerWithFCSFile:(NSString *)fcsFile
{
    FCSFile20Header *newFCSHeader = [[super alloc] init];
    
    NSError *dataReadingError;
    NSData *fileData = [NSData dataWithContentsOfFile:fcsFile options:NSDataReadingUncached error:&dataReadingError];
    const char *bytes[58];
    [fileData getBytes:bytes length:58];
    fileData = nil;
    
    newFCSHeader.text = [NSString.alloc initWithBytes:bytes length:58 encoding:NSASCIIStringEncoding];
    
    NSString *testString;
    [[fileData subdataWithRange:NSMakeRange(0, 58)] getBytes:&testString length:58];
    
    NSLog(@"newFCSHeader.text: %@", newFCSHeader.text);
        
    
    newFCSHeader.fcsVersion  =  [newFCSHeader.text substringWithRange:NSMakeRange(0, 10)];
    NSUInteger textBegin     = [[newFCSHeader.text substringWithRange:NSMakeRange(10, 8)] integerValue];
    NSUInteger textEnd       = [[newFCSHeader.text substringWithRange:NSMakeRange(18, 8)] integerValue];
    NSUInteger dataBegin     = [[newFCSHeader.text substringWithRange:NSMakeRange(26, 8)] integerValue];
    NSUInteger dataEnd       = [[newFCSHeader.text substringWithRange:NSMakeRange(34, 8)] integerValue];
    NSUInteger analysisBegin = [[newFCSHeader.text substringWithRange:NSMakeRange(42, 8)] integerValue];
    NSUInteger analysisEnd   = [[newFCSHeader.text substringWithRange:NSMakeRange(50, 8)] integerValue];
    
    newFCSHeader.textRange     = NSMakeRange(textBegin, textEnd - textBegin);
    newFCSHeader.dataRange     = NSMakeRange(dataBegin, dataEnd - dataBegin);
    newFCSHeader.analysisRange = NSMakeRange(analysisBegin, analysisEnd - analysisBegin);
    
    return newFCSHeader;
}


@end
