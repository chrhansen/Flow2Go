//
//  FCSFile.m
//  Flow2Go
//
//  Created by Christian Hansen on 05/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import "FGFCSFile.h"
#import "FGMatrixInversion.h"

typedef NS_ENUM(NSInteger, FGParameterSize)
{
    FGParameterSizeUnknown,
    FGParameterSize8,
    FGParameterSize16,
    FGParameterSize32,
};

@implementation FGFCSHeader

@end

@interface FGFCSFile ()

@property (nonatomic) FGFCSHeader *header;
@property (nonatomic) NSUInteger bitsPerEvent;
@property (nonatomic, strong) NSCharacterSet *seperatorCharacterset;

@end

@implementation FGFCSFile

- (void)readFCSFileAtPath:(NSString *)path progressDelegate:(id<FGFCSProgressDelegate>)progressDelegate withCompletion:(void (^)(NSError *error))completion
{
    NSError *error = [self.class checkFilePath:path];
    if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(error);
        });
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSError *error = [self _parseFileFromPath:path lastParsingSegment:FGParsingSegmentAnalysis];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(error);
            }
        });
    });
}


+ (FGFCSFile *)fcsFileWithPath:(NSString *)path lastParsingSegment:(FGParsingSegment)lastSegment error:(NSError **)error
{
    FGFCSFile *newFCSFile = [FGFCSFile.alloc init];
    *error = [newFCSFile _parseFileFromPath:path lastParsingSegment:lastSegment];
    
    if (!*error) return newFCSFile;
    
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
    [newFCSFile _parseFileFromPath:path lastParsingSegment:FGParsingSegmentText];
    return newFCSFile.text;
}


- (NSError *)_parseFileFromPath:(NSString *)path lastParsingSegment:(FGParsingSegment)lastParsingSegment;
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
                if (!error) {
                    _parsingSegment = (FGParsingSegmentHeader == lastParsingSegment) ? FGParsingSegmentFinished : FGParsingSegmentText;
                } else {
                    _parsingSegment = FGParsingSegmentFailed;
                }
                break;
                
            case FGParsingSegmentText:
                error = [self _readTextSegmentFromStream:fcsFileStream from:self.header.textBegin to:self.header.textEnd];
                if (!error) {
                    _parsingSegment = (FGParsingSegmentText == lastParsingSegment) ? FGParsingSegmentFinished : FGParsingSegmentData;
                } else {
                    _parsingSegment = FGParsingSegmentFailed;
                }
                break;
                
            case FGParsingSegmentData:
                error = [self _readDataSegmentFromStream:fcsFileStream from:self.header.dataBegin to:self.header.dataEnd];
                if (!error) {
                    _parsingSegment = (FGParsingSegmentData == lastParsingSegment) ? FGParsingSegmentFinished : FGParsingSegmentAnalysis;
                } else {
                    _parsingSegment = FGParsingSegmentFailed;
                }
                break;
                
            case FGParsingSegmentAnalysis:
                error = [self _readAnalysisSegmentFromStream:fcsFileStream from:self.header.analysisBegin to:self.header.analysisEnd];
                _parsingSegment = (!error) ? FGParsingSegmentFinished : FGParsingSegmentFailed;
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
        error = [self _readDoubleDataType:inputStream from:firstByte to:lastByte byteOrder:fcsByteOrder];
    }
    if (!error) {
        [self _setMinAndMaxValue:self.events dataTypeString:self.text[@"$DATATYPE"]];
        [self _convertChannelValuesToScaleValues:self.events];
        [self _applyCompensationToScaleValues:self.events];
        [self _applyCalibrationToScaledValues:self.events];
    }
    return error;
}


- (NSError *)_readIntegerDataType:(NSInputStream *)inputStream from:(NSUInteger)firstByte to:(NSUInteger)lastByte byteOrder:(CFByteOrder)fcsFileByteOrder
{
    NSUInteger totalBytesRead = 0;
    NSInteger bytesRead = 0;
    NSUInteger eventNo = 0;
    NSError *error;
    FGParameterSize *parSizes = [self _getParameterSizes:_noOfParams];
    for (NSUInteger parIndex = 0; parIndex < _noOfParams; parIndex++) {
        if (parSizes[parIndex] == FGParameterSizeUnknown) {
            error = [NSError errorWithDomain:FCSFile_Error_Domain code:-1 userInfo:@{@"error": [NSString stringWithFormat:@"Paramter number %d has an unsupored bit size.", parIndex + 1]}];
            return error;
        }
    }
    
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
    
    return error;
}

