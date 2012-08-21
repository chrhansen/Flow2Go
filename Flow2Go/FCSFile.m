 //
//  FCSFile.m
//  Flow2Go
//
//  Created by Christian Hansen on 05/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import "FCSFile.h"
#import "FCSHeader.h"

typedef enum
{
    kParsingSegmentHeader,
    kParsingSegmentText,
    kParsingSegmentData,
    kParsingSegmentAnalysis,
    kParsingSegmentFailed
} kParsingSegment;

typedef enum
{
    kParSizeUnknown,
    kParSize8,
    kParSize16,
    kParSize32,
} kParSize;

@interface FCSFile ()

@property (nonatomic) FCSHeader *header;
@property (nonatomic) NSUInteger bitsPerEvent;

@end

@implementation FCSFile

+ (FCSFile *)fcsFileWithPath:(NSString *)path
{
    FCSFile *newFCSFile = [FCSFile.alloc init];
    
    [newFCSFile _parseFileFromPath:path];
    
    return newFCSFile;
}


- (void)_parseFileFromPath:(NSString *)path
{
    NSInputStream *fcsFileStream = [NSInputStream inputStreamWithFileAtPath:path];
    [fcsFileStream open];
    
    kParsingSegment parsingSegment = kParsingSegmentHeader;
    
    while ([fcsFileStream hasBytesAvailable])
    {
        switch (parsingSegment)
        {                
            case kParsingSegmentHeader:
                NSLog(@"CASE: kParsingSegmentHeader");
                if ([self _readHeaderSegmentFromInputStream:fcsFileStream])
                {
                    parsingSegment = kParsingSegmentText;
                }
                else
                {
                    parsingSegment = kParsingSegmentFailed;
                }
                break;
                
            case kParsingSegmentText:
                NSLog(@"CASE: kParsingSegmentText");
                if ([self _readTextSegmentFromInputStream:fcsFileStream from:self.header.textBegin to:self.header.textEnd])
                {
                    parsingSegment = kParsingSegmentData;
                }
                else
                {
                    parsingSegment = kParsingSegmentFailed;
                }
                break;
                
            case kParsingSegmentData:
                NSLog(@"CASE: kParsingSegmentData");
                if ([self _readDataSegmentFromInputStream:fcsFileStream from:self.header.dataBegin to:self.header.dataEnd])
                {
                    parsingSegment = kParsingSegmentAnalysis;
                }
                else
                {
                    parsingSegment = kParsingSegmentFailed;
                }
                break;
                
            case kParsingSegmentAnalysis:
                NSLog(@"CASE: kParsingSegmentAnalysis");
                [self _readAnalysisSegmentFromInputStream:fcsFileStream from:self.header.analysisBegin to:self.header.analysisEnd];
                [fcsFileStream close];

                break;
                
            case kParsingSegmentFailed:
                NSLog(@"CASE: kParsingSegmentFailed");
                [fcsFileStream close];
                break;
                
            default:
                NSLog(@"no known parsing segment");
                [fcsFileStream close];
                break;
        }
    }
}

- (BOOL)_readHeaderSegmentFromInputStream:(NSInputStream *)inputStream
{
    uint8_t buffer[HEADER_LENGTH];
    NSUInteger bytesRead = [inputStream read:buffer maxLength:sizeof(buffer)];
    NSString *headerString = [NSString.alloc initWithBytes:buffer
                                                    length:bytesRead
                                                  encoding:NSASCIIStringEncoding];
    NSLog(@"headerString: %@", headerString);
    
    if (!headerString || headerString.length < HEADER_LENGTH)
    {
        NSLog(@"header string not valid");
        return NO;
    }
    self.header = [FCSHeader.alloc init];
    self.header.textBegin     = [[headerString substringWithRange:NSMakeRange(10, 8)] integerValue];
    self.header.textEnd       = [[headerString substringWithRange:NSMakeRange(18, 8)] integerValue];
    self.header.dataBegin     = [[headerString substringWithRange:NSMakeRange(26, 8)] integerValue];
    self.header.dataEnd       = [[headerString substringWithRange:NSMakeRange(34, 8)] integerValue];
    self.header.analysisBegin = [[headerString substringWithRange:NSMakeRange(42, 8)] integerValue];
    self.header.analysisEnd   = [[headerString substringWithRange:NSMakeRange(50, 8)] integerValue];
    
    return YES;
}


