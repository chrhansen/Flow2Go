//
//  FCSFile.m
//  Flow2Go
//
//  Created by Christian Hansen on 05/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import "FGFCSFile.h"
#import "FGFCSHeader.h"

typedef NS_ENUM(NSInteger, FGParameterSize)
{
    FGParameterSizeUnknown,
    FGParameterSize8,
    FGParameterSize16,
    FGParameterSize32,
};

@interface FGFCSFile ()

@property (nonatomic) FGFCSHeader *header;
@property (nonatomic) NSUInteger bitsPerEvent;
@property (nonatomic, strong) NSCharacterSet *seperatorCharacterset;

@end

@implementation FGFCSFile

+ (void)readFCSFileAtPath:(NSString *)path progressDelegate:(id<FGFCSProgressDelegate>)progressDelegate withCompletion:(void (^)(NSError *error, FGFCSFile *fcsFile))completion
{
    NSError *error = [self checkFilePath:path];
    if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(error, nil);
        });
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        FGFCSFile *newFCSFile = [FGFCSFile.alloc init];
        NSError *error = [newFCSFile _parseFileFromPath:path];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(error, newFCSFile);
            }
        });
        
    });
}


+ (FGFCSFile *)fcsFileWithPath:(NSString *)path error:(NSError **)error
{
    FGFCSFile *newFCSFile = [FGFCSFile.alloc init];
    
    *error = [newFCSFile _parseFileFromPath:path];
    
    if (!error) {
        return newFCSFile;
    }
    return nil;
}

+ (NSError *)checkFilePath:(NSString *)path
{
    NSError *error;
    if (!path) error = [NSError errorWithDomain:@"io.flow2go.fcsparser" code:-100 userInfo:@{@"userInfo": @"Error: Path for FCS file is nil."}];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) error = [NSError errorWithDomain:@"io.flow2go.fcsparser" code:-100 userInfo:@{@"userInfo": @"Error: no file at specified path."}];
    return error;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.parsingSegment = FGParsingSegmentBegan;
    }
    return self;
}

+ (NSDictionary *)fcsKeywordsWithFCSFileAtPath:(NSString *)path
{
    FGFCSFile *newFCSFile = [FGFCSFile.alloc init];
    [newFCSFile _parseTextSegmentFromPath:path];
    return newFCSFile.text;
}


- (NSError *)_parseTextSegmentFromPath:(NSString *)path
{
    NSError *error;
    NSInputStream *fcsFileStream = [NSInputStream inputStreamWithFileAtPath:path];
    [fcsFileStream open];
    
    while ([fcsFileStream hasBytesAvailable])
    {
        switch (_parsingSegment)
        {
            case FGParsingSegmentBegan:
                _parsingSegment = FGParsingSegmentHeader;
                break;
                
            case FGParsingSegmentHeader:
                error = [self _readHeaderSegmentFromStream:fcsFileStream];
                if (!error)
                {
                    _parsingSegment = FGParsingSegmentText;
                }
                else
                {
                    _parsingSegment = FGParsingSegmentFailed;
                }
                break;
                
            case FGParsingSegmentText:
                error = [self _readTextSegmentFromStream:fcsFileStream from:self.header.textBegin to:self.header.textEnd];
                if (!error)
                {
                    _parsingSegment = FGParsingSegmentData;
                }
                else
                {
                    _parsingSegment = FGParsingSegmentFailed;
                }
                break;
                
            case FGParsingSegmentFinished:
            case FGParsingSegmentFailed:
                [fcsFileStream close];
                break;
                
            default:
                error = [NSError errorWithDomain:@"io.flow2go.fcsparser" code:-100 userInfo:@{@"userInfo": @"Error: FCS parser ended in an unknown state."}];
                [fcsFileStream close];
                break;
        }
    }
    fcsFileStream = nil;
    return error;
}


