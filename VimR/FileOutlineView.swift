/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift

enum FileOutlineViewAction {

  case openFileItem(fileItem: FileItem)
}

class FileOutlineView: NSOutlineView, Flow {

  fileprivate let flow: EmbeddableComponent

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  var sink: Observable<Any> {
    return self.flow.sink
  }

  init(source: Observable<Any>) {
    self.flow = EmbeddableComponent(source: source)

    super.init(frame: CGRect.zero)
    self.translatesAutoresizingMaskIntoConstraints = false
  }

  override func keyDown(with event: NSEvent) {
    guard let char = event.charactersIgnoringModifiers?.characters.first else {
      super.keyDown(with: event)
      return
    }

    guard let item = self.selectedItem as? FileItem else {
      super.keyDown(with: event)
      return
    }

    switch char {
    case " ", "\r": // Why "\r" and not "\n"?
      if item.dir || item.package {
        self.toggle(item: item)
      } else {
        self.flow.publish(event: FileOutlineViewAction.openFileItem(fileItem: item))
      }

    default:
      super.keyDown(with: event)
    }
  }
}
