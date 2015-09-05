//
//  VRFileBrowserActionTestCase.m
//  VimR
//
//  Created by Mark Sandstrom on 7/6/14.
//  Copyright (c) 2014 Tae Won Ha. All rights reserved.
//

#import "VRBaseTestCase.h"
#import "VRFileBrowserOutlineView.h"

static const int qEscCharacter = '\033';


NSEvent *KeyDownEventWithModifiers(unichar key, NSUInteger modifierFlags) {
  return [NSEvent keyEventWithType:NSKeyDown
                          location:NSMakePoint(0, 0)
                     modifierFlags:modifierFlags
                         timestamp:0
                      windowNumber:0
                           context:nil
                        characters:[NSString stringWithCharacters:&key length:1]
       charactersIgnoringModifiers:[NSString stringWithCharacters:&key length:1]
                         isARepeat:NO
                           keyCode:0];
}

NSEvent *KeyDownEvent(unichar key) {
  return KeyDownEventWithModifiers(key, 0);
}


@interface VRFileBrowserActionsTestCase : VRBaseTestCase

@end

@implementation VRFileBrowserActionsTestCase {
  VRFileBrowserOutlineView *fileOutlineView;
  id<VRFileBrowserActionDelegate> actionDelegate;
}

- (void)setUp {
  [super setUp];
  actionDelegate = mockProtocol(@protocol(VRFileBrowserActionDelegate));
  fileOutlineView =[[VRFileBrowserOutlineView alloc] initWithFrame:CGRectZero];
  fileOutlineView.actionDelegate = actionDelegate;
  [given([actionDelegate actionCanActOnNode]) willReturnBool:YES];
}

#pragma mark Utils

- (NSNumber *)isInNormalMode {
  return @(fileOutlineView.actionMode == VRFileBrowserActionModeNormal);
}

- (void)type:(NSString *)string {
  for (int i = 0; i < string.length; i++) {
    [fileOutlineView keyDown:KeyDownEvent([string characterAtIndex:(NSUInteger) i])];
  }
}

#pragma mark Tests

- (void)testUnknownKeyShouldBeIgnored {
  [fileOutlineView keyDown:KeyDownEvent('6')];
  [verify(actionDelegate) actionIgnore];
}

- (void)test_j_ActionShouldMoveDown {
  [fileOutlineView keyDown:KeyDownEvent('j')];
  [verify(actionDelegate) actionMoveDown];
}

- (void)test_k_ActionShouldMoveUp {
  [fileOutlineView keyDown:KeyDownEvent('k')];
  [verify(actionDelegate) actionMoveUp];
}

- (void)test_h_ActionShouldOpenDefault {
  [fileOutlineView keyDown:KeyDownEvent('h')];
  [verify(actionDelegate) actionOpenDefault];
}

- (void)test_l_ActionShouldOpenDefault {
  [fileOutlineView keyDown:KeyDownEvent('l')];
  [verify(actionDelegate) actionOpenDefault];
}

- (void)test_G_ActionShouldMoveToBottom {
  [fileOutlineView keyDown:KeyDownEvent('G')];
  [verify(actionDelegate) actionMoveToBottom];
}

- (void)test_gg_ActionShouldMoveToTop {
  [fileOutlineView keyDown:KeyDownEvent('g')];
  [fileOutlineView keyDown:KeyDownEvent('g')];
  [verify(actionDelegate) actionMoveToTop];
}

- (void)test_ctrlE_ActionShouldScrollDownOneLine {
  [fileOutlineView keyDown:KeyDownEventWithModifiers('e', NSControlKeyMask)];
  [verify(actionDelegate) actionScrollDownOneLine];
}

- (void)test_ctrlY_ActionShouldScrollUpOneLine {
  [fileOutlineView keyDown:KeyDownEventWithModifiers('y', NSControlKeyMask)];
  [verify(actionDelegate) actionScrollUpOneLine];
}

