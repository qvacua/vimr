#ifndef SF
#define SF(format, ...) [NSString stringWithFormat:format, ##__VA_ARGS__]
#endif

#ifndef CPP_STR
#define CPP_STR(str) cf::to_s((__bridge CFStringRef) str)
#endif

#ifndef RETURN_NIL_WHEN_NOT_SELF
#define RETURN_NIL_WHEN_NOT_SELF if (!self) { return nil; }
#endif

OBJC_EXTERN inline void dispatch_to_main_thread(dispatch_block_t block);
OBJC_EXTERN inline void dispatch_to_global_queue(dispatch_block_t block);
OBJC_EXTERN inline void dispatch_loop(size_t count, void (^block)(size_t));
OBJC_EXTERN inline NSURL *common_parent_url(NSArray *fileUrls);
OBJC_EXTERN inline NSValue *vsize(CGSize size);
OBJC_EXTERN inline NSValue *vrect(CGRect rect);
OBJC_EXTERN inline NSValue *vpoint(CGPoint point);
OBJC_EXTERN inline NSArray *urls_from_paths(NSArray *);
OBJC_EXTERN inline CGRect rect_with_origin(CGPoint origin, CGFloat width, CGFloat height);