union Int2Float {
    uint8_t b[4];
    Float32 floatValue;
};
typedef union Int2Float Int2Float;


- (NSError *)_readFloatDataType:(NSInputStream *)inputStream from:(NSUInteger)firstByte to:(NSUInteger)lastByte byteOrder:(CFByteOrder)fileByteOrder
{
    NSInteger bytesRead = 0;
    uint8_t bufferAllData[_noOfParams * _noOfEvents * sizeof(Float32)];
    
    bytesRead = [inputStream read:bufferAllData maxLength:sizeof(bufferAllData)];
    
    int indexOfOffset0 = (fileByteOrder == CFByteOrderLittleEndian) ? 0 : 3;
    int indexOfOffset1 = (fileByteOrder == CFByteOrderLittleEndian) ? 1 : 2;
    int indexOfOffset2 = (fileByteOrder == CFByteOrderLittleEndian) ? 2 : 1;
    int indexOfOffset3 = (fileByteOrder == CFByteOrderLittleEndian) ? 3 : 0;
    
    NSUInteger byteOffset = 0;
    Int2Float int2Float;
    for (NSUInteger eventNo = 0; eventNo < _noOfEvents; eventNo++)
    {
        for (NSUInteger parNo = 0; parNo < _noOfParams; parNo++)
        {
            int2Float.b[indexOfOffset0] = bufferAllData[byteOffset + 0];
            int2Float.b[indexOfOffset1] = bufferAllData[byteOffset + 1];
            int2Float.b[indexOfOffset2] = bufferAllData[byteOffset + 2];
            int2Float.b[indexOfOffset3] = bufferAllData[byteOffset + 3];
            _events[eventNo][parNo] = (double)int2Float.floatValue;
            byteOffset += 4;
        }
    }
    return nil;
}


union Int2Double {
    uint8_t b[8];
    Float64 doubleValue;
};
typedef union Int2Double Int2Double;


