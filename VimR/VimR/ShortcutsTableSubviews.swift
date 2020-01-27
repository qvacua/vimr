/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import ShortcutRecorder

class ShortcutTableRow: NSTableRowView {

  init(withIdentifier identifier: String) {
    super.init(frame: .zero)
    self.identifier = NSUserInterfaceItemIdentifier(identifier)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

class ShortcutTableCell: NSTableCellView {

  static let font = NSFont.systemFont(ofSize: 13)
  static let boldFont = NSFont.boldSystemFont(ofSize: 13)

  var customized = false
  var isDir = false

  var text: String {
    get { self.textField!.stringValue }
    set { self.textField?.stringValue = newValue }
  }

  func setDelegateOfRecorder(_ delegate: RecorderControlDelegate) {
    self.shortcutRecorder.delegate = delegate
  }

  func bindRecorder(toKeyPath keypath: String, to content: Any) {
    self.shortcutRecorder.unbind(.value)
    self.shortcutRecorder.bind(
      .value,
      to: content,
      withKeyPath: keypath,
      options: [.valueTransformer: ValueTransformer.keyedUnarchiveFromDataTransformer]
    )
  }

  init(withIdentifier identifier: String) {
    super.init(frame: .zero)

    self.identifier = NSUserInterfaceItemIdentifier(identifier)

    self.textField = self._textField

    let textField = self._textField
    textField.font = ShortcutTableCell.font
    textField.isBordered = true
    textField.isBezeled = false
    textField.allowsEditingTextAttributes = false
    textField.isEditable = false
    textField.usesSingleLineMode = true
    textField.drawsBackground = false

    let recorder = self.shortcutRecorder
    recorder.allowsEscapeToCancelRecording = true
    recorder.allowsDeleteToClearShortcutAndEndRecording = true
    recorder.set(
      allowedModifierFlags: [.command, .shift, .option, .control],
      requiredModifierFlags: [],
      allowsEmptyModifierFlags: false
    )
    recorder.allowsDeleteToClearShortcutAndEndRecording = true
  }

  func reset() -> ShortcutTableCell {
    self.text = ""
    self.removeAllSubviews()
    return self
  }

  func layoutViews() {
    let textField = self._textField
    let recorder = self.shortcutRecorder

    textField.removeFromSuperview()
    recorder.removeFromSuperview()

    if self.isDir {
      textField.font = ShortcutTableCell.boldFont
    } else {
      textField.font = ShortcutTableCell.font
    }
    if self.customized {
      textField.textColor = .blue
    } else {
      textField.textColor = .textColor
    }

    self.addSubview(textField)
    guard !self.isDir else {
      textField.autoPinEdgesToSuperviewEdges(
        with: NSEdgeInsets(top: 3, left: 4, bottom: 3, right: 12)
      )
      return
    }

    self.addSubview(recorder)

    recorder.autoPinEdge(toSuperviewEdge: .right, withInset: 12)
    recorder.autoPinEdge(toSuperviewEdge: .top, withInset: 2)
    recorder.autoSetDimension(.width, toSize: 180)
    textField.autoPinEdge(toSuperviewEdge: .left, withInset: 4)
    textField.autoPinEdge(.right, to: .left, of: recorder, withOffset: -8)
    textField.autoPinEdge(toSuperviewEdge: .top, withInset: 3)
  }

  private let shortcutRecorder = RecorderControl(forAutoLayout: ())
  private let _textField = NSTextField(forAutoLayout: ())

  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

