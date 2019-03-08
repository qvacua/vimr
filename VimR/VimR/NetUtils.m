/**
 * Greg Omelaenko - http://omelaen.co
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

#import "NetUtils.h"
#import <os/log.h>
#import <sys/socket.h>
#import <netinet/in.h>

static os_log_t logger;

@implementation NetUtils

// from https://developer.apple.com/library/content/documentation/NetworkingInternet/Conceptual/NetworkingTopics/Articles/UsingSocketsandSocketStreams.html#//apple_ref/doc/uid/CH73-SW9
// and http://stackoverflow.com/a/20850182/6939513
// slightly modified
+ (in_port_t)openPort {
  static dispatch_once_t token;
  dispatch_once(&token, ^{
    // See Defs.swift
    logger = os_log_create("com.qvacua.VimR", "general");
  });

  int sock = socket(AF_INET, SOCK_STREAM, 0);
  if(sock < 0) {
    os_log_error(logger, "Could not open socket");
    return 0;
  }
  
  struct sockaddr_in sin;
  memset(&sin, 0, sizeof(sin));

  sin.sin_len = sizeof(sin);
  sin.sin_family = AF_INET;
  sin.sin_port = htons(0);

  if (bind(sock, (struct sockaddr *) &sin, sizeof(sin)) < 0) {
    if(errno == EADDRINUSE) {
      os_log_error(logger, "the port is not available.");
      return 0;
    } else {
      os_log_error(logger, "could not bind to process (%{public}d) %{public}s", errno, strerror(errno));
      return 0;
    }
  }

  socklen_t len = sizeof(sin);
  if (getsockname(sock, (struct sockaddr *)&sin, &len) == -1) {
    os_log_error(logger, "getsockname failed.");
    return 0;
  }

  in_port_t result = ntohs(sin.sin_port);

  if (close (sock) < 0 ) {
    os_log_error(logger, "socket did not close: %{public}s", strerror(errno));
    return 0;
  }
  
  return result;
}

@end