- (BOOL)_readTextSegmentFromInputStream:(NSInputStream *)inputStream from:(NSUInteger)firstByte to:(NSUInteger)lastByte
{
    [self _setInputStream:inputStream toPosition:firstByte];

    uint8_t buffer[lastByte-firstByte];
    NSUInteger bytesRead = [inputStream read:buffer maxLength:sizeof(buffer)];
    NSString *textString = [NSString.alloc initWithBytes:buffer
                                                  length:bytesRead
                                                encoding:NSASCIIStringEncoding];
    
    if (!textString)
    {
        NSLog(@"text string not valid");
        return NO;
    }
    
    NSCharacterSet *seperatorCharacterset = [NSCharacterSet characterSetWithCharactersInString:[textString substringToIndex:1]];
    NSArray *textSeparated = [[textString substringFromIndex:1] componentsSeparatedByCharactersInSet:seperatorCharacterset];
    
    NSMutableDictionary *textKeyValuePairs = [NSMutableDictionary dictionary];
    
    for (int i = 0; i < textSeparated.count; i += 2)
    {
        if (i + 1 < textSeparated.count)
        {
            [textKeyValuePairs setObject:textSeparated[i+1] forKey:[textSeparated[i] uppercaseString]];
        }
    }
    
    if (textKeyValuePairs.count > 0)
    {
        self.text = [NSDictionary dictionaryWithDictionary:textKeyValuePairs];
        //NSLog(@"self.text: \n%@", self.text);
        return YES;
    }
    return NO;
}


- (BOOL)_readDataSegmentFromInputStream:(NSInputStream *)inputStream from:(NSUInteger)firstByte to:(NSUInteger)lastByte
{
    [self _setInputStream:inputStream toPosition:firstByte];
    
    _noOfEvents = [self.text[@"$TOT"] integerValue];
    NSUInteger noOfParams = [self.text[@"$PAR"] integerValue];
        
    if (_noOfEvents == 0
        || noOfParams == 0)
    {
        return NO;
    }

    self.event = calloc(_noOfEvents, sizeof(NSUInteger *));
    for (NSUInteger i = 0; i < _noOfEvents; i++)
    {
        self.event[i] = calloc(noOfParams, sizeof(NSUInteger));
    }
    
    kParSize *parSizes = [self _getParameterSizes:noOfParams];
    
    uint8_t bufferOneEvent[self.bitsPerEvent/8];
    CFByteOrder byteOrder = [self _byteOrderFromString:self.text[@"$BYTEORD"]];
    
    NSUInteger totalBytesRead = 0;
    NSInteger bytesRead = 0;
    NSUInteger eventNo = 0;
    
    while (totalBytesRead < lastByte - firstByte
           && [inputStream hasBytesAvailable])
    {
        bytesRead = [inputStream read:bufferOneEvent maxLength:sizeof(bufferOneEvent)];
        totalBytesRead += bytesRead;
        
        if (bytesRead > 0)
        {
            NSUInteger byteOffset = 0;
            for (NSUInteger parNo = 0; parNo < noOfParams; parNo++)
            {
                switch (parSizes[parNo])
                {
                    case kParSize8:
                        self.event[eventNo][parNo] = bufferOneEvent[byteOffset];
                        byteOffset += 1;
                        break;
                        
                    case kParSize16:
                        if (byteOrder == CFByteOrderBigEndian)
                        {
                            self.event[eventNo][parNo] = (bufferOneEvent[byteOffset] << 8) | bufferOneEvent[byteOffset + 1];
                        }
                        else
                        {
                            self.event[eventNo][parNo] = (bufferOneEvent[byteOffset + 1] << 8) | bufferOneEvent[byteOffset];
                        }
                        byteOffset += 2;
                        break;
                        
                    case kParSize32:
                        if (byteOrder == CFByteOrderBigEndian)
                        {
                            self.event[eventNo][parNo] = (bufferOneEvent[byteOffset] << 24) | (bufferOneEvent[byteOffset + 1]  << 16) | (bufferOneEvent[byteOffset + 2]  << 8) | bufferOneEvent[byteOffset + 3];
                        }
                        else
                        {
                            self.event[eventNo][parNo] = (bufferOneEvent[byteOffset + 3] << 24) | (bufferOneEvent[byteOffset + 2]  << 16) | (bufferOneEvent[byteOffset + 1]  << 8) | bufferOneEvent[byteOffset];
                        }
                        byteOffset += 4;
                        break;
                        
                    default:
                        break;
                }
            }
        }
        else
        {
            return NO;
        }
        eventNo++;
    }
    
    //[self _printOut:100 forPars:noOfParams];
    
    return YES;
}

- (BOOL)_readAnalysisSegmentFromInputStream:(NSInputStream *)inputStream from:(NSUInteger)firstByte to:(NSUInteger)lastByte
{
    if (firstByte == 0
        || lastByte == 0)
    {
        return NO;
    }
    
    //TODO: read analysis segment
    
    return YES;
}


