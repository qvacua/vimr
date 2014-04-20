#ifndef SF
    #define SF(format, ...) [NSString stringWithFormat:format, ##__VA_ARGS__]
#endif

#ifndef CPP_STR
    #define CPP_STR(str) cf::to_s((__bridge CFStringRef) str)
#endif

#ifndef RETURN_NIL_WHEN_NOT_SELF
    #define RETURN_NIL_WHEN_NOT_SELF if (!self) { return nil; }
#endif

extern inline double measure_time(void (^block)());
extern inline void dispatch(dispatch_block_t block);

