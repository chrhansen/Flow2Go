//
//  FCSFile20Text.m
//  FCSViewer
//
//  Created by Christian Hansen on 2/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FCSFile20Text.h"

@implementation FCSFile20Text

@synthesize dictionary = _dictionary;
@synthesize noOfParameters = _noOfParameters;
@synthesize parameterRanges = _parameterRanges;
@synthesize parameterRange = _parameterRange;
@synthesize parameterNames = _parameterNames;

+ (FCSFile20Text *)textWithFCSFile:(NSString *)fcsFile inRange:(NSRange)aRange;
{
    FCSFile20Text *newFCSText = [[super alloc] init];
    
    NSError *dataReadingError;
    NSData *fileData = [NSData dataWithContentsOfFile:fcsFile options:NSDataReadingUncached error:&dataReadingError];
    UInt8 bytes[aRange.length];
    [fileData getBytes:bytes range:aRange];
    
    NSString *textAsString = [[NSString alloc] initWithBytes:bytes length:aRange.length encoding:NSASCIIStringEncoding];
    NSLog(@"textAsString: %@", textAsString);
    NSString *seperatorCharacter = [textAsString substringToIndex:1];
    NSArray *textSeparated = [textAsString componentsSeparatedByString:seperatorCharacter];
    
    NSMutableDictionary *textKeyValuePairs = [NSMutableDictionary dictionary];
    
    for (int i = 0; i < [textSeparated count]; i++) 
    {
        NSString *aPossibleKeyword = [textSeparated objectAtIndex:i];
        if ([aPossibleKeyword hasPrefix:@"$"] || [aPossibleKeyword hasPrefix:@"@"]) 
        {
            [textKeyValuePairs setValue:[textSeparated objectAtIndex:i+1] forKey:aPossibleKeyword];
        }
    }
    
    NSLog(@"string byteorder: %@", [textKeyValuePairs objectForKey:@"$BYTEORD"]);
    
    NSNumber *fileByteorder = [self getByteorderOfDescriptionString:[textKeyValuePairs objectForKey:@"$BYTEORD"]];
    [textKeyValuePairs setValue:fileByteorder forKey:@"$BYTEORD"];
    
    newFCSText.dictionary = [NSDictionary dictionaryWithDictionary:textKeyValuePairs];
    newFCSText.noOfParameters = [[newFCSText.dictionary objectForKey:@"$PAR"] integerValue];
    
    newFCSText.parameterRange = calloc(newFCSText.noOfParameters, sizeof(NSUInteger));
    
    NSMutableArray *myParameterNames = [NSMutableArray arrayWithObjects: nil];
    NSMutableArray *myParameterRanges = [NSMutableArray arrayWithObjects: nil];

    for (NSUInteger i = 1; i <= newFCSText.noOfParameters; i++) {
        NSString *prefix = [@"$P" stringByAppendingString:[NSString stringWithFormat:@"%d", i]];
        NSString *nameKey = [prefix stringByAppendingString:@"S"];
        NSString *shortNameKey = [prefix stringByAppendingString:@"N"];
        NSString *rangeKey = [prefix stringByAppendingString:@"R"];
        
        NSString *parname = [newFCSText.dictionary valueForKey:nameKey];
        NSString *shortName = [newFCSText.dictionary valueForKey:shortNameKey];
        NSString *range = [newFCSText.dictionary valueForKey:rangeKey];
                
        NSLog(@"ByteSize: %@", [newFCSText.dictionary objectForKey:[prefix stringByAppendingString:@"B"]]);

        
        if (range) {
            [myParameterRanges addObject:[NSNumber numberWithInteger:[range integerValue]]];
            newFCSText.parameterRange[i-1] = [range integerValue];
        } else {
            NSLog(@"Range for parameter %d not found", i);
        }
        
        NSLog(@"Range %@ = %@", rangeKey, range);
        
        if (![parname isEqualToString:@""] && ![shortName isEqualToString:@""]  && parname != nil) {
            [myParameterNames addObject:[[shortName stringByAppendingString:@" - "] stringByAppendingString:parname]]; 
        } else if (shortName) {
            [myParameterNames addObject:shortName]; 
        } else if (parname) {
            [myParameterNames addObject:parname]; 
        } else {
            [myParameterNames addObject:[@"Parameter " stringByAppendingString:[NSString stringWithFormat:@"%d", i]]]; 
        } 
    }
    newFCSText.parameterRanges = [NSArray arrayWithArray:myParameterRanges];
    newFCSText.parameterNames = [NSArray arrayWithArray:myParameterNames];
    
    myParameterRanges = nil;
    textKeyValuePairs = nil;
    myParameterNames = nil;
    
    return newFCSText;
}


+ (NSNumber *)getByteorderOfDescriptionString:(NSString *)descriptionString
{
    NSArray *significantBytes = [descriptionString componentsSeparatedByString:@","];
    
    //Only one object in array, byte order ignored
    if (significantBytes.count == 1) {
        return [NSNumber numberWithInteger:CFByteOrderUnknown];
    }
    
    if (significantBytes.count > 1) {
        if ([[significantBytes objectAtIndex:0] integerValue] > [[significantBytes objectAtIndex:1] integerValue]) {
            return [NSNumber numberWithInteger:CFByteOrderLittleEndian];
        } else if ([[significantBytes objectAtIndex:0] integerValue] < [[significantBytes objectAtIndex:1] integerValue]) {
            return [NSNumber numberWithInteger:CFByteOrderBigEndian];
        }
    }
    return [NSNumber numberWithInteger:CFByteOrderUnknown];
}

@end