- (NSError *)_parseFileFromPath:(NSString *)path
{
    NSError *error;
    NSInputStream *fcsFileStream = [NSInputStream inputStreamWithFileAtPath:path];
    [fcsFileStream open];
    
    while ([fcsFileStream hasBytesAvailable])
    {
        switch (_parsingSegment)
        {
            case FGParsingSegmentBegan:
                _parsingSegment = FGParsingSegmentHeader;
                break;
                
            case FGParsingSegmentHeader:
                error = [self _readHeaderSegmentFromStream:fcsFileStream];
                if (!error)
                {
                    _parsingSegment = FGParsingSegmentText;
                }
                else
                {
                    _parsingSegment = FGParsingSegmentFailed;
                }
                break;
                
            case FGParsingSegmentText:
                error = [self _readTextSegmentFromStream:fcsFileStream from:self.header.textBegin to:self.header.textEnd];
                if (!error)
                {
                    _parsingSegment = FGParsingSegmentData;
                }
                else
                {
                    _parsingSegment = FGParsingSegmentFailed;
                }
                break;
                
            case FGParsingSegmentData:
                error = [self _readDataSegmentFromStream:fcsFileStream from:self.header.dataBegin to:self.header.dataEnd];
                if (!error)
                {
                    _parsingSegment = FGParsingSegmentAnalysis;
                }
                else
                {
                    _parsingSegment = FGParsingSegmentFailed;
                }
                break;
                
            case FGParsingSegmentAnalysis:
                error = [self _readAnalysisSegmentFromStream:fcsFileStream from:self.header.analysisBegin to:self.header.analysisEnd];
                if (!error)
                {
                    _parsingSegment = FGParsingSegmentFinished;
                }
                else
                {
                    _parsingSegment = FGParsingSegmentFailed;
                }
                break;
                
            case FGParsingSegmentFinished:
            case FGParsingSegmentFailed:
                [fcsFileStream close];
                break;
                
            default:
                error = [NSError errorWithDomain:@"io.flow2go.fcsparser" code:-100 userInfo:@{@"userInfo": @"Error: FCS parser ended in an unknown state."}];
                [fcsFileStream close];
                break;
        }
    }
    fcsFileStream = nil;
    return error;
}


- (NSError *)_readHeaderSegmentFromStream:(NSInputStream *)inputStream
{
    uint8_t buffer[HEADER_LENGTH];
    NSUInteger bytesRead = [inputStream read:buffer maxLength:sizeof(buffer)];
    NSString *headerString = [NSString.alloc initWithBytes:buffer
                                                    length:bytesRead
                                                  encoding:NSASCIIStringEncoding];
    
    if (!headerString || headerString.length < HEADER_LENGTH) {
        return [NSError errorWithDomain:@"io.flow2go.fcsparser.headersegment" code:-100 userInfo:@{@"userInfo": @"Error: length of header in FCS file not correct."}];
    }
    self.header = FGFCSHeader.alloc.init;
    self.header.textBegin     = [[headerString substringWithRange:NSMakeRange(10, 8)] integerValue];
    self.header.textEnd       = [[headerString substringWithRange:NSMakeRange(18, 8)] integerValue];
    self.header.dataBegin     = [[headerString substringWithRange:NSMakeRange(26, 8)] integerValue];
    self.header.dataEnd       = [[headerString substringWithRange:NSMakeRange(34, 8)] integerValue];
    self.header.analysisBegin = [[headerString substringWithRange:NSMakeRange(42, 8)] integerValue];
    self.header.analysisEnd   = [[headerString substringWithRange:NSMakeRange(50, 8)] integerValue];
    
    return nil;
}


- (NSError *)_readTextSegmentFromStream:(NSInputStream *)inputStream from:(NSUInteger)firstByte to:(NSUInteger)lastByte
{
    [self _setInputStream:inputStream toPosition:firstByte];
    
    uint8_t buffer[lastByte-firstByte];
    NSUInteger bytesRead = [inputStream read:buffer maxLength:sizeof(buffer)];
    NSString *textString = [NSString.alloc initWithBytes:buffer length:bytesRead encoding:NSASCIIStringEncoding];
    
    if (!textString || textString.length == 0)
    {
        return [NSError errorWithDomain:@"io.flow2go.fcsparser.textsegment" code:-100 userInfo:@{@"userInfo": @"Error: text segment in FCS file could not be read."}];
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
        return nil;
    }
    else
    {
        return [NSError errorWithDomain:@"io.flow2go.fcsparser.textsegment" code:-100 userInfo:@{@"userInfo": @"Error: no keywords could be read from FCS file."}];
    }
}


