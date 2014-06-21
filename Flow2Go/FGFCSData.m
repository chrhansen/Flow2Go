//
//  FGFCSData.m
//  Flow2Go
//
//  Created by Christian Hansen on 26/04/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import "FGFCSData.h"
#import "FGFCSText.h"
#import "FGMatrixInversion.h"

@interface FGFCSData ()

@property (nonatomic) NSUInteger bitsPerEvent;
@property (nonatomic, strong) NSDictionary *keywords;
@property (nonatomic) FGParameterSize *parSizes;

@end

@implementation FGFCSData

- (NSError *)parseDataSegmentFromData:(NSData *)dataSegmentData fcsKeywords:(NSDictionary *)keywords
{
    self.keywords = keywords;
    _noOfEvents = [keywords[@"$TOT"] integerValue];
    NSUInteger noOfParams = [keywords[@"$PAR"] integerValue];
    self.noOfParams = noOfParams;
    
    if (_noOfEvents == 0 || noOfParams == 0)
    {
        return [NSError errorWithDomain:@"io.flow2go.fcsparser.datasegment" code:-100 userInfo:@{NSLocalizedDescriptionKey: @"Error: parameter or event count is zero in FCS file"}];
    }
    
    [self allocateDataArrayWithType:keywords[@"$DATATYPE"]];
    CFByteOrder fcsByteOrder = [self _byteOrderFromString:keywords[@"$BYTEORD"]];
    NSError *error;
    
    @try {
        if ([keywords[@"$DATATYPE"] isEqualToString:@"I"])
        {
            error = [self _readIntegerDataFromData:dataSegmentData byteOrder:fcsByteOrder];
        }
        else if ([keywords[@"$DATATYPE"] isEqualToString:@"F"])
        {
            error = [self _readFloatDataFromData:dataSegmentData byteOrder:fcsByteOrder];
        }
        else if ([keywords[@"$DATATYPE"] isEqualToString:@"D"])
        {
            error = [self _readDoubleDataFromData:dataSegmentData byteOrder:fcsByteOrder];
        }
        
        if (!error) {
            [self _setMinAndMaxValue:self.events dataTypeString:keywords[@"$DATATYPE"]];
            [self _convertChannelValuesToScaleValues:self.events];
            [self _applyCompensationToScaleValues:self.events];
            [self _applyCalibrationToScaledValues:self.events];
            if ([keywords[@"$DATATYPE"] isEqualToString:@"F"] || [keywords[@"$DATATYPE"] isEqualToString:@"D"]) {
                for (NSUInteger parNo = 0; parNo < _noOfParams; parNo++)
                    [self _findMinMaxForParNo:parNo events:self.events];
            }
        }
    }
    @catch (NSException *exception) {
        error = [NSError errorWithDomain:@"io.flow2go.fcsparser.datasegment" code:1 userInfo:@{NSLocalizedDescriptionKey: @"Error reading data segment of"}];
    }
    @finally {
        //
    }
    return error;
}


