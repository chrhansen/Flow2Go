 //
//  FCSFile.m
//  Flow2Go
//
//  Created by Christian Hansen on 05/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import "FGFCSFile.h"
#import "FGFCSHeader.h"

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

@interface FGFCSFile ()

@property (nonatomic) FGFCSHeader *header;
@property (nonatomic) NSUInteger bitsPerEvent;
@property (nonatomic, strong) NSCharacterSet *seperatorCharacterset;

@end

@implementation FGFCSFile

+ (void)readFCSFileAtPath:(NSString *)path progressDelegate:(id<FGFCSProgressDelegate>)progressDelegate withCompletion:(void (^)(NSError *error, FGFCSFile *fcsFile))completion
{
    dispatch_queue_t readerQueue = dispatch_queue_create("it.calcul8.flow2go.fcsreader", NULL);
    dispatch_async(readerQueue, ^{

        return;
    });
}


+ (FGFCSFile *)fcsFileWithPath:(NSString *)path error:(NSError **)error
{
    FGFCSFile *newFCSFile = [FGFCSFile.alloc init];
    
    BOOL succes = [newFCSFile _parseFileFromPath:path];
    
    if (succes) {
        return newFCSFile;
    }
    
    if (error != NULL)
    {
        NSDictionary *errorDictionary = @{ NSLocalizedDescriptionKey : NSLocalizedString(@"Error: FCS file could not be read", nil)};
        *error = [[NSError alloc] initWithDomain:FCSFile_Error_Domain code:-1 userInfo:errorDictionary];
    }
    return nil;
}

+ (NSDictionary *)fcsKeywordsWithFCSFileAtPath:(NSString *)path
{
    FGFCSFile *newFCSFile = [FGFCSFile.alloc init];
    [newFCSFile _parseTextSegmentFromPath:path];
    return newFCSFile.text;
}


- (void)_parseTextSegmentFromPath:(NSString *)path
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
                    [fcsFileStream close];
                }
                else
                {
                    parsingSegment = kParsingSegmentFailed;
                }
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


- (BOOL)_parseFileFromPath:(NSString *)path
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
                return NO;
                break;
                
            default:
                NSLog(@"no known parsing segment");
                [fcsFileStream close];
                break;
        }
    }
    return YES;
}


- (BOOL)_readHeaderSegmentFromInputStream:(NSInputStream *)inputStream
{
    uint8_t buffer[HEADER_LENGTH];
    NSUInteger bytesRead = [inputStream read:buffer maxLength:sizeof(buffer)];
    NSString *headerString = [NSString.alloc initWithBytes:buffer
                                                    length:bytesRead
                                                  encoding:NSASCIIStringEncoding];
    
    if (!headerString || headerString.length < HEADER_LENGTH)
    {
        NSLog(@"Error: Header string not valid");
        return NO;
    }
    self.header = FGFCSHeader.alloc.init;
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
        NSLog(@"Error: Text string not valid");
        return NO;
    }
    
    self.seperatorCharacterset = [NSCharacterSet characterSetWithCharactersInString:[textString substringToIndex:1]];
    NSArray *textSeparated = [[textString substringFromIndex:1] componentsSeparatedByCharactersInSet:self.seperatorCharacterset];
    
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
        return YES;
    }
    return NO;
}