- (void)test_ctrlF_ActionShouldScrollDownOneScreen {
  [fileOutlineView keyDown:KeyDownEventWithModifiers('f', NSControlKeyMask)];
  [verify(actionDelegate) actionScrollDownOneScreen];
}

- (void)test_ctrlB_ActionShouldScrollUpOneScreen {
  [fileOutlineView keyDown:KeyDownEventWithModifiers('b', NSControlKeyMask)];
  [verify(actionDelegate) actionScrollUpOneScreen];
}

- (void)test_down_arrow_ActionShouldMoveDown {
    [fileOutlineView keyDown:KeyDownEvent(NSDownArrowFunctionKey)];
    [verify(actionDelegate) actionMoveDown];
}

- (void)test_up_arrow_ActionShouldMoveUp {
    [fileOutlineView keyDown:KeyDownEvent(NSUpArrowFunctionKey)];
    [verify(actionDelegate) actionMoveUp];
}

- (void)test_left_arrow_ActionShouldOpenDefault {
    [fileOutlineView keyDown:KeyDownEvent(NSLeftArrowFunctionKey)];
    [verify(actionDelegate) actionOpenDefault];
}

- (void)test_right_arrow_ActionShouldOpenDefault {
    [fileOutlineView keyDown:KeyDownEvent(NSRightArrowFunctionKey)];
    [verify(actionDelegate) actionOpenDefault];
}

- (void)test_space_ActionShouldOpenDefault {
  [fileOutlineView keyDown:KeyDownEvent(' ')];
  [verify(actionDelegate) actionOpenDefault];
}

- (void)test_return_ActionShouldOpenDefault {
  [fileOutlineView keyDown:KeyDownEvent(NSCarriageReturnCharacter)];
  [verify(actionDelegate) actionOpenDefault];
}

- (void)test_o_ActionShouldOpenDefault {
  [fileOutlineView keyDown:KeyDownEvent('o')];
  [verify(actionDelegate) actionOpenDefault];
}

- (void)test_t_ActionShouldOpenInNewTabIfNodeIsFile {
  [given([actionDelegate actionNodeIsDirectory]) willReturnBool:NO];
  [fileOutlineView keyDown:KeyDownEvent('t')];
  [verify(actionDelegate) actionOpenInNewTab];
}

- (void)test_t_IsIgnoredIfNodeIsDirectory {
  [given([actionDelegate actionNodeIsDirectory]) willReturnBool:YES];
  [fileOutlineView keyDown:KeyDownEvent('t')];
  [verify(actionDelegate) actionIgnore];
}

- (void)test_s_ActionShouldOpenInVerticalSplitIfNodeIsFile {
  [given([actionDelegate actionNodeIsDirectory]) willReturnBool:NO];
  [fileOutlineView keyDown:KeyDownEvent('s')];
  [verify(actionDelegate) actionOpenInVerticalSplit];
}

- (void)test_s_IsIgnoredIfNodeIsDirectory {
  [given([actionDelegate actionNodeIsDirectory]) willReturnBool:YES];
  [fileOutlineView keyDown:KeyDownEvent('s')];
  [verify(actionDelegate) actionIgnore];
}

- (void)test_i_ActionShouldOpenInHorizontalSplitIfNodeIsFile {
  [fileOutlineView keyDown:KeyDownEvent('i')];
  [verify(actionDelegate) actionOpenInHorizontalSplit];
}

- (void)test_i_IsIgnoredIfNodeIsDirectory {
  [given([actionDelegate actionNodeIsDirectory]) willReturnBool:YES];
  [fileOutlineView keyDown:KeyDownEvent('i')];
  [verify(actionDelegate) actionIgnore];
}

- (void)testEscShouldFocusVimView {
  [fileOutlineView keyDown:KeyDownEvent(qEscCharacter)];
  [verify(actionDelegate) actionFocusVimView];
}

