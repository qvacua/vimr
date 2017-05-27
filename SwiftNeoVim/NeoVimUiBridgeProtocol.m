@import Foundation;
#import "NeoVimUiBridgeProtocol.h"

extern NSString * __nonnull cursorModeShapeName(CursorModeShape mode) {
  switch (mode) {
    case CursorModeShapeNormal: return @"Normal";
    case CursorModeShapeVisual: return @"Visual";
    case CursorModeShapeInsert: return @"Insert";
    case CursorModeShapeReplace: return @"Replace";
    case CursorModeShapeCmdline: return @"Cmdline";
    case CursorModeShapeCmdlineInsert: return @"CmdlineInsert";
    case CursorModeShapeCmdlineReplace: return @"CmdlineReplace";
    case CursorModeShapeOperatorPending: return @"OperatorPending";
    case CursorModeShapeVisualExclusive: return @"VisualExclusive";
    case CursorModeShapeOnCmdline: return @"OnCmdline";
    case CursorModeShapeOnStatusLine: return @"OnStatusLine";
    case CursorModeShapeDraggingStatusLine: return @"DraggingStatusLine";
    case CursorModeShapeOnVerticalSepLine: return @"OnVerticalSepLine";
    case CursorModeShapeDraggingVerticalSepLine: return @"DraggingVerticalSepLine";
    case CursorModeShapeMore: return @"More";
    case CursorModeShapeMoreLastLine: return @"MoreLastLine";
    case CursorModeShapeShowingMatchingParen: return @"ShowingMatchingParen";
    case CursorModeShapeTermFocus: return @"TermFocus";
    case CursorModeShapeCount: return @"Count";
    default: return @"NON_EXISTING_MODE";
  }
}