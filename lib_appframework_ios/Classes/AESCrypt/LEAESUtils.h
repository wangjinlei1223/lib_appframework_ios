
/**
 *  Just a port for NSData+AES & NSString+AES
 *
 */

#import <Foundation/Foundation.h>

@interface LEAESUtils : NSObject

+ (NSData *)AES256EncryptData:(NSData *)data withKey:(NSString *)key;
+ (NSData *)AES256DecryptData:(NSData *)data withKey:(NSString *)key;

+ (NSData *)dataWithBase64EncodedString:(NSString *)string;

+ (NSString *)base64EncodingWithData:(NSData *)data;
+ (NSString *)base64EncodingData:(NSData *)data WithLineLength:(NSUInteger)lineLength ;
	
+ (BOOL)data:(NSData *)data hasPrefixBytes:(const void *)prefix length:(NSUInteger)length;
+ (BOOL)data:(NSData *)data hasSuffixBytes:(const void *)suffix length:(NSUInteger)length;

+ (NSString *)AES256EncryptString:(NSString *)string withKey:(NSString *)key;
+ (NSString *)AES256DecryptString:(NSString *)string withKey:(NSString *)key;

@end
