/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <Cocoa/Cocoa.h>
#import <TBCacao/TBCacao.h>


int main(int argc, const char *argv[]) {
    [[TBContext sharedContext] initContext];

    return NSApplicationMain(argc, argv);
}
