//
// Created by Tae Won Ha on 1/13/17.
// Copyright (c) 2017 Tae Won Ha. All rights reserved.
//

#import "NetUtils.h"
#import <sys/socket.h>
#import <netinet/in.h>

@implementation NetUtils

// from https://developer.apple.com/library/content/documentation/NetworkingInternet/Conceptual/NetworkingTopics/Articles/UsingSocketsandSocketStreams.html#//apple_ref/doc/uid/CH73-SW9
// and http://stackoverflow.com/a/20850182/6939513
// slightly modified
+ (in_port_t)openPort {
  int sock = socket(AF_INET, SOCK_STREAM, 0);
  if(sock < 0) {
    NSLog(@"ERROR Could not open a socket");
    return 0;
  }
  
  struct sockaddr_in sin;
  memset(&sin, 0, sizeof(sin));

  sin.sin_len = sizeof(sin);
  sin.sin_family = AF_INET;
  sin.sin_port = htons(0);

  if (bind(sock, (struct sockaddr *) &sin, sizeof(sin)) < 0) {
    if(errno == EADDRINUSE) {
      NSLog(@"ERROR the port is not available. already to other process");
      return 0;
    } else {
      NSLog(@"ERROR could not bind to process (%d) %s", errno, strerror(errno));
      return 0;
    }
  }

  socklen_t len = sizeof(sin);
  if (getsockname(sock, (struct sockaddr *)&sin, &len) == -1) {
    NSLog(@"ERROR getsockname");
    return 0;
  }

  in_port_t result = ntohs(sin.sin_port);

  if (close (sock) < 0 ) {
    NSLog(@"ERROR did not close: %s", strerror(errno));
    return 0;
  }
  
  return result;
}

@end