- (BOOL)_readDataSegmentFromInputStream:(NSInputStream *)inputStream from:(NSUInteger)firstByte to:(NSUInteger)lastByte
{
    [self _setInputStream:inputStream toPosition:firstByte];
    
    _noOfEvents = [self.text[@"$TOT"] integerValue];
    NSUInteger noOfParams = [self.text[@"$PAR"] integerValue];
    self.noOfParams = noOfParams;
    
    if (_noOfEvents == 0
        || noOfParams == 0)
    {
        return NO;
    }

    [self allocateDataArrayWithType:self.text[@"$DATATYPE"] forParameters:noOfParams];
    
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
                        self.events[eventNo][parNo] = (double)bufferOneEvent[byteOffset];
                        byteOffset += 1;
                        break;
                        
                    case kParSize16:
                        if (byteOrder == CFByteOrderBigEndian)
                        {
                            self.events[eventNo][parNo] = (double)((bufferOneEvent[byteOffset] << 8) | bufferOneEvent[byteOffset + 1]);
                        }
                        else
                        {
                            self.events[eventNo][parNo] = (double)((bufferOneEvent[byteOffset + 1] << 8) | bufferOneEvent[byteOffset]);
                        }
                        byteOffset += 2;
                        break;
                        
                    case kParSize32:
                        if (byteOrder == CFByteOrderBigEndian)
                        {
                            self.events[eventNo][parNo] = (double)((bufferOneEvent[byteOffset] << 24) | (bufferOneEvent[byteOffset + 1]  << 16) | (bufferOneEvent[byteOffset + 2]  << 8) | bufferOneEvent[byteOffset + 3]);
                        }
                        else
                        {
                            self.events[eventNo][parNo] = (double)((bufferOneEvent[byteOffset + 3] << 24) | (bufferOneEvent[byteOffset + 2]  << 16) | (bufferOneEvent[byteOffset + 1]  << 8) | bufferOneEvent[byteOffset]);
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
    
    if (parSizes) free(parSizes);
    
    [self _convertChannelValuesToScaleValues:self.events];
    [self _applyCompensationToScaleValues:self.events];
    [self _applyCalibrationToScaledValues:self.events];
    //[self _printOut:100 forPars:noOfParams];
    //[self _printOutScaledMinMax];
    
    return YES;
}

- (BOOL)_readAnalysisSegmentFromInputStream:(NSInputStream *)inputStream from:(NSUInteger)firstByte to:(NSUInteger)lastByte
{
    if (firstByte == 0
        || lastByte == 0)
    {
        return NO;
    }
    
    [self _setInputStream:inputStream toPosition:firstByte];
    
    uint8_t buffer[lastByte-firstByte];
    NSUInteger bytesRead = [inputStream read:buffer maxLength:sizeof(buffer)];
    NSString *analysisString = [NSString.alloc initWithBytes:buffer
                                                      length:bytesRead
                                                    encoding:NSASCIIStringEncoding];
    
    if (!analysisString)
    {
        NSLog(@"analysis string not valid");
        return NO;
    }
    
    if (!self.seperatorCharacterset)
    {
        NSLog(@"self.seperatorCharacterset in Analysis Segment not set");
    }
    NSArray *textSeparated = [[analysisString substringFromIndex:1] componentsSeparatedByCharactersInSet:self.seperatorCharacterset];
    
    NSMutableDictionary *analysisKeyValuePairs = [NSMutableDictionary dictionary];
    
    for (int i = 0; i < textSeparated.count; i += 2)
    {
        if (i + 1 < textSeparated.count)
        {
            [analysisKeyValuePairs setObject:textSeparated[i+1] forKey:[textSeparated[i] uppercaseString]];
        }
    }
    
    if (analysisKeyValuePairs.count > 0)
    {
        self.analysis = [NSDictionary dictionaryWithDictionary:analysisKeyValuePairs];
        return YES;
    }
    return NO;
}


- (void)allocateDataArrayWithType:(NSString *)dataTypeString forParameters:(NSUInteger)noOfParams
{
    if ([dataTypeString isEqualToString: @"I"])
    {
        self.events = calloc(_noOfEvents, sizeof(NSUInteger *));
        for (NSUInteger i = 0; i < _noOfEvents; i++)
        {
            self.events[i] = calloc(noOfParams, sizeof(double));
        }
        return;
    }
    
    if ([dataTypeString isEqualToString: @"F"])
    {
        NSLog(@"allocating float type: %@", dataTypeString);
        self.events = calloc(_noOfEvents, sizeof(NSUInteger *));
        for (NSUInteger i = 0; i < _noOfEvents; i++)
        {
            self.events[i] = calloc(noOfParams, sizeof(double));
        }
        return;
    }
    if ([dataTypeString isEqualToString: @"D"])
    {
        NSLog(@"allocating double type: %@", dataTypeString);
        self.events = calloc(_noOfEvents, sizeof(NSUInteger *));
        for (NSUInteger i = 0; i < _noOfEvents; i++)
        {
            self.events[i] = calloc(noOfParams, sizeof(double));
        }
        return;
    }
}


- (kParSize *)_getParameterSizes:(NSUInteger)numberOfParameters
{
    kParSize *parameterSizes = calloc(numberOfParameters, sizeof(kParSize));
    self.bitsPerEvent = 0;
    
    for (NSUInteger parNO = 0; parNO < numberOfParameters; parNO++)
    {
        NSString *key = [@"$P" stringByAppendingFormat:@"%iB", parNO + 1];
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


- (void)_convertChannelValuesToScaleValues:(double **)eventsAsChannelValues
{
    self.ranges = calloc(_noOfParams, sizeof(FGRange));

    for (NSUInteger parNo = 0; parNo < _noOfParams; parNo++)
    {
        NSString *scaleString = self.text[[@"$P" stringByAppendingFormat:@"%iE", parNo + 1]];
        if (!scaleString) NSLog(@"Required scale Value for par %i not found.", parNo + 1);
        
        NSArray *scaleComponents = [scaleString componentsSeparatedByString:@","];
        double f1 = [scaleComponents[0] doubleValue];
        double f2 = [scaleComponents[1] doubleValue];
        double g = [self _gainValueWithString:self.text[[@"$P" stringByAppendingFormat:@"%iG", parNo + 1]]];
        double range = [self.text[[@"$P" stringByAppendingFormat:@"%iR", parNo + 1]] doubleValue] - 1.0;
        FGAxisType valueType;
        if (f1 <= 0.0)
        {
            valueType = kAxisTypeLinear;
            self.ranges[parNo].minValue = 0.0;
            self.ranges[parNo].maxValue = range / g;
        }
        else if (f1 > 0.0)
        {
            valueType = kAxisTypeLogarithmic;
            if (f2 == 0.0) f2 = 1.0; // some files has f2 for log-values errouneously set to 0
            
            self.ranges[parNo].minValue = f2;
            self.ranges[parNo].maxValue = pow(10, f1 + log10(f2));
        }
    
//        NSLog(@"Par%i,(f1,f2)=(%f,%f), g= %f, RangeValue (value=%f) (%f,%f)", parNo + 1, f1, f2, g, range + 1.0,self.ranges[parNo].minValue, self.ranges[parNo].maxValue);
        for (NSUInteger eventNo = 0; eventNo < _noOfEvents; eventNo++)
        {
            switch (valueType)
            {
                case kAxisTypeLinear:
                    eventsAsChannelValues[eventNo][parNo] = eventsAsChannelValues[eventNo][parNo] / g;
                    break;
                    
                case kAxisTypeLogarithmic:
                    eventsAsChannelValues[eventNo][parNo] = pow(10, f1 * eventsAsChannelValues[eventNo][parNo] / range) * f2;
                    break;
                    
                default:
                    NSLog(@"neither linear or logarithmic, for parameter %i", parNo + 1);
                    break;
            }
        }
    }
}



- (double)_gainValueWithString:(NSString *)gString
{
    // default is 1.0 if $PiG is not present
    if (gString)
    {
        double g = gString.doubleValue;
        if (g == 0.0)
        {
            NSLog(@"Amplifier gain value is zero (g = %f).", g);
        }
        else
        {
            return g;
        }
    }
    return 1.0;
}


- (void)_applyCompensationToScaleValues:(double **)eventsAsScaledValues
{
    NSString *spillOverString = self.text[@"$SPILLOVER"];
    if (spillOverString == nil)
    {        
        return;
    }
    NSLog(@"Alert! ----------- Found spillover/compensation ----------");

    NSArray *spillOverArray = [spillOverString componentsSeparatedByString:@","];
    if (spillOverArray.count == 0)
    {
        NSLog(@"Error: No spill over components found: %@", spillOverString);
        return;
    }
    NSUInteger n = [spillOverArray[0] unsignedIntegerValue];
    if (spillOverArray.count < 1 + n + n * n) {
        NSLog(@"Error: Not all required spill over parameters found: %@", spillOverString);
        return;
    }

    double spillOverMatrix[n*n];
    for (NSUInteger i = 0; i < n * n; n++)
    {
        spillOverMatrix[i] = [spillOverArray[1 + n + (i + 1)] doubleValue];
    }
    
    NSLog(@"Spill over string: %@", spillOverString);
    for (NSUInteger i = 0; i < n * n; i++)
    {
        NSLog(@"(%i): %f", i, spillOverMatrix[i]);
    }
    // construct row vector of one event, e
    
    // invert spill over matrix
    
    // multiply, e x S-1 to get compensated value
    
}


- (void)_applyCalibrationToScaledValues:(double **)eventsAsScaledValues
{
    NSMutableDictionary *unitNames = nil;
    for (NSUInteger parNo = 0; parNo < _noOfParams; parNo++)
    {
        NSString *calibrationString = self.text[[@"$P" stringByAppendingFormat:@"%iCALIBRATION", parNo + 1]];
        if (calibrationString)
        {
            NSLog(@"Alert! ----------- Found calibration for parameter %i. ----------", parNo + 1);

            NSArray *calibrationComponents = [calibrationString componentsSeparatedByString:@","];
            if (calibrationComponents.count < 2)
            {
                NSLog(@"Error: Not enough calibration components for parameter %i.", parNo + 1);
                break;
            }
            if (!unitNames)
            {
                unitNames = NSMutableArray.array;
            }
            double f = [calibrationComponents[0] doubleValue];
            NSString *unitNameWithBraces = [@"[" stringByAppendingFormat:@"%@]", calibrationComponents[1]];
            [unitNames setObject:unitNameWithBraces forKey:[NSString stringWithFormat:@"%i", parNo + 1]];
            for (NSUInteger eventNo = 0; eventNo < _noOfEvents; eventNo++)
            {
                eventsAsScaledValues[eventNo][parNo] = eventsAsScaledValues[eventNo][parNo] * f;
            }
            self.ranges[parNo].minValue = self.ranges[parNo].minValue * f;
            self.ranges[parNo].maxValue = self.ranges[parNo].maxValue * f;
        }
    }
    if (unitNames)
    {
        self.calibrationUnitNames = [NSDictionary dictionaryWithDictionary:unitNames];
    }
    else
    {
        NSLog(@"No calibration keyword");
    }
}


- (void)_printOut:(NSUInteger)noOfEvents forPars:(NSUInteger)noOfParams
{
    for (NSUInteger i = 0; i < noOfEvents; i++)
    {
        NSLog(@"eventNo:(%i)", i);
        for (NSUInteger j = 0; j < noOfParams; j++)
        {
            NSLog(@"parNo:(%i) , value: %f", j, self.events[i][j]);
        }
    }
}
- (void)_printOutScaledMinMax
{
    for (NSUInteger parNo = 0; parNo < _noOfParams; parNo++)
    {
        double maxValue = 0.0;
        double minValue = 500.0;
        for (NSUInteger eventNo = 0; eventNo < self.noOfEvents; eventNo++)
        {
            if (self.events[eventNo][parNo] > maxValue)
            {
                maxValue = self.events[eventNo][parNo];
            }
            if (self.events[eventNo][parNo] < minValue)
            {
                minValue = self.events[eventNo][parNo];
            }
        }
        NSLog(@"Actual Par %i, min: %f, max: %f", parNo + 1, minValue, maxValue);
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


#pragma mark - Public methods

+ (NSInteger)parameterNumberForName:(NSString *)PiNShortName inFCSFile:(FGFCSFile *)fcsFile
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

+ (NSString *)parameterShortNameForParameterIndex:(NSInteger)parameterIndex inFCSFile:(FGFCSFile *)fcsFile
{
    NSString *shortNameKey = [@"$P" stringByAppendingFormat:@"%iN", parameterIndex + 1];
    
    return fcsFile.text[shortNameKey];
}


+ (NSString *)parameterNameForParameterIndex:(NSInteger)parameterIndex inFCSFile:(FGFCSFile *)fcsFile
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


- (NSInteger)rangeOfParameterIndex:(NSInteger)parameterIndex
{
    NSString *rangeKey = [@"$P" stringByAppendingFormat:@"%iR", parameterIndex + 1];
    return [self.text[rangeKey] integerValue];
}


- (FGAxisType)axisTypeForParameterIndex:(NSInteger)parameterIndex
{
    NSString *scaleString = self.text[[@"$P" stringByAppendingFormat:@"%iE", parameterIndex + 1]];
    if (!scaleString) NSLog(@"Required scale Value for par %i not found.", parameterIndex + 1);
    
    NSArray *scaleComponents = [scaleString componentsSeparatedByString:@","];
    double f1 = [scaleComponents[0] doubleValue];
    if (f1 <= 0.0)
    {
        return kAxisTypeLinear;
    }
    else
    {
        return kAxisTypeLogarithmic;
    }
}

- (void)cleanUpEvents
{
    for (NSUInteger i = 0; i < _noOfEvents; i++) {
        free(_events[i]);
    }
    free(self.events);
    free(self.ranges);
}

@end
