//
//  FCSFile20Data.m
//  FCSViewer
//
//  Created by Christian Hansen on 2/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FCSFile20Data.h"
#import <stdint.h>

@interface FCSFile20Data ()

@end

@implementation FCSFile20Data
@synthesize events = _events;
@synthesize event = _event;
@synthesize parameter = _parameter;
@synthesize maxValues = _maxValues;


+ (FCSFile20Data *)dataWithFCSFile:(NSString *)fcsFile inRange:(NSRange)aRange noOfParameters:(NSUInteger)noOfPar noOfEvents:(NSUInteger)noOfEvents andTextDescription:(FCSFile20Text *)fcsText;
{
    FCSFile20Data *newFCSData = [[super alloc] init];
    
    NSError *dataReadingError;
    NSData *fileData = [NSData dataWithContentsOfFile:fcsFile options:NSDataReadingUncached error:&dataReadingError];

    //Allocate memory for data array 
    newFCSData.event = malloc(noOfEvents * sizeof(NSUInteger *));
    for (NSUInteger i = 0; i < noOfEvents; i++) {
        newFCSData.event[i] = malloc(noOfPar * sizeof(NSUInteger));
    }
    
    NSUInteger  dataPosition  = 0;
    CFByteOrder fileByteorder = CFByteOrderLittleEndian; //(CFByteOrder)[[fcsText.dictionary objectForKey:@"$BYTEORD"] integerValue];
    NSUInteger  byteSize      =              16; //[[fcsText.dictionary objectForKey:@"$P1B"] integerValue];

    UInt16 bytes16[aRange.length/2];
    //UInt32 bytes32[aRange.length/4];
    [fileData getBytes:bytes16 range:aRange];
    
    if (byteSize == 16)
    {
        
    } 
    else if (byteSize == 32) 
    {
        //free(bytes16);
        //[fileData getBytes:bytes32 range:aRange];
    }
    fileData = nil;
    
    
    NSLog(@"Start reading events from data buffer");
    
    for (NSUInteger event = 0; event < noOfEvents; event++) 
    {
        for (NSUInteger parameter = 0; parameter < noOfPar; parameter++) 
        {
            switch (byteSize) 
            {
                case 16:
                    if (fileByteorder != CFByteOrderGetCurrent()) 
                    {
                        newFCSData.event[event][parameter] = bytes16[dataPosition++];//[[NSString stringWithFormat:@"%hu", bytes[dataPosition++]] integerValue];
                    } 
                    else
                    {
                        newFCSData.event[event][parameter] = CFSwapInt16(bytes16[dataPosition++]);//CFSwapInt16([[NSString stringWithFormat:@"%hu", bytes[dataPosition++]] integerValue]);
                    }
                    break;
                case 32:
                    if (fileByteorder != CFByteOrderGetCurrent()) 
                    {
                        //newFCSData.event[event][parameter] = [[NSString stringWithFormat:@"%u", bytes32[dataPosition++]] integerValue];
                    } 
                    else
                    {
                        //newFCSData.event[event][parameter] = CFSwapInt16([[NSString stringWithFormat:@"%u", bytes32[dataPosition++]] integerValue]);
                    }
                    break;
                default:
                    break;
            }
        }
    }

    [FCSFile20Data _printOut:100 forPars:6 forArray:newFCSData];
    
    NSLog(@"End reading events from data buffer");
    
    newFCSData.maxValues = calloc(noOfPar, sizeof(NSUInteger));
    
    for (NSUInteger event = 0; event < noOfEvents; event++) 
    {
        for (NSUInteger parameter = 0; parameter < noOfPar; parameter++) 
        {
            if (newFCSData.event[event][parameter] > newFCSData.maxValues[parameter]) 
            {
                newFCSData.maxValues[parameter] = newFCSData.event[event][parameter];
            }            
        }
    }
    
    
    return newFCSData;
}


- (NSNumber *)aNumberBytesize:(NSUInteger)byteSize endianNess:(CFByteOrder)byteOrder inBytes:(UInt16 *)bytes atPosition:(NSUInteger)dataPosition
{
    switch (byteSize) 
    {
        case 16:
            if (byteOrder != CFByteOrderGetCurrent()) 
            {
                return [NSNumber numberWithInteger:[[NSString stringWithFormat:@"%hu", bytes[dataPosition++]] integerValue]];
            } 
            else
            {
                return [NSNumber numberWithInteger:CFSwapInt16([[NSString stringWithFormat:@"%hu", bytes[dataPosition++]] integerValue])];
            }
            break;
        case 32:
            if (byteOrder != CFByteOrderGetCurrent()) 
            {
                return [NSNumber numberWithInteger:[[NSString stringWithFormat:@"%u", bytes[dataPosition++]] integerValue]];
            } 
            else
            {
                return [NSNumber numberWithInteger:CFSwapInt16([[NSString stringWithFormat:@"%u", bytes[dataPosition++]] integerValue])];
            }
            break;
            
        default:
            break;
    }
    return [NSNumber numberWithInteger:0];
}

+ (void)_printOut:(NSUInteger)noOfEvents forPars:(NSUInteger)noOfParams forArray:(FCSFile20Data *)fcsData
{
    for (NSUInteger i = 0; i < noOfEvents; i++)
    {
        NSLog(@"eventNo:(%i)", i);
        for (NSUInteger j = 0; j < noOfParams; j++)
        {
            NSLog(@"parNo:(%i) , value: %i", j, fcsData.event[i][j]);
        }
    }
}

@end