- (kParSize *)_getParameterSizes:(NSUInteger)numberOfParameters
{
    kParSize *parameterSizes = calloc(numberOfParameters, sizeof(kParSize));
    self.bitsPerEvent = 0;
    
    for (NSUInteger parNO = 0; parNO < numberOfParameters; parNO++)
    {
        NSString *key = [@"$P" stringByAppendingFormat:@"%iB", parNO + 1];
        //NSLog(@"par size (%i): %@ , %@", parNO, key, self.text[key]);
        switch ([self.text[key] integerValue])
        {
            case 8:
                parameterSizes[parNO] = kParSize8;
                self.bitsPerEvent += 8;
                break;
             
            case 16:
                parameterSizes[parNO] = kParSize16;
                self.bitsPerEvent += 16;
                break;
                
            case 32:
                parameterSizes[parNO] = kParSize32;
                self.bitsPerEvent += 32;
                break;
                
            default:
                parameterSizes[parNO] = kParSizeUnknown;
                break;
        }
    }
    NSLog(@"self.bitsPerEvent: %i", _bitsPerEvent);
    
    return parameterSizes;
}

- (BOOL)_setInputStream:(NSInputStream *)inputStream toPosition:(NSUInteger)bytePosition
{
    NSUInteger currentByteOffset = [[inputStream propertyForKey:NSStreamFileCurrentOffsetKey] integerValue];
    if (currentByteOffset < bytePosition)
    {
        uint8_t wasteBuffer[bytePosition-currentByteOffset];
        [inputStream read:wasteBuffer maxLength:sizeof(wasteBuffer)];
    }
    if ([[inputStream propertyForKey:NSStreamFileCurrentOffsetKey] integerValue] == bytePosition)
    {
        return YES;
    }
    return NO;
}


- (void)_printOut:(NSUInteger)noOfEvents forPars:(NSUInteger)noOfParams
{
    for (NSUInteger i = 0; i < noOfEvents; i++)
    {
        NSLog(@"eventNo:(%i)", i);
        for (NSUInteger j = 0; j < noOfParams; j++)
        {
            NSLog(@"parNo:(%i) , value: %i", j, self.event[i][j]);
        }
    }
}

- (CFByteOrder)_byteOrderFromString:(NSString *)byteOrderString
{
    NSArray *byteOrderStrings = [byteOrderString componentsSeparatedByString:@","];
    
    if (byteOrderStrings.count < 2)
    {
        return CFByteOrderUnknown;
    }
    
    NSUInteger firstByte  = [byteOrderStrings[0] integerValue];
    NSUInteger secondByte = [byteOrderStrings[1] integerValue];

    if (firstByte < secondByte)
    {
        return CFByteOrderLittleEndian;
    }
    
    if (firstByte > secondByte)
    {
        return CFByteOrderBigEndian;
    }
    
    return CFByteOrderUnknown;
}


+ (NSInteger)parameterNumberForName:(NSString *)PiNShortName inFCSFile:(FCSFile *)fcsFile
{
    for (NSUInteger parNO = 0; parNO < [fcsFile.text[@"$PAR"] integerValue]; parNO++)
    {
        NSString *keyword = [@"$P" stringByAppendingFormat:@"%iS", parNO + 1];
        if ([PiNShortName isEqualToString:fcsFile.text[keyword]])
        {
            return parNO;
        }
    }
    return -1;
}

+ (NSString *)parameterShortNameForParameterIndex:(NSInteger)parameterIndex inFCSFile:(FCSFile *)fcsFile
{
    NSString *shortNameKey = [@"$P" stringByAppendingFormat:@"%iN", parameterIndex + 1];
    
    return fcsFile.text[shortNameKey];
}


+ (NSString *)parameterNameForParameterIndex:(NSInteger)parameterIndex inFCSFile:(FCSFile *)fcsFile
{
    NSString *shortNameKey = [@"$P" stringByAppendingFormat:@"%iN", parameterIndex + 1];
    NSString *longNameKey = [@"$P" stringByAppendingFormat:@"%iS", parameterIndex + 1];
    
    NSString *shortName = fcsFile.text[shortNameKey];
    NSString *longName = fcsFile.text[longNameKey];
    
    if (shortName
        && longName)
    {
        return [shortName stringByAppendingFormat:@" %@", longName];
    }
    else if (longName)
    {
        return longName;
    }
    else if (shortName)
    {
        return shortName;
    }
    return [@"Parameter" stringByAppendingFormat:@" %i", parameterIndex + 1];
}

@end
