/**
 * Tae Won Ha
 * http://qvacua.com
 * https://github.com/qvacua
 *
 * See LICENSE
 */

#import <Foundation/Foundation.h>

typedef enum {
    OCNoLinkS         = 0x00000001, // Don’t do link processing, block <a> tags
    OCNoImage         = 0x00000002, // Don’t do image processing, block <img>
    OCNoPants         = 0x00000004, // Don’t run smartypants()
    OCNoHtml          = 0x00000008, // Don’t allow raw html through AT ALL
    OCStrict          = 0x00000010, // Disable SUPERSCRIPT, RELAXED_EMPHASIS
    OCTagtext         = 0x00000020, // Process text inside an html tag; no <em>, no <bold>, no html or [] expansion
    OCNoExt           = 0x00000040, // Don’t allow pseudo-protocols
    OCCdata           = 0x00000080, // Generate code for xml ![CDATA[...]]
    OCNoSuperscript   = 0x00000100, // No A^B
    OCNoRelaxed       = 0x00000200, // Emphasis happens everywhere
    OCNoTables        = 0x00000400, // Don’t process PHP Markdown Extra tables.
    OCNoStrikethrough = 0x00000800, // Forbid ~~strikethrough~~
    OCToc             = 0x00001000, // Do table-of-contents processing
    OC1Compat         = 0x00002000, // Compatability with MarkdownTest_1.0
    OCAutoLink        = 0x00004000, // Make http://foo.com a link even without <>s
    OCSafeLink        = 0x00008000, // Paranoid check for link protocol
    OCNoHeader        = 0x00010000, // Don’t process document headers
    OCTabStop         = 0x00020000, // Expand tabs to 4 spaces
    OCNoDivQuote      = 0x00040000, // Forbid >%class% blocks
    OCNoAlphaList     = 0x00080000, // Forbid alphabetic lists
    OCNoDlist         = 0x00100000, // Forbid definition lists
    OCExtraFootnote   = 0x00200000, // Enable PHP Markdown Extra-style footnotes.
} OCMarkdownFlag;

@interface NSString (OCDiscount)

/**
* Parses the content of the string as markdown and produces an HTML fragment, ie without the html, header and body tags.
* Following flags are available from discount.
*
* Flag              |  Action
* ------------------+------------------------------------------------------------------------------
* OCNoLinkS         |  Don’t do link processing, block <a> tags
* OCNoImage         |  Don’t do image processing, block <img>
* OCNoPants         |  Don’t run smartypants()
* OCNoHtml          |  Don’t allow raw html through AT ALL
* OCStrict          |  Disable SUPERSCRIPT, RELAXED_EMPHASIS
* OCTagtext         |  Process text inside an html tag; no <em>, no <bold>, no html or [] expansion
* OCNoExt           |  Don’t allow pseudo-protocols
* OCCdata           |  Generate code for xml ![CDATA[...]]
* OCNoSuperscript   |  No A^B
* OCNoRelaxed       |  Emphasis happens everywhere
* OCNoTables        |  Don’t process PHP Markdown Extra tables.
* OCNoStrikethrough |  Forbid ~~strikethrough~~
* OCToc             |  Do table-of-contents processing
* OC1Compat         |  Compatability with MarkdownTest_1.0
* OCAutoLink        |  Make http://foo.com a link even without <>s
* OCSafeLink        |  Paranoid check for link protocol
* OCNoHeader        |  Don’t process document headers
* OCTabStop         |  Expand tabs to 4 spaces
* OCNoDivQuote      |  Forbid >%class% blocks
* OCNoAlphaList     |  Forbid alphabetic lists
* OCNoDlist         |  Forbid definition lists
* OCExtraFootnote   |  Enable PHP Markdown Extra-style footnotes.
*/
- (NSString *)htmlFromMarkdownWithFlags:(OCMarkdownFlag)flags;

/**
* Parses the content of the string as markdown and produces an HTML fragment, ie without the html, header and body tags.
* This method uses no flag, ie all extensions or features, which discount support, are enabled. If you want to use other
* flags, use -htmlFromMarkdownWithFlags:.
*/
- (NSString *)htmlFromMarkdown;

@end