- (NSError *)_readDoubleDataType:(NSInputStream *)inputStream from:(NSUInteger)firstByte to:(NSUInteger)lastByte byteOrder:(CFByteOrder)fcsFileByteOrder
{
    NSInteger bytesRead = 0;
    uint8_t bufferAllData[_noOfParams * _noOfEvents * sizeof(Float64)];
    bytesRead = [inputStream read:bufferAllData maxLength:sizeof(bufferAllData)];
    
    NSLog(@"Double buffer size: %lu (#par: %d, #events: %d)\nbytesRead: %d", sizeof(bufferAllData), _noOfParams, _noOfEvents, bytesRead);
    
    Int2Double int2Double;
    int indexOfOffset0 = (fcsFileByteOrder == CFByteOrderLittleEndian) ? 0 : 7;
    int indexOfOffset1 = (fcsFileByteOrder == CFByteOrderLittleEndian) ? 1 : 6;
    int indexOfOffset2 = (fcsFileByteOrder == CFByteOrderLittleEndian) ? 2 : 5;
    int indexOfOffset3 = (fcsFileByteOrder == CFByteOrderLittleEndian) ? 3 : 4;
    int indexOfOffset4 = (fcsFileByteOrder == CFByteOrderLittleEndian) ? 4 : 3;
    int indexOfOffset5 = (fcsFileByteOrder == CFByteOrderLittleEndian) ? 5 : 2;
    int indexOfOffset6 = (fcsFileByteOrder == CFByteOrderLittleEndian) ? 6 : 1;
    int indexOfOffset7 = (fcsFileByteOrder == CFByteOrderLittleEndian) ? 7 : 0;
    
    NSUInteger byteOffset = 0;
    for (NSUInteger eventNo = 0; eventNo < _noOfEvents; eventNo++)
    {
        for (NSUInteger parNo = 0; parNo < _noOfParams; parNo++)
        {
            int2Double.b[indexOfOffset0] = bufferAllData[byteOffset + 0];
            int2Double.b[indexOfOffset1] = bufferAllData[byteOffset + 1];
            int2Double.b[indexOfOffset2] = bufferAllData[byteOffset + 2];
            int2Double.b[indexOfOffset3] = bufferAllData[byteOffset + 3];
            int2Double.b[indexOfOffset4] = bufferAllData[byteOffset + 4];
            int2Double.b[indexOfOffset5] = bufferAllData[byteOffset + 5];
            int2Double.b[indexOfOffset6] = bufferAllData[byteOffset + 6];
            int2Double.b[indexOfOffset7] = bufferAllData[byteOffset + 7];
            
            self.events[eventNo][parNo] = (double)int2Double.doubleValue;
            byteOffset += 8;
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
            analysisKeyValuePairs[[textSeparated[i] uppercaseString]] = textSeparated[i+1];
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
    if ([dataTypeString isEqualToString: @"I"]
        || [dataTypeString isEqualToString: @"F"]
        || [dataTypeString isEqualToString: @"D"]) {
        self.events = calloc(_noOfEvents, sizeof(NSUInteger *));
        for (NSUInteger i = 0; i < _noOfEvents; i++) {
            self.events[i] = calloc(_noOfParams, sizeof(double));
        }
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


- (void)_setMinAndMaxValue:(double **)eventsAsChannelValues dataTypeString:(NSString *)dataTypeString
{
    self.ranges = calloc(_noOfParams, sizeof(FGRange));
    for (NSUInteger parNo = 0; parNo < _noOfParams; parNo++)
    {
        double range = [self.text[[@"$P" stringByAppendingFormat:@"%iR", parNo + 1]] doubleValue] - 1.0;
        if ([dataTypeString isEqualToString:@"I"]) {
            self.ranges[parNo].minValue = 0.0;
            self.ranges[parNo].maxValue = range;
        } else {
            [self _findMinMaxForParNo:parNo events:eventsAsChannelValues];
            // do nothing, ranges for float and double data types have to be set by searching min/max value
        }
    }
}


- (void)_findMinMaxForParNo:(NSUInteger)parNo events:(double **)eventValues
{
    double value;
    double minValue, maxValue;
    minValue = maxValue = self.ranges[parNo].minValue = self.ranges[parNo].maxValue = eventValues[0][parNo];
    
    for (NSUInteger eventNo = 0; eventNo < _noOfEvents; eventNo++) {
        value = eventValues[eventNo][parNo];
        if (value > maxValue) {
            _ranges[parNo].maxValue = maxValue = value;
        } else if (value < minValue) {
            _ranges[parNo].minValue = minValue = value;
        }
    }
}


- (void)_convertChannelValuesToScaleValues:(double **)eventsAsChannelValues
{
    for (NSUInteger parNo = 0; parNo < _noOfParams; parNo++)
    {
        NSString *scaleString = self.text[[@"$P" stringByAppendingFormat:@"%iE", parNo + 1]];
        if (!scaleString) NSLog(@"Required scale Value for par %i not found.", parNo + 1);
        
        NSArray *scaleComponents = [scaleString componentsSeparatedByString:@","];
        double f1 = [scaleComponents[0] doubleValue];
        double f2 = [scaleComponents[1] doubleValue];
        double gain = [self _gainValueWithString:self.text[[@"$P" stringByAppendingFormat:@"%iG", parNo + 1]]];
        double range = [self.text[[@"$P" stringByAppendingFormat:@"%iR", parNo + 1]] doubleValue] - 1.0;
        FGAxisType valueType;
        if (f1 <= 0.0) {
            valueType = kAxisTypeLinear;
            self.ranges[parNo].minValue /= gain;
            self.ranges[parNo].maxValue /= gain;
        } else {
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
                    eventsAsChannelValues[eventNo][parNo] /= gain;
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
    if (gString) {
        double g = gString.doubleValue;
        if (g == 0.0) {
            NSLog(@"Amplifier gain value is zero (g = %f).", g);
        } else {
            return g;
        }
    }
    return 1.0;
}


- (NSError *)_applyCompensationToScaleValues:(double **)eventsAsScaledValues
{
    NSString *spillOverString = self.text[@"$SPILLOVER"];
    NSError *error;
    if (spillOverString == nil) spillOverString = self.text[@"SPILL"];

    if (spillOverString == nil) {
        return error;
    }
    
    NSArray *spillOverArray = [spillOverString componentsSeparatedByString:@","];
    if (spillOverArray.count == 0)
    {
        NSLog(@"Error: No spill over components found: %@", spillOverString);
        return error;
    }
    NSInteger n = [spillOverArray[0] integerValue];
    if (spillOverArray.count < 1 + n + n * n) {
        NSLog(@"Error: Not all required spill over parameters found: %@", spillOverString);
        return error;
    }
        
    double **spillOverMatrix    = calloc(n, sizeof(NSUInteger *));
    double **spillOverMatrixInv = calloc(n, sizeof(NSUInteger *));
    for (NSUInteger i = 0; i < n; i++) {
        spillOverMatrix[i]       = calloc(n, sizeof(double));
        spillOverMatrixInv[i] = calloc(n, sizeof(double));
    }

    for (NSUInteger i = 0; i < n * n; i++) {
        spillOverMatrix[i / n][i % n] = [spillOverArray[1 + n + i] doubleValue];
    }
    
    if ([FGMatrixInversion isIdentityMatrix:spillOverMatrix order:n]) {
        for (NSUInteger i = 0; i < n; i++) {
            free(spillOverMatrix[i]);
            free(spillOverMatrixInv[i]);
        }
        free(spillOverMatrix);
        free(spillOverMatrixInv);

        return error;
    }
    
    NSLog(@"Spill over matrix is NOT identity check values");
    
    // invert spill over matrix
    BOOL inversionSuccess;
    spillOverMatrixInv = [FGMatrixInversion getInverseMatrix:spillOverMatrix order:n success:&inversionSuccess];
    if (!inversionSuccess) {
        NSLog(@"Spill over matrix could not be inverted");
        return error = [NSError errorWithDomain:FCSFile_Error_Domain code:-1 userInfo:@{@"error": NSLocalizedString(@"Spill over matrix is not inversible.", nil)}];
    }
    NSUInteger compensationParIndexes[n];
    for (NSUInteger i = 1; i < 1 + n; i++) {
        compensationParIndexes[i-1] = [FGFCSFile parameterNumberForShortName:spillOverArray[i] inFCSFile:self] - 1;
    }

    double *eventVector = calloc(n, sizeof(double));
    for (NSUInteger eventIndex = 0; eventIndex < _noOfEvents; eventIndex++) {
        // construct row vector of one event, e
        for (NSUInteger compensationRow = 0; compensationRow < n; compensationRow++) {
            NSUInteger parameterIndex = compensationParIndexes[compensationRow];
            eventVector[compensationRow] = _events[eventIndex][parameterIndex];
        }
        // multiply, e x S-1 to get compensated value
        eventVector = [FGMatrixInversion multiplyVector:eventVector byMatrix:spillOverMatrixInv order:n];
        for (NSUInteger compensationRow = 0; compensationRow < n; compensationRow++) {
            NSUInteger parameterIndex = compensationParIndexes[compensationRow];
            _events[eventIndex][parameterIndex] = eventVector[compensationRow];
        }
    }
    
    free(eventVector);
    return error;
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


- (void)_printOutRange:(NSRange)range forParameter:(NSInteger)parNo
{
    for (NSUInteger i = range.location; i < range.location + range.length; i++)
    {
        NSLog(@"eventNo:%i, parNo:(%i) , value: %f", i, parNo, self.events[i][parNo - 1]);
    }
}


- (void)_printOutRange:(NSRange)range
{
    for (NSUInteger parNo = 0; parNo < _noOfParams; parNo++) {
        for (NSUInteger i = range.location; i < range.location + range.length; i++) {
            NSLog(@"ParNo:(%i), eventNo:%i, value: %f", parNo + 1, i + 1, self.events[i][parNo]);
        }
        NSLog(@"\n");
    }
}



- (void)_printOutScaledMinMax
{
    for (NSUInteger parNo = 0; parNo < _noOfParams; parNo++)
    {
        double maxValue, minValue;
        minValue = maxValue = self.events[0][parNo];
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

+ (NSInteger)parameterNumberForShortName:(NSString *)PiNShortName inFCSFile:(FGFCSFile *)fcsFile
{
    for (NSUInteger parNO = 1; parNO <= [fcsFile.text[@"$PAR"] integerValue]; parNO++)
    {
        NSString *keyword = [@"$P" stringByAppendingFormat:@"%iN", parNO];
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


+ (FGAxisType)axisTypeForScaleString:(NSString *)scaleString
{
    if (!scaleString) {
        return kAxisTypeUnknown;
    }
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

- (FGAxisType)axisTypeForParameterIndex:(NSInteger)parameterIndex
{
    NSString *scaleString = self.text[[@"$P" stringByAppendingFormat:@"%iE", parameterIndex + 1]];
    if (!scaleString) NSLog(@"Required scale Value for par %i not found.", parameterIndex + 1);
    
    return [self.class axisTypeForScaleString:scaleString];
}

- (void)dealloc
{
    for (NSUInteger i = 0; i < _noOfEvents; i++) {
        free(_events[i]);
    }
    free(_events);
    free(_ranges);
}

@end