- (void)test_n_ShouldIgnoreIfThereIsNoPreviousSearch {
  [fileOutlineView keyDown:KeyDownEvent('n')];
  [verify(actionDelegate) actionIgnore];
}

- (void)test_n_ShouldSearchWithPreviousSearch {
  [self type:@"/search"];
  [fileOutlineView keyDown:KeyDownEvent(NSCarriageReturnCharacter)];
  [fileOutlineView keyDown:KeyDownEvent('n')];
  [verifyCount(actionDelegate, times(2)) actionSearch:@"search"];
  //[verifyCount(actionDelegate, times(2)) updateStatusMessage:@"/search"];

}

- (void)test_N_ShouldIgnoreIfThereIsNoPreviousSearch {
  [fileOutlineView keyDown:KeyDownEvent('N')];
  [verify(actionDelegate) actionIgnore];
}

- (void)test_n_ShouldReverseSearchWithPreviousSearch {
  [self type:@"/search"];
  [fileOutlineView keyDown:KeyDownEvent(NSCarriageReturnCharacter)];
  [fileOutlineView keyDown:KeyDownEvent('N')];
  [verifyCount(actionDelegate, times(1)) actionReverseSearch:@"search"];
  //[verifyCount(actionDelegate, times(2)) updateStatusMessage:@"/search"];
}

- (void)test_slash_ShouldDisplaySearchStatusMessage {
  [fileOutlineView keyDown:KeyDownEvent('/')];
  [verify(actionDelegate) updateStatusMessage:@"/"];
}

- (void)test_m_ActionShouldDisplayMenuStatusMessage {
  [fileOutlineView keyDown:KeyDownEvent('m')];
  [verify(actionDelegate) updateStatusMessage:@"Actions: (a)dd (m)ove (d)elete (c)opy"];
}

#pragma mark Search Tests

- (void)testSearchShouldUpdateStatusMessage {
  [fileOutlineView keyDown:KeyDownEvent('/')];
  [fileOutlineView keyDown:KeyDownEvent('a')];
  [verify(actionDelegate) updateStatusMessage:@"/a"];
  [fileOutlineView keyDown:KeyDownEvent('b')];
  [verify(actionDelegate) updateStatusMessage:@"/ab"];
}

- (void)testSearchShouldHandleDelete {
  [fileOutlineView keyDown:KeyDownEvent('/')];
  [fileOutlineView keyDown:KeyDownEvent('a')];
  [fileOutlineView keyDown:KeyDownEvent('b')];
  [fileOutlineView keyDown:KeyDownEvent(NSDeleteCharacter)];
  [verifyCount(actionDelegate, times(2)) updateStatusMessage:@"/a"];
}

- (void)testSearchShouldSearchOnReturnKey {
  [fileOutlineView keyDown:KeyDownEvent('/')];
  [fileOutlineView keyDown:KeyDownEvent('a')];
  [fileOutlineView keyDown:KeyDownEvent('b')];
  [verifyCount(actionDelegate, never()) actionSearch:anything()];
  [fileOutlineView keyDown:KeyDownEvent(NSCarriageReturnCharacter)];
  [verify(actionDelegate) actionSearch:@"ab"];
}

- (void)testSearchWithNothingShouldBeIgnored {
  [fileOutlineView keyDown:KeyDownEvent('/')];
  [fileOutlineView keyDown:KeyDownEvent(NSCarriageReturnCharacter)];
  [verifyCount(actionDelegate, never()) actionSearch:anything()];
  [verifyCount(actionDelegate, times(1)) actionIgnore];
}

#pragma mark Menu Tests

- (void)testMenu_a_ShouldPromptToAddNode {
  [fileOutlineView keyDown:KeyDownEvent('m')];
  [fileOutlineView keyDown:KeyDownEvent('a')];
  [verify(actionDelegate) updateStatusMessage:@"Add node: "];
}

