//
//  NSData+AESCrypt.m
//
//  AES Encrypt/Decrypt
//  Created by Jim Dovey and 'Jean'
//  See http://iphonedevelopment.blogspot.com/2009/02/strong-encryption-for-cocoa-cocoa-touch.html
//
//  BASE64 Encoding/Decoding
//  Copyright (c) 2001 Kyle Hammond. All rights reserved.
//  Original development by Dave Winer.
//
//  Put together by Michael Sedlaczek, Gone Coding on 2011-02-22
//

#import "LEAESUtils.h"

#import <CommonCrypto/CommonCryptor.h>

static char encodingTable[64] = 
{
   'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P',
   'Q','R','S','T','U','V','W','X','Y','Z','a','b','c','d','e','f',
   'g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v',
   'w','x','y','z','0','1','2','3','4','5','6','7','8','9','+','/'
};

@implementation LEAESUtils

+ (NSData *)AES256EncryptData:(NSData *)data withKey:(NSString *)key
{
    // 'key' should be 32 bytes for AES256, will be null-padded otherwise
    char keyPtr[key.length + 1]; // room for terminator (unused)
    bzero( keyPtr, sizeof( keyPtr ) ); // fill with zeroes (for padding)
    
   // fetch key data
   [key getCString:keyPtr maxLength:sizeof( keyPtr ) encoding:NSUTF8StringEncoding];
   
   NSUInteger dataLength = [data length];
   
   //See the doc: For block ciphers, the output size will always be less than or 
   //equal to the input size plus the size of one block.
   //That's why we need to add the size of one block here
   size_t bufferSize = dataLength + kCCBlockSizeAES128;
   void *buffer = malloc( bufferSize );
   
   size_t numBytesEncrypted = 0;
   CCCryptorStatus cryptStatus = CCCrypt( kCCEncrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding | kCCOptionECBMode,
                                          keyPtr, key.length,
                                          NULL /* initialization vector (optional) */,
                                          [data bytes], dataLength, /* input */
                                          buffer, bufferSize, /* output */
                                          &numBytesEncrypted );
   if( cryptStatus == kCCSuccess )
   {
      //the returned NSData takes ownership of the buffer and will free it on deallocation
      return [NSData dataWithBytesNoCopy:buffer length:numBytesEncrypted];
   }
   
   free( buffer ); //free the buffer
   return nil;
}

+ (NSData *)AES256DecryptData:(NSData *)data withKey:(NSString *)key
{
   // 'key' should be 32 bytes for AES256, will be null-padded otherwise
   char keyPtr[key.length +1]; // room for terminator (unused)
   bzero( keyPtr, sizeof( keyPtr ) ); // fill with zeroes (for padding)
   
   // fetch key data
   [key getCString:keyPtr maxLength:sizeof( keyPtr ) encoding:NSUTF8StringEncoding];
   
   NSUInteger dataLength = [data length];
   
   //See the doc: For block ciphers, the output size will always be less than or 
   //equal to the input size plus the size of one block.
   //That's why we need to add the size of one block here
   size_t bufferSize = dataLength + kCCBlockSizeAES128;
   void *buffer = malloc( bufferSize );
   
   size_t numBytesDecrypted = 0;
   CCCryptorStatus cryptStatus = CCCrypt( kCCDecrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding | kCCOptionECBMode,
                                          keyPtr, key.length,
                                          NULL /* initialization vector (optional) */,
                                          [data bytes], dataLength, /* input */
                                          buffer, bufferSize, /* output */
                                          &numBytesDecrypted );
   
   if( cryptStatus == kCCSuccess )
   {
      //the returned NSData takes ownership of the buffer and will free it on deallocation
      return [NSData dataWithBytesNoCopy:buffer length:numBytesDecrypted];
   }
   
   free( buffer ); //free the buffer
   return nil;
}

#pragma mark -

