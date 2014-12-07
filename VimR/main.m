/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <TBCacao/TBCacao.h>
#import <CocoaLumberjack/DDTTYLogger.h>


int main(int argc, const char *argv[]) {
  // necessary MacVimFramework initialization {
//  [MMUtils setKeyHandlingUserDefaults];
//  [MMUtils setInitialUserDefaults];

//  [[NSFileManager defaultManager] changeCurrentDirectoryPath:NSHomeDirectory()];
  // } necessary MacVimFramework initialization

  [[TBContext sharedContext] initContext];

//  DDTTYLogger *logger = [DDTTYLogger sharedInstance];
//  logger.colorsEnabled = YES;
//  logger.logFormatter = [[VRLogFormatter alloc] init];
//  [DDLog addLogger:logger];

  return NSApplicationMain(argc, argv);
}
