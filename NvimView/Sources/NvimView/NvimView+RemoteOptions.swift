/**
 * Renee Koecher -  @shirk
 * See LICENSE
 */

import Cocoa
import MessagePack

extension NvimView {
  enum RemoteOption {
    // list of currently handled remote options
    case guifont(fontSpec: String)
    case guifontWide(fontSpec: String)

    static func fromValuePair(_ option: (key: MessagePackValue, value: MessagePackValue)) -> RemoteOption? {
      switch option.key.stringValue ?? "" {
      case "guifont": return RemoteOption.guifont(fontSpec: option.value.stringValue ?? "")
      case "guifontwide": return RemoteOption.guifontWide(fontSpec: option.value.stringValue ?? "")

      default: return nil
      }
    }
  }

  final func handleRemoteOptions(_ options: [MessagePackValue: MessagePackValue]) {
    for kvPair in options {
      guard let option = RemoteOption.fromValuePair(kvPair) else {
        self.bridgeLogger.debug("Could not handle RemoteOption \(kvPair)")
        continue
      }

      switch(option) {
        // fixme: currently this treats gft and gfw the as the same
        case .guifont(let fontSpec): handleGuifontSet(fontSpec); break
        case .guifontWide(let fontSpec): handleGuifontSet(fontSpec); break
      }
    }
  }

  private final func handleGuifontSet(_ fontSpec: String) {
    let fontParams = fontSpec.components(separatedBy: ":")

    guard fontParams.count == 2 else {
      self.bridgeLogger.debug("Invalid specification for guifont '\(fontSpec)'")
      return
    }

    let fontName = fontParams[0].components(separatedBy: "_").joined(separator: " ")
    var fontSize = NvimView.defaultFont.pointSize // use a sane fallback

    if fontParams[1].hasPrefix("h") && fontParams[1].count >= 2 {
      let sizeSpec = fontParams[1].dropFirst()
      if let parsed = Float(sizeSpec)?.rounded() {
        fontSize = CGFloat(parsed)

        if fontSize < NvimView.minFontSize || fontSize > NvimView.maxFontSize {
          fontSize = NvimView.defaultFont.pointSize
        }
      }
    }

    if let newFont = NSFont(name: fontName, size: CGFloat(fontSize)) {
      gui.async {
        self.font = newFont
        self.markForRenderWholeView()
        self.eventsSubject.onNext(.guifontChanged(newFont))
      }
    } else {
      // todo: report an error back to NvimServer?
      self.bridgeLogger.debug("No valid font for name=\(fontName) size=\(fontSize)")
    }
  }
}

private let gui = DispatchQueue.main