- (void)testMenu_a_ShouldAddNodeOnReturn {
  [fileOutlineView keyDown:KeyDownEvent('m')];
  [fileOutlineView keyDown:KeyDownEvent('a')];
  [self type:@"file"];
  [fileOutlineView keyDown:KeyDownEvent(NSCarriageReturnCharacter)];
  [verify(actionDelegate) actionAddPath:@"file"];
  assertThat([self isInNormalMode], isYes);
}

#pragma mark -

- (void)testMenu_m_ShouldPromptToMoveNode {
  [fileOutlineView keyDown:KeyDownEvent('m')];
  [fileOutlineView keyDown:KeyDownEvent('m')];
  [verify(actionDelegate) updateStatusMessage:@"Move to: "];
}

- (void)testMenu_m_ShouldCallCheckClobberForPathOnReturn {
  [fileOutlineView keyDown:KeyDownEvent('m')];
  [fileOutlineView keyDown:KeyDownEvent('m')];
  [self type:@"file"];
  [fileOutlineView keyDown:KeyDownEvent(NSCarriageReturnCharacter)];
  [verify(actionDelegate) actionCheckClobberForPath:@"file"];
}

- (void)testMenu_a_ShouldMoveIfPathDoesNotExist {
  [given([actionDelegate actionCheckClobberForPath:@"file"]) willReturnBool:NO];
  [fileOutlineView keyDown:KeyDownEvent('m')];
  [fileOutlineView keyDown:KeyDownEvent('m')];
  [self type:@"file"];
  [fileOutlineView keyDown:KeyDownEvent(NSCarriageReturnCharacter)];
  [verify(actionDelegate) actionMoveToPath:@"file"];
  assertThat([self isInNormalMode], isYes);
}

- (void)testMenu_m_ShouldShowConfirmationIfPathExists {
  [given([actionDelegate actionCheckClobberForPath:@"file"]) willReturnBool:YES];
  [fileOutlineView keyDown:KeyDownEvent('m')];
  [fileOutlineView keyDown:KeyDownEvent('m')];
  [self type:@"file"];
  [fileOutlineView keyDown:KeyDownEvent(NSCarriageReturnCharacter)];
  [verify(actionDelegate) updateStatusMessage:@"Overwrite existing file? (y)es (n)o"];
}

- (void)testMenu_a_ShouldAddIfConfirmed {
  [given([actionDelegate actionCheckClobberForPath:@"file"]) willReturnBool:YES];
  [fileOutlineView keyDown:KeyDownEvent('m')];
  [fileOutlineView keyDown:KeyDownEvent('m')];
  [self type:@"file"];
  [fileOutlineView keyDown:KeyDownEvent(NSCarriageReturnCharacter)];
  [fileOutlineView keyDown:KeyDownEvent('y')];
  [verifyCount(actionDelegate, times(1)) actionMoveToPath:@"file"];
  assertThat([self isInNormalMode], isYes);
}

- (void)testMenu_a_ShouldReturnToMenuMoveModeIfNotConfirmed {
  [given([actionDelegate actionCheckClobberForPath:@"file"]) willReturnBool:YES];
  [fileOutlineView keyDown:KeyDownEvent('m')];
  [fileOutlineView keyDown:KeyDownEvent('m')];
  [self type:@"file"];
  [fileOutlineView keyDown:KeyDownEvent(NSCarriageReturnCharacter)];
  [fileOutlineView keyDown:KeyDownEvent('n')];
  [verifyCount(actionDelegate, never()) actionAddPath:anything()];
  assertThat(@(fileOutlineView.actionMode), is(@(VRFileBrowserActionModeMenuMove)));
}

#pragma mark -


- (void)testMenu_c_ShouldPromptToCopyNode {
  [fileOutlineView keyDown:KeyDownEvent('m')];
  [fileOutlineView keyDown:KeyDownEvent('c')];
  [verify(actionDelegate) updateStatusMessage:@"Copy to: "];
}