- (NSError *)_readIntegerDataFromData:(NSData *)dataSegmentData byteOrder:(CFByteOrder)fcsFileByteOrder
{
    self.parSizes = [self _getParameterSizes:_noOfParams];
    NSUInteger bytesPerEvent = self.bitsPerEvent/8;
    NSUInteger bytesToRead = _noOfEvents * bytesPerEvent;
    if (dataSegmentData.length < bytesToRead) {
        return [NSError errorWithDomain:@"io.flow2go.fcsparser.datasegment.integer" code:1 userInfo:@{NSLocalizedDescriptionKey: @"Error data segment is smaller than required for the number of events and parameters."}];
    }
    NSUInteger totalBytesRead = 0;
    NSUInteger eventIndex = 0;
    NSError *error;
    for (NSUInteger parIndex = 0; parIndex < _noOfParams; parIndex++) {
        if (self.parSizes[parIndex] == FGParameterSizeUnknown) {
            error = [NSError errorWithDomain:FCSFile_Error_Domain code:-1 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Paramter number %d has an unsupored bit size", parIndex + 1]}];
            return error;
        }
    }
    
    uint8_t bufferOneEvent[bytesPerEvent];
    
    while (totalBytesRead < bytesToRead)
    {
        [dataSegmentData getBytes:bufferOneEvent range:NSMakeRange(totalBytesRead, bytesPerEvent)];
        totalBytesRead += bytesPerEvent;
        
        NSUInteger byteOffset = 0;
        for (NSUInteger parIndex = 0; parIndex < _noOfParams; parIndex++)
        {
            switch (self.parSizes[parIndex])
            {
                case FGParameterSize8:
                    self.events[eventIndex][parIndex] = (double)bufferOneEvent[byteOffset];
                    byteOffset += 1;
                    break;
                    
                case FGParameterSize16:
                    if (fcsFileByteOrder == CFByteOrderBigEndian)
                    {
                        self.events[eventIndex][parIndex] = (double)((bufferOneEvent[byteOffset] << 8) | bufferOneEvent[byteOffset + 1]);
                    }
                    else
                    {
                        self.events[eventIndex][parIndex] = (double)((bufferOneEvent[byteOffset + 1] << 8) | bufferOneEvent[byteOffset]);
                    }
                    byteOffset += 2;
                    break;
                    
                case FGParameterSize32:
                    if (fcsFileByteOrder == CFByteOrderBigEndian)
                    {
                        self.events[eventIndex][parIndex] = (double)((bufferOneEvent[byteOffset] << 24) | (bufferOneEvent[byteOffset + 1]  << 16) | (bufferOneEvent[byteOffset + 2]  << 8) | bufferOneEvent[byteOffset + 3]);
                    }
                    else
                    {
                        self.events[eventIndex][parIndex] = (double)((bufferOneEvent[byteOffset + 3] << 24) | (bufferOneEvent[byteOffset + 2]  << 16) | (bufferOneEvent[byteOffset + 1]  << 8) | bufferOneEvent[byteOffset]);
                    }
                    byteOffset += 4;
                    break;
                    
                default:
                    break;
            }
        }
        eventIndex++;
    }
//    if (_parSizes) free(_parSizes);
    
    return error;
}

union Int2Float {
    uint8_t b[4];
    Float32 floatValue;
};
typedef union Int2Float Int2Float;


- (NSError *)_readFloatDataFromData:(NSData *)dataSegmentData byteOrder:(CFByteOrder)fcsFileByteOrder
{
    if (dataSegmentData.length < _noOfParams * _noOfEvents * sizeof(Float32)) {
        return [NSError errorWithDomain:@"io.flow2go.fcsparser.datasegment.float" code:1 userInfo:@{NSLocalizedDescriptionKey: @"Error data segment is smaller than required for the number of events and parameters."}];
    }
    
    int indexOfOffset0 = (fcsFileByteOrder == CFByteOrderLittleEndian) ? 0 : 3;
    int indexOfOffset1 = (fcsFileByteOrder == CFByteOrderLittleEndian) ? 1 : 2;
    int indexOfOffset2 = (fcsFileByteOrder == CFByteOrderLittleEndian) ? 2 : 1;
    int indexOfOffset3 = (fcsFileByteOrder == CFByteOrderLittleEndian) ? 3 : 0;

    NSUInteger bytesPerEvent = _noOfParams * sizeof(Float32);
    NSUInteger bytesToRead = _noOfEvents * bytesPerEvent;

    NSUInteger totalBytesRead = 0;
    NSUInteger eventIndex = 0;
    Int2Float int2Float;

    uint8_t bufferOneEvent[bytesPerEvent];
    
    while (totalBytesRead < bytesToRead)
    {
        [dataSegmentData getBytes:bufferOneEvent range:NSMakeRange(totalBytesRead, bytesPerEvent)];
        totalBytesRead += bytesPerEvent;
        
        NSUInteger byteOffset = 0;
        for (NSUInteger parIndex = 0; parIndex < _noOfParams; parIndex++)
        {
            int2Float.b[indexOfOffset0] = bufferOneEvent[byteOffset + 0];
            int2Float.b[indexOfOffset1] = bufferOneEvent[byteOffset + 1];
            int2Float.b[indexOfOffset2] = bufferOneEvent[byteOffset + 2];
            int2Float.b[indexOfOffset3] = bufferOneEvent[byteOffset + 3];
            _events[eventIndex][parIndex] = (double)int2Float.floatValue;
            byteOffset += 4;
        }
        eventIndex++;
    }
    return nil;
}


union Int2Double {
    uint8_t b[8];
    Float64 doubleValue;
};
typedef union Int2Double Int2Double;


- (NSError *)_readDoubleDataFromData:(NSData *)dataSegmentData byteOrder:(CFByteOrder)fcsFileByteOrder
{
    NSError *error;
    if (dataSegmentData.length < _noOfParams * _noOfEvents * sizeof(Float64)) {
        error = [NSError errorWithDomain:@"io.flow2go.fcsparser.datasegment.double" code:1 userInfo:@{NSLocalizedDescriptionKey: @"Error data segment is smaller than required for the number of events and parameters."}];
        return error;
    }
    uint8_t bufferAllData[dataSegmentData.length];
    [dataSegmentData getBytes:bufferAllData length:dataSegmentData.length];
    
    NSLog(@"Double buffer size: %lu (#par: %d, #events: %d)", sizeof(bufferAllData), _noOfParams, _noOfEvents);
    
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


- (void)allocateDataArrayWithType:(NSString *)dataTypeString
{
    NSUInteger dataSize = sizeof(double);
    if ([dataTypeString isEqualToString: @"I"]
        || [dataTypeString isEqualToString: @"F"]
        || [dataTypeString isEqualToString: @"D"]) {
        self.events = calloc(_noOfEvents, sizeof(NSUInteger *));
        for (NSUInteger i = 0; i < _noOfEvents; i++) {
            self.events[i] = calloc(_noOfParams, dataSize);
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


- (void)_setMinAndMaxValue:(double **)eventsAsChannelValues dataTypeString:(NSString *)dataTypeString
{
    self.ranges = calloc(_noOfParams, sizeof(FGRange));
    for (NSUInteger parNo = 0; parNo < _noOfParams; parNo++) {
        double range = [self.keywords[[@"$P" stringByAppendingFormat:@"%iR", parNo + 1]] doubleValue] - 1.0;
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
            maxValue = value;
        } else if (value < minValue) {
            minValue = value;
        }
    }
    _ranges[parNo].maxValue = maxValue;
    _ranges[parNo].minValue = minValue;
}


- (void)_convertChannelValuesToScaleValues:(double **)eventsAsChannelValues
{
    for (NSUInteger parNo = 0; parNo < _noOfParams; parNo++)
    {
        NSString *scaleString = self.keywords[[@"$P" stringByAppendingFormat:@"%iE", parNo + 1]];
        if (!scaleString) NSLog(@"Required scale Value for par %i not found.", parNo + 1);
        
        NSArray *scaleComponents = [scaleString componentsSeparatedByString:@","];
        double f1 = [scaleComponents[0] doubleValue];
        double f2 = [scaleComponents[1] doubleValue];
        double gain = [self _gainValueWithString:self.keywords[[@"$P" stringByAppendingFormat:@"%iG", parNo + 1]]];
        double range = [self.keywords[[@"$P" stringByAppendingFormat:@"%iR", parNo + 1]] doubleValue] - 1.0;
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



- (NSError *)_applyCompensationToScaleValues:(double **)eventsAsScaledValues
{
    NSString *spillOverString = self.keywords[@"$SPILLOVER"];
    NSError *error;
    if (spillOverString == nil) spillOverString = self.keywords[@"SPILL"];
    
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
    
    double **spillOverMatrix    = calloc(n, sizeof(double *));
    double **spillOverMatrixInv = calloc(n, sizeof(double *));
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
        return error = [NSError errorWithDomain:FCSFile_Error_Domain code:-1 userInfo:@{NSLocalizedDescriptionKey : NSLocalizedString(@"Spill over matrix is not inversible.", nil)}];
    }
    NSUInteger compensationParIndexes[n];
    for (NSUInteger i = 1; i < 1 + n; i++) {
        compensationParIndexes[i-1] = [FGFCSText parameterNumberForShortName:spillOverArray[i] inFCSKeywords:self.keywords] - 1;
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
        NSString *calibrationString = self.keywords[[@"$P" stringByAppendingFormat:@"%iCALIBRATION", parNo + 1]];
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

- (FGParameterSize *)_getParameterSizes:(NSUInteger)numberOfParameters
{
    FGParameterSize *parameterSizes = calloc(numberOfParameters, sizeof(FGParameterSize));
    self.bitsPerEvent = 0;
    
    for (NSUInteger parNO = 0; parNO < numberOfParameters; parNO++)
    {
        NSString *key = [@"$P" stringByAppendingFormat:@"%iB", parNO + 1];
        switch ([self.keywords[key] integerValue])
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

- (void)dealloc
{
    for (NSUInteger i = 0; i < _noOfEvents; i++) {
        free(_events[i]);
    }
//    if (_parSizes) free(_parSizes);
    
    free(_events);
    free(_ranges);
}

@end
