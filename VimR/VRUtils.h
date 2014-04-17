#ifndef SF
    #define SF(format, ...) [NSString stringWithFormat:format, ##__VA_ARGS__]
#endif

#ifndef CPP_STR
    #define CPP_STR(str) cf::to_s((__bridge CFStringRef) str)
#endif