- (void)testMenu_c_ShouldCallCheckClobberForPathOnReturn {
  [fileOutlineView keyDown:KeyDownEvent('m')];
  [fileOutlineView keyDown:KeyDownEvent('c')];
  [self type:@"file"];
  [fileOutlineView keyDown:KeyDownEvent(NSCarriageReturnCharacter)];
  [verify(actionDelegate) actionCheckClobberForPath:@"file"];
}

- (void)testMenu_a_ShouldCopyIfPathDoesNotExist {
  [given([actionDelegate actionCheckClobberForPath:@"file"]) willReturnBool:NO];
  [fileOutlineView keyDown:KeyDownEvent('m')];
  [fileOutlineView keyDown:KeyDownEvent('c')];
  [self type:@"file"];
  [fileOutlineView keyDown:KeyDownEvent(NSCarriageReturnCharacter)];
  [verify(actionDelegate) actionCopyToPath:@"file"];
}

- (void)testMenu_a_ShouldShowConfirmationIfPathExists {
  [given([actionDelegate actionCheckClobberForPath:@"file"]) willReturnBool:YES];
  [fileOutlineView keyDown:KeyDownEvent('m')];
  [fileOutlineView keyDown:KeyDownEvent('c')];
  [self type:@"file"];
  [fileOutlineView keyDown:KeyDownEvent(NSCarriageReturnCharacter)];
  [verify(actionDelegate) updateStatusMessage:@"Overwrite existing file? (y)es (n)o"];
}

- (void)testMenu_a_ShouldCopyIfConfirmed {
  [given([actionDelegate actionCheckClobberForPath:@"file"]) willReturnBool:YES];
  [fileOutlineView keyDown:KeyDownEvent('m')];
  [fileOutlineView keyDown:KeyDownEvent('c')];
  [self type:@"file"];
  [fileOutlineView keyDown:KeyDownEvent(NSCarriageReturnCharacter)];
  [fileOutlineView keyDown:KeyDownEvent('y')];
  [verifyCount(actionDelegate, times(1)) actionCopyToPath:@"file"];
}

- (void)testMenu_a_ShouldReturnToMenuCopyModeIfNotConfirmed {
  [given([actionDelegate actionCheckClobberForPath:@"file"]) willReturnBool:YES];
  [fileOutlineView keyDown:KeyDownEvent('m')];
  [fileOutlineView keyDown:KeyDownEvent('c')];
  [self type:@"file"];
  [fileOutlineView keyDown:KeyDownEvent(NSCarriageReturnCharacter)];
  [fileOutlineView keyDown:KeyDownEvent('n')];
  [verifyCount(actionDelegate, never()) actionCopyToPath:@"file"];
  assertThat(@(fileOutlineView.actionMode), is(@(VRFileBrowserActionModeMenuCopy)));
}

#pragma mark -


- (void)testMenu_d_ShouldPromptToDeleteNode {
  [fileOutlineView keyDown:KeyDownEvent('m')];
  [fileOutlineView keyDown:KeyDownEvent('d')];
  [verify(actionDelegate) updateStatusMessage:@"Delete? (y)es (n)o"];
}

- (void)testMenuDelete_y_ShouldDelete {
  [fileOutlineView keyDown:KeyDownEvent('m')];
  [fileOutlineView keyDown:KeyDownEvent('d')];
  [fileOutlineView keyDown:KeyDownEvent('y')];
  [verify(actionDelegate) actionDelete];
  assertThat([self isInNormalMode], isYes);
}

- (void)testMenuDelete_n_ShouldDoNothing {
  [fileOutlineView keyDown:KeyDownEvent('m')];
  [fileOutlineView keyDown:KeyDownEvent('d')];
  [fileOutlineView keyDown:KeyDownEvent('n')];
  [verifyCount(actionDelegate, never()) actionDelete];
  assertThat([self isInNormalMode], isYes);
}

