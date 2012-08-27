//
//  NSData+MD5.m
//  Flow2Go
//
//  Created by Christian Hansen on 27/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import "NSData+MD5.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSData (MD5)

- (NSString*)md5
{
    unsigned char result[16];
    CC_MD5( self.bytes, self.length, result ); // This is the md5 call
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}

@end
