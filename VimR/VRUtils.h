#ifndef SF
#define SF(format, ...) [NSString stringWithFormat:format, ##__VA_ARGS__]
#endif

#ifndef CPP_STR
#define CPP_STR(str) cf::to_s((__bridge CFStringRef) str)
#endif

#ifndef RETURN_NIL_WHEN_NOT_SELF
#define RETURN_NIL_WHEN_NOT_SELF if (!self) { return nil; }
#endif

OBJC_EXTERN inline double measure_time(dispatch_block_t block);
OBJC_EXTERN inline void dispatch_to_main_thread(dispatch_block_t block);
OBJC_EXTERN inline void dispatch_to_global_queue(dispatch_block_t block);
OBJC_EXTERN inline void dispatch_loop(size_t count, void (^block)(size_t));
