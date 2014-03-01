/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <XCTest/XCTest.h>


#define HC_SHORTHAND
#import <OCHamcrest/OCHamcrest.h>


#define MOCKITO_SHORTHAND
#import <OCMockito/OCMockito.h>


@interface VRBaseTestCase : XCTestCase

@end

@implementation VRBaseTestCase

- (void)testExample {
    XCTFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
}

@end
