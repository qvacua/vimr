//
// Created by Tae Won Ha on 1/5/17.
// Copyright (c) 2017 Tae Won Ha. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Wrapper : NSObject

@property (strong) NSData *data;
@property (getter=isDataReady) bool dataReady;

@end
