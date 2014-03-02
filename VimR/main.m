/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <TBCacao/TBCacao.h>
#import <MacVimFramework/MacVimFramework.h>


int main(int argc, const char *argv[]) {
    // necessary MacVimFramework initialization {
    [MMUtils setKeyHandlingUserDefaults];
    [MMUtils setInitialUserDefaults];

    [[NSFileManager defaultManager] changeCurrentDirectoryPath:NSHomeDirectory()];
    // } necessary MacVimFramework initialization

    [[TBContext sharedContext] initContext];

    return NSApplicationMain(argc, argv);
}