- (NSError *)_readDataSegmentFromStream:(NSInputStream *)inputStream from:(NSUInteger)firstByte to:(NSUInteger)lastByte
{
    [self _setInputStream:inputStream toPosition:firstByte];
    
    _noOfEvents = [self.text[@"$TOT"] integerValue];
    NSUInteger noOfParams = [self.text[@"$PAR"] integerValue];
    self.noOfParams = noOfParams;
    
    if (_noOfEvents == 0
        || noOfParams == 0)
    {
        return [NSError errorWithDomain:@"io.flow2go.fcsparser.datasegment" code:-100 userInfo:@{@"userInfo": @"Error: parameter or event count is zero in FCS file"}];
    }
    
    [self allocateDataArrayWithType:self.text[@"$DATATYPE"]];
    CFByteOrder fcsByteOrder = [self _byteOrderFromString:self.text[@"$BYTEORD"]];
    NSError *error;
    if ([self.text[@"$DATATYPE"] isEqualToString:@"I"])
    {
        error = [self _readIntegerDataType:inputStream from:firstByte to:lastByte byteOrder:fcsByteOrder];
    }
    else if ([self.text[@"$DATATYPE"] isEqualToString:@"F"])
    {
        error = [self _readFloatDataType:inputStream from:firstByte to:lastByte byteOrder:fcsByteOrder];
    }
    else if ([self.text[@"$DATATYPE"] isEqualToString:@"D"])
    {
        // TODO: read doubles
    }
    
    [self _convertChannelValuesToScaleValues:self.events];
    [self _applyCompensationToScaleValues:self.events];
    [self _applyCalibrationToScaledValues:self.events];
    //[self _printOut:100 forPars:noOfParams];
    //[self _printOutScaledMinMax];
    
    return error;
}


