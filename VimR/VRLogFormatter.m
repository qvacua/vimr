/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import "VRLogFormatter.h"
#import "VRUtils.h"


@implementation VRLogFormatter {
  NSDateFormatter *_dateFormatter;
}

- (id)init {
  self = [super init];
  RETURN_NIL_WHEN_NOT_SELF

  _dateFormatter = [[NSDateFormatter alloc] init];
  [_dateFormatter setDateFormat:@"HH:mm:ss:SSS"];

  return self;
}

- (NSString *)formatLogMessage:(DDLogMessage *)msg {
  NSString *level;
  switch (msg->logFlag) {
    case LOG_FLAG_ERROR :
      level = @"[ERROR]";
      break;
    case LOG_FLAG_WARN  :
      level = @"[WARN ]";
      break;
    case LOG_FLAG_INFO  :
      level = @"[INFO ]";
      break;
    case LOG_FLAG_DEBUG :
      level = @"[DEBUG]";
      break;
    default             :
      level = @"[OTHER]";
      break;
  }

  NSString *fileName = [NSString stringWithUTF8String:msg->file].lastPathComponent.stringByDeletingPathExtension;

  return SF(@"%@ %@ %@ %s-%d - %@",
  level, [_dateFormatter stringFromDate:msg->timestamp], fileName, msg->function, msg->lineNumber, msg->logMsg
  );
}

@end