#pragma mark Non-Normal Mode Escape Tests

- (void)testEscFromNonNormalModeShouldReturnToNormalMode {
  [fileOutlineView keyDown:KeyDownEvent('/')];
  assertThat([self isInNormalMode], isNo);
  [fileOutlineView keyDown:KeyDownEvent(qEscCharacter)];
  assertThat([self isInNormalMode], isYes);
}

- (void)testEscFromNonNormalModeShouldDisplayStatusMessage {
  [fileOutlineView keyDown:KeyDownEvent('/')];
  [fileOutlineView keyDown:KeyDownEvent(qEscCharacter)];
  [verify(actionDelegate) updateStatusMessage:@"Type <Esc> again to focus text"];
}

- (void)testEscFromNonNormalModeShouldNotFocusVimView {
  [fileOutlineView keyDown:KeyDownEvent('/')];
  [fileOutlineView keyDown:KeyDownEvent(qEscCharacter)];
  [verifyCount(actionDelegate, never()) actionFocusVimView];
}

#pragma mark Line Editing Mode Tests

- (void)testLineEditingCanHandleMultipleDeletes {
  [fileOutlineView keyDown:KeyDownEvent('/')];
  [fileOutlineView keyDown:KeyDownEvent('a')];
  [verifyCount(actionDelegate, times(1)) updateStatusMessage:@"/a"];
  [fileOutlineView keyDown:KeyDownEvent(NSDeleteCharacter)];
  [fileOutlineView keyDown:KeyDownEvent(NSDeleteCharacter)];
  [fileOutlineView keyDown:KeyDownEvent(NSDeleteCharacter)];
  [verifyCount(actionDelegate, times(4)) updateStatusMessage:@"/"];
}

@end


@interface VREmptyFileBrowserActionsTestCase : VRBaseTestCase

@end

@implementation VREmptyFileBrowserActionsTestCase {
  VRFileBrowserOutlineView *fileOutlineView;
  id<VRFileBrowserActionDelegate> actionDelegate;
}

- (void)setUp {
  [super setUp];
  actionDelegate = mockProtocol(@protocol(VRFileBrowserActionDelegate));
  fileOutlineView =[[VRFileBrowserOutlineView alloc] initWithFrame:CGRectZero];
  fileOutlineView.actionDelegate = actionDelegate;
  [given([actionDelegate actionCanActOnNode]) willReturnBool:NO];
}

- (void)testMenu_a_ShouldAddNodeOnReturn {
  [fileOutlineView keyDown:KeyDownEvent('m')];
  [fileOutlineView keyDown:KeyDownEvent('a')];
  assertThat(@(fileOutlineView.actionMode), is(@(VRFileBrowserActionModeMenuAdd)));
}

- (void)testMenu_m_CannotMove {
  [fileOutlineView keyDown:KeyDownEvent('m')];
  [fileOutlineView keyDown:KeyDownEvent('m')];
  [verify(actionDelegate) actionIgnore];
  assertThat(@(fileOutlineView.actionMode), is(@(VRFileBrowserActionModeNormal)));
}

- (void)testMenu_m_CannotDelete {
  [fileOutlineView keyDown:KeyDownEvent('m')];
  [fileOutlineView keyDown:KeyDownEvent('d')];
  [verify(actionDelegate) actionIgnore];
  assertThat(@(fileOutlineView.actionMode), is(@(VRFileBrowserActionModeNormal)));

}

- (void)testMenu_m_CannotCopy {
  [fileOutlineView keyDown:KeyDownEvent('m')];
  [fileOutlineView keyDown:KeyDownEvent('c')];
  [verify(actionDelegate) actionIgnore];
  assertThat(@(fileOutlineView.actionMode), is(@(VRFileBrowserActionModeNormal)));
}

@end
