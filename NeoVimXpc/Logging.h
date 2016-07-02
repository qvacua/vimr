/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

#ifdef DEBUG

#ifndef log4Debug
#define log4Debug(format, ...) printf("%s", \
 [[NSString stringWithFormat:(@"%s %@ %s - %d: " format "\n"), \
 __TIME__, [[NSString stringWithUTF8String: __FILE__] lastPathComponent], \
 __func__, __LINE__, ##__VA_ARGS__] UTF8String])
#endif

#ifndef log4Mark
#define log4Mark printf("%s", [[NSString stringWithFormat:(@"%s %s %s - %d\n"), __TIME__, __FILE__, __PRETTY_FUNCTION__, __LINE__] UTF8String])
#endif

#else

#define log4Debug(...)
#define log4Mark

#endif
