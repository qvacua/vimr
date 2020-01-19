//
// Created by Tae Won Ha on 05.01.20.
// Copyright (c) 2020 Tae Won Ha. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ScoredUrl : NSObject

@property (readonly, nonnull) NSURL *url;
@property (readonly) NSInteger score;

- (BOOL)isEqual:(id _Nullable)other;
- (BOOL)isEqualToUrl:(ScoredUrl * _Nullable)url;
- (NSUInteger)hash;

- (instancetype _Nonnull)initWithUrl:(NSURL * _Nonnull)url score:(NSInteger)score;
- (NSString * _Nonnull)description;
+ (instancetype _Nonnull)urlWithUrl:(NSURL * _Nonnull)url score:(NSInteger)score;


@end