+ (NSData *)dataWithBase64EncodedString:(NSString *)string
{
    NSMutableData *mutableData = nil;
    
    if( string )
    {
        unsigned long ixtext = 0;
        unsigned long lentext = 0;
        unsigned char ch = 0;
        unsigned char inbuf[4], outbuf[3];
        short i = 0, ixinbuf = 0;
        BOOL flignore = NO;
        BOOL flendtext = NO;
        NSData *base64Data = nil;
        const unsigned char *base64Bytes = nil;
        
        // Convert the string to ASCII data.
        base64Data = [string dataUsingEncoding:NSASCIIStringEncoding];
        base64Bytes = [base64Data bytes];
        mutableData = [NSMutableData dataWithCapacity:base64Data.length];
        lentext = base64Data.length;
        
        while( YES )
        {
            if( ixtext >= lentext ) break;
            ch = base64Bytes[ixtext++];
            flignore = NO;
            
            if( ( ch >= 'A' ) && ( ch <= 'Z' ) ) ch = ch - 'A';
            else if( ( ch >= 'a' ) && ( ch <= 'z' ) ) ch = ch - 'a' + 26;
            else if( ( ch >= '0' ) && ( ch <= '9' ) ) ch = ch - '0' + 52;
            else if( ch == '+' ) ch = 62;
            else if( ch == '=' ) flendtext = YES;
            else if( ch == '/' ) ch = 63;
            else flignore = YES;
            
            if( ! flignore )
            {
                short ctcharsinbuf = 3;
                BOOL flbreak = NO;
                
                if( flendtext )
                {
                    if( ! ixinbuf ) break;
                    if( ( ixinbuf == 1 ) || ( ixinbuf == 2 ) ) ctcharsinbuf = 1;
                    else ctcharsinbuf = 2;
                    ixinbuf = 3;
                    flbreak = YES;
                }
                
                inbuf [ixinbuf++] = ch;
                
                if( ixinbuf == 4 )
                {
                    ixinbuf = 0;
                    outbuf [0] = ( inbuf[0] << 2 ) | ( ( inbuf[1] & 0x30) >> 4 );
                    outbuf [1] = ( ( inbuf[1] & 0x0F ) << 4 ) | ( ( inbuf[2] & 0x3C ) >> 2 );
                    outbuf [2] = ( ( inbuf[2] & 0x03 ) << 6 ) | ( inbuf[3] & 0x3F );
                    
                    for( i = 0; i < ctcharsinbuf; i++ )
                        [mutableData appendBytes:&outbuf[i] length:1];
                }
                
                if( flbreak )  break;
            }
        }
    }
    
    return [[NSData alloc] initWithData:mutableData];
}

#pragma mark -

+ (NSString *)base64EncodingWithData:(NSData *)data;
{
   return [self base64EncodingData:data WithLineLength:0];
}

+ (NSString *)base64EncodingData:(NSData *)data WithLineLength:(NSUInteger)lineLength
{
   const unsigned char   *bytes = [data bytes];
   NSMutableString *result = [NSMutableString stringWithCapacity:data.length];
   unsigned long ixtext = 0;
   unsigned long lentext = data.length;
   long ctremaining = 0;
   unsigned char inbuf[3], outbuf[4];
   unsigned short i = 0;
   unsigned short charsonline = 0, ctcopy = 0;
   unsigned long ix = 0;
   
   while( YES )
   {
      ctremaining = lentext - ixtext;
      if( ctremaining <= 0 ) break;
      
      for( i = 0; i < 3; i++ )
      {
         ix = ixtext + i;
         if( ix < lentext ) inbuf[i] = bytes[ix];
         else inbuf [i] = 0;
      }
      
      outbuf [0] = (inbuf [0] & 0xFC) >> 2;
      outbuf [1] = ((inbuf [0] & 0x03) << 4) | ((inbuf [1] & 0xF0) >> 4);
      outbuf [2] = ((inbuf [1] & 0x0F) << 2) | ((inbuf [2] & 0xC0) >> 6);
      outbuf [3] = inbuf [2] & 0x3F;
      ctcopy = 4;
      
      switch( ctremaining )
      {
         case 1:
            ctcopy = 2;
            break;
         case 2:
            ctcopy = 3;
            break;
      }
      
      for( i = 0; i < ctcopy; i++ )
         [result appendFormat:@"%c", encodingTable[outbuf[i]]];
      
      for( i = ctcopy; i < 4; i++ )
         [result appendString:@"="];
      
      ixtext += 3;
      charsonline += 4;
      
      if( lineLength > 0 )
      {
         if( charsonline >= lineLength )
         {
            charsonline = 0;
            [result appendString:@"\n"];
         }
      }
   }
   
   return [NSString stringWithString:result];
}

#pragma mark -

+ (BOOL)data:(NSData *)data hasPrefixBytes:(const void *)prefix length:(NSUInteger)length
{
   if( ! prefix || ! length || data.length < length ) return NO;
   return ( memcmp( [data bytes], prefix, length ) == 0 );
}

+ (BOOL)data:(NSData *)data hasSuffixBytes:(const void *)suffix length:(NSUInteger)length
{
   if( ! suffix || ! length || data.length < length ) return NO;
   return ( memcmp( ((const char *)[data bytes] + (data.length - length)), suffix, length ) == 0 );
}

#pragma mark - NSString+AESCrypt

+ (NSString *)AES256EncryptString:(NSString *)string withKey:(NSString *)key
{
    NSData *plainData = [string dataUsingEncoding:NSUTF8StringEncoding];
    NSData *encryptedData = [[self class] AES256EncryptData:plainData withKey:key];
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_7_0
    NSString *encryptedString = [encryptedData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
#else
    NSString *encryptedString = [encryptedData base64Encoding];
#endif
    
    return encryptedString;
}

+ (NSString *)AES256DecryptString:(NSString *)string withKey:(NSString *)key
{
    NSData *encryptedData = [[self class] dataWithBase64EncodedString:string];
    NSData *plainData = [[self class] AES256DecryptData:encryptedData withKey:key];
    
    NSString *plainString = [[NSString alloc] initWithData:plainData encoding:NSUTF8StringEncoding];
    return plainString;
}

@end
