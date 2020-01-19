/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

#import "FoundationCommons.h"
#import <dirent.h>

@implementation NSURL (Commons)

- (struct dirent)fakeDirent {
  const char *nameCstr = [self.lastPathComponent cStringUsingEncoding:NSUTF8StringEncoding];

  struct dirent result = {
      .d_type=self.direntType,
      .d_namlen=(__uint16_t) strlen(nameCstr),
  };
  strcpy(result.d_name, nameCstr);

  return result;
}

- (uint8_t)direntType {
  NSString *value = nil;
  if (![self getResourceValue:&value forKey:NSURLFileResourceTypeKey error:nil]) {
    return DT_UNKNOWN;
  }

  if ([value isEqualToString:NSURLFileResourceTypeNamedPipe]) {return DT_FIFO;}
  if ([value isEqualToString:NSURLFileResourceTypeCharacterSpecial]) {return DT_CHR;}
  if ([value isEqualToString:NSURLFileResourceTypeDirectory]) {return DT_DIR;}
  if ([value isEqualToString:NSURLFileResourceTypeBlockSpecial]) {return DT_BLK;}
  if ([value isEqualToString:NSURLFileResourceTypeRegular]) {return DT_REG;}
  if ([value isEqualToString:NSURLFileResourceTypeSymbolicLink]) {return DT_LNK;}
  if ([value isEqualToString:NSURLFileResourceTypeSocket]) {return DT_SOCK;}

  return DT_UNKNOWN;
}

@end
