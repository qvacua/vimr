#ifdef DEBUG

    #ifndef log4Debug
       #define log4Debug(format, ...) printf("%s", [[NSString stringWithFormat:(@"[DEBUG] %s - %d: " format "\n"), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__] UTF8String])
    #endif

    #ifndef logPoint4Debug
        #define logPoint4Debug(prefix, point) printf("%s", [[NSString stringWithFormat:@"[DEBUG] %s - %d: %@: x: %.2f, y: %.2f\n", __PRETTY_FUNCTION__, __LINE__, prefix, point.x, point.y] UTF8String])
    #endif

    #ifndef logSize4Debug
        #define logSize4Debug(prefix, size) printf("%s", [[NSString stringWithFormat:@"[DEBUG] %s - %d: %@: w: %.2f, h: %.2f\n", __PRETTY_FUNCTION__, __LINE__, prefix, size.width, size.height] UTF8String])
    #endif

    #ifndef logRect4Debug
        #define logRect4Debug(prefix, rect) printf("%s", [[NSString stringWithFormat:@"[DEBUG] %s - %d: %@: x: %.2f, y: %.2f, w: %.2f, h: %.2f\n", __PRETTY_FUNCTION__, __LINE__, prefix, rect.origin.x, rect.origin.y, rect.size.width, rect.size.height] UTF8String])
    #endif

    #ifndef log4Mark
        #define log4Mark printf("%s", [[NSString stringWithFormat:(@"[DEBUG] %s - %d\n"), __PRETTY_FUNCTION__, __LINE__] UTF8String])
    #endif

#else

    #define log4Debug(...)
    #define logPoint4Debug(...)
    #define logSize4Debug(...)
    #define logRect4Debug(...)
    #define log4Mark

#endif

#ifndef log4Info
    #define log4Info(format, ...) printf("%s", [[NSString stringWithFormat:(@"[INFO] %s - %d: " format "\n"), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__] UTF8String])
#endif

#ifndef log4Warn
    #define log4Warn(format, ...) printf("%s", [[NSString stringWithFormat:(@"[WARN] %s - %d: " format "\n"), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__] UTF8String])
#endif

#ifndef log4Error
    #define log4Error(format, ...) printf("%s", [[NSString stringWithFormat:(@"[ERROR] %s - %d: " format "\n"), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__] UTF8String])
#endif

#ifndef log4Fatal
    #define log4Fatal(format, ...) printf("%s", [[NSString stringWithFormat:(@"[FATAL] %s - %d: " format "\n"), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__] UTF8String])
#endif

