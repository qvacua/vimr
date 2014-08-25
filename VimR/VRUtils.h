/**
* Tae Won Ha — @hataewon
*
* http://taewon.de
* http://qvacua.com
*
* See LICENSE
*/

#ifndef SF
#define SF(format, ...) [NSString stringWithFormat:format, ##__VA_ARGS__]
#endif

#ifndef CPP_STR
#define CPP_STR(str) cf::to_s((__bridge CFStringRef) str)
#endif

#ifndef RETURN_NIL_WHEN_NOT_SELF
#define RETURN_NIL_WHEN_NOT_SELF if (!self) { return nil; }
#endif

OBJC_EXTERN void dispatch_to_main_thread(dispatch_block_t block);
OBJC_EXTERN void dispatch_to_global_queue(dispatch_block_t block);
OBJC_EXTERN void dispatch_loop(size_t count, void (^block)(size_t));
OBJC_EXTERN NSURL *common_parent_url(NSArray *fileUrls);
OBJC_EXTERN NSValue *vsize(CGSize size);
OBJC_EXTERN NSValue *vrect(CGRect rect);
OBJC_EXTERN NSValue *vpoint(CGPoint point);
OBJC_EXTERN NSArray *urls_from_paths(NSArray *);
OBJC_EXTERN NSArray *paths_from_urls(NSArray *urls);
OBJC_EXTERN CGRect rect_with_origin(CGPoint origin, CGFloat width, CGFloat height);
OBJC_EXTERN NSData *vim_data_for_menu_descriptor(NSArray *descriptor);
OBJC_EXTERN BOOL blank(NSString *str);

OBJC_EXTERN NSString *VRResolvePathRelativeToPathWithFileManager(NSString *path, NSString *relativeToPath, BOOL sibling, NSFileManager *fileManager);
OBJC_EXTERN NSString *VRResolvePathRelativeToPath(NSString *path, NSString *relativeToPath, BOOL sibling);
