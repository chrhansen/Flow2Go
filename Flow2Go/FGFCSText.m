//
//  FGFCSText.m
//  Flow2Go
//
//  Created by Christian Hansen on 26/04/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import "FGFCSText.h"

@implementation FGFCSText

- (NSError *)parseTextSegmentFromData:(NSData *)textASCIIData
{
    NSString *textString = [[NSString alloc] initWithData:textASCIIData encoding:NSASCIIStringEncoding];
    
    if (!textString || textString.length == 0){
        return [NSError errorWithDomain:@"io.flow2go.fcsparser.textsegment" code:-100 userInfo:@{@"userInfo": @"Error: text segment in FCS file could not be read."}];
    }
    
    self.seperatorCharacterset = [NSCharacterSet characterSetWithCharactersInString:[textString substringToIndex:1]];
    NSArray *textSeparated = [[textString substringFromIndex:1] componentsSeparatedByCharactersInSet:self.seperatorCharacterset];
    
    NSMutableDictionary *textKeyValuePairs = [NSMutableDictionary dictionary];
    
    for (int i = 0; i < textSeparated.count; i += 2)
    {
        if (i + 1 < textSeparated.count)
        {
            [textKeyValuePairs setObject:textSeparated[i + 1] forKey:[textSeparated[i] uppercaseString]];
        }
    }
    
    if (textKeyValuePairs.count > 0)
    {
        self.keywords = [NSDictionary dictionaryWithDictionary:textKeyValuePairs];
        return nil;
    }
    else
    {
        return [NSError errorWithDomain:@"io.flow2go.fcsparser.textsegment" code:-100 userInfo:@{@"userInfo": @"Error: no keywords could be read from FCS file."}];
    }
}


#pragma mark - Public methods

+ (NSInteger)parameterNumberForShortName:(NSString *)PiNShortName inFCSKeywords:(NSDictionary *)keywords
{
    for (NSUInteger parNO = 1; parNO <= [keywords[@"$PAR"] integerValue]; parNO++)
    {
        NSString *keyword = [@"$P" stringByAppendingFormat:@"%iN", parNO];
        if ([PiNShortName isEqualToString:keywords[keyword]])
        {
            return parNO;
        }
    }
    return -1;
}

+ (NSString *)parameterShortNameForParameterIndex:(NSInteger)parameterIndex inFCSKeywords:(NSDictionary *)keywords
{
    NSString *shortNameKey = [@"$P" stringByAppendingFormat:@"%iN", parameterIndex + 1];
    return keywords[shortNameKey];
}


+ (NSString *)parameterNameForParameterIndex:(NSInteger)parameterIndex inFCSKeywords:(NSDictionary *)keywords
{
    NSString *shortNameKey = [@"$P" stringByAppendingFormat:@"%iN", parameterIndex + 1];
    NSString *longNameKey = [@"$P" stringByAppendingFormat:@"%iS", parameterIndex + 1];
    
    NSString *shortName = keywords[shortNameKey];
    NSString *longName = keywords[longNameKey];
    
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