- (NSError *)_readIntegerDataType:(NSInputStream *)inputStream from:(NSUInteger)firstByte to:(NSUInteger)lastByte byteOrder:(CFByteOrder)fcsFileByteOrder
{
    NSUInteger totalBytesRead = 0;
    NSInteger bytesRead = 0;
    NSUInteger eventNo = 0;
    FGParameterSize *parSizes = [self _getParameterSizes:_noOfParams];
    uint8_t bufferOneEvent[self.bitsPerEvent/8];
    
    while (totalBytesRead < lastByte - firstByte
           && [inputStream hasBytesAvailable])
    {
        bytesRead = [inputStream read:bufferOneEvent maxLength:sizeof(bufferOneEvent)];
        totalBytesRead += bytesRead;
        
        if (bytesRead > 0)
        {
            NSUInteger byteOffset = 0;
            for (NSUInteger parNo = 0; parNo < _noOfParams; parNo++)
            {
                switch (parSizes[parNo])
                {
                    case FGParameterSize8:
                        self.events[eventNo][parNo] = (double)bufferOneEvent[byteOffset];
                        byteOffset += 1;
                        break;
                        
                    case FGParameterSize16:
                        if (fcsFileByteOrder == CFByteOrderBigEndian)
                        {
                            self.events[eventNo][parNo] = (double)((bufferOneEvent[byteOffset] << 8) | bufferOneEvent[byteOffset + 1]);
                        }
                        else
                        {
                            self.events[eventNo][parNo] = (double)((bufferOneEvent[byteOffset + 1] << 8) | bufferOneEvent[byteOffset]);
                        }
                        byteOffset += 2;
                        break;
                        
                    case FGParameterSize32:
                        if (fcsFileByteOrder == CFByteOrderBigEndian)
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
            return [NSError errorWithDomain:@"io.flow2go.fcsparser.datasegment.integer" code:-100 userInfo:@{@"userInfo": @"Error: could not read from integer-data segment in FCS file"}];
        }
        eventNo++;
    }
    if (parSizes) free(parSizes);
    
    return nil;
}


- (NSError *)_readFloatDataType:(NSInputStream *)inputStream from:(NSUInteger)firstByte to:(NSUInteger)lastByte byteOrder:(CFByteOrder)fcsFileByteOrder
{
    NSInteger bytesRead = 0;
    uint8_t bufferAllData[_noOfParams * _noOfEvents * sizeof(Float32)];
    bytesRead = [inputStream read:bufferAllData maxLength:sizeof(bufferAllData)];
    
    NSLog(@"Float buffer size: %lu (#par: %d, #events: %d)\nbytesRead: %d", sizeof(bufferAllData), _noOfParams, _noOfEvents, bytesRead);
    
    NSUInteger byteOffset = 0;
    for (NSUInteger eventNo = 0; eventNo < _noOfEvents; eventNo++)
    {
        for (NSUInteger parNo = 0; parNo < _noOfParams; parNo++)
        {
            if (fcsFileByteOrder == CFByteOrderBigEndian)
            {
                self.events[eventNo][parNo] = (double)((bufferAllData[byteOffset] << 24) | (bufferAllData[byteOffset + 1]  << 16) | (bufferAllData[byteOffset + 2]  << 8) | bufferAllData[byteOffset + 3]);
            }
            else
            {
                self.events[eventNo][parNo] = (double)((bufferAllData[byteOffset + 3] << 24) | (bufferAllData[byteOffset + 2]  << 16) | (bufferAllData[byteOffset + 1]  << 8) | bufferAllData[byteOffset]);
            }
            byteOffset += 4;
        }
    }

    return nil;
}


- (NSError *)_readAnalysisSegmentFromStream:(NSInputStream *)inputStream from:(NSUInteger)firstByte to:(NSUInteger)lastByte
{
    if (firstByte == 0
        || lastByte == 0)
    {
        return nil;
    }
    
    [self _setInputStream:inputStream toPosition:firstByte];
    
    uint8_t buffer[lastByte-firstByte];
    NSUInteger bytesRead = [inputStream read:buffer maxLength:sizeof(buffer)];
    NSString *analysisString = [NSString.alloc initWithBytes:buffer length:bytesRead encoding:NSASCIIStringEncoding];
    
    if (!analysisString)
    {
        return [NSError errorWithDomain:@"io.flow2go.fcsparser.analysissegment" code:-100 userInfo:@{@"userInfo": @"Error: analysis could not be read in FCS file"}];
    }
    
    if (!self.seperatorCharacterset)
    {
        return [NSError errorWithDomain:@"io.flow2go.fcsparser.analysissegment" code:-100 userInfo:@{@"userInfo": @"Error: separator not set in analysis segment."}];
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
        return nil;
    }
    return [NSError errorWithDomain:@"io.flow2go.fcsparser.analysissegment" code:-100 userInfo:@{@"userInfo": @"Error: no keywords could be read in the analysis segment."}];
}


- (void)allocateDataArrayWithType:(NSString *)dataTypeString
{
    if ([dataTypeString isEqualToString: @"I"])
    {
        self.events = calloc(_noOfEvents, sizeof(NSUInteger *));
        for (NSUInteger i = 0; i < _noOfEvents; i++)
        {
            self.events[i] = calloc(_noOfParams, sizeof(double));
        }
        return;
    }
    
    if ([dataTypeString isEqualToString: @"F"])
    {
        NSLog(@"allocating float type: %@", dataTypeString);
        self.events = calloc(_noOfEvents, sizeof(NSUInteger *));
        for (NSUInteger i = 0; i < _noOfEvents; i++)
        {
            self.events[i] = calloc(_noOfParams, sizeof(double));
        }
        return;
    }
    if ([dataTypeString isEqualToString: @"D"])
    {
        NSLog(@"allocating double type: %@", dataTypeString);
        self.events = calloc(_noOfEvents, sizeof(NSUInteger *));
        for (NSUInteger i = 0; i < _noOfEvents; i++)
        {
            self.events[i] = calloc(_noOfParams, sizeof(double));
        }
        return;
    }
}


- (FGParameterSize *)_getParameterSizes:(NSUInteger)numberOfParameters
{
    FGParameterSize *parameterSizes = calloc(numberOfParameters, sizeof(FGParameterSize));
    self.bitsPerEvent = 0;
    
    for (NSUInteger parNO = 0; parNO < numberOfParameters; parNO++)
    {
        NSString *key = [@"$P" stringByAppendingFormat:@"%iB", parNO + 1];
        switch ([self.text[key] integerValue])
        {
            case 8:
                parameterSizes[parNO] = FGParameterSize8;
                self.bitsPerEvent += 8;
                break;
                
            case 16:
                parameterSizes[parNO] = FGParameterSize16;
                self.bitsPerEvent += 16;
                break;
                
            case 32:
                parameterSizes[parNO] = FGParameterSize32;
                self.bitsPerEvent += 32;
                break;
                
            default:
                parameterSizes[parNO] = FGParameterSizeUnknown;
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
    free(_events);
    free(_ranges);
}

@end
