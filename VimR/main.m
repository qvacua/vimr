/**
* Tae Won Ha — @hataewon
*
* http://taewon.de
* http://qvacua.com
*
* See LICENSE
*/


int main(int argc, const char *argv[]) {
  /**
  *  Usually we would call here the following:
  * [[TBContext sharedContext] initContext];
  * However, we do that in the -init of the app delegate because we use a subclass of NSApplication. Otherwise, AppKit
  * tries to instantiate two NSApplication's.
  */

  return NSApplicationMain(argc, argv);
}
