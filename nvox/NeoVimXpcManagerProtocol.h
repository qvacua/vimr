//
//  NeoVimXpcManagerProtocol.h
//  nvox
//
//  Created by Tae Won Ha on 07/07/16.
//  Copyright © 2016 Tae Won Ha. All rights reserved.
//

@import Foundation;

@protocol NeoVimXpcManagerProtocol <NSObject>

- (void)shouldAcceptEndpoint:(NSXPCListenerEndpoint *)endpoint forNeoVimUuid:(NSString *)neoVimUuid;

@end
