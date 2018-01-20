//
//  NvimView.h
//  NvimView
//
//  Created by hat on 02.12.17.
//  Copyright © 2017 Tae Won Ha. All rights reserved.
//

#import <Cocoa/Cocoa.h>

//! Project version number for NvimView.
FOUNDATION_EXPORT double NvimViewVersionNumber;

//! Project version string for NvimView.
FOUNDATION_EXPORT const unsigned char NvimViewVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <NvimView/PublicHeader.h>

#import <NvimView/NvimUiBridgeProtocol.h>
// TODO: this header should not be public, but we cannot use a bridging header in a framework.
#import <NvimView/TextDrawer.h>
#import <NvimView/UiClient.h>
#import <NvimView/NvimAutoCommandEvent.generated.h>
#import <NvimView/SharedTypes.h>
