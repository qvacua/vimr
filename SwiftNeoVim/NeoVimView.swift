/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift

public class NeoVimView: NSView {
  
  public var delegate: NeoVimViewDelegate?
  
  private let disposeBag = DisposeBag()

  private var foregroundColor = NSColor.blackColor()
  private var backgroundColor = NSColor.whiteColor()
  private var font = NSFont(name: "Menlo", size: 12)!
  
  private var cellSize: CGSize {
    return self.font.boundingRectForFont.size
  }
  
  private var lineGap: CGFloat = 2.0

  init(frame rect: NSRect = CGRectZero, uiEventObservable: Observable<NeoVim.UiEvent>) {
    super.init(frame: rect)
    
    uiEventObservable.subscribe(
      onNext: { event in
        switch event {
        case .Resize(let size):
          Swift.print("### resize: \(size)")
          let rectSize = CGSizeMake(
            CGFloat(size.columns) * self.cellSize.width,
            CGFloat(size.rows) * self.cellSize.height + self.lineGap * (CGFloat(size.rows - 1))
          )
          dispatch_async(dispatch_get_main_queue()) {
            self.delegate?.resizeToSize(rectSize)
          }
          
        case .MoveCursor(let position):
          Swift.print("### \(position)")
          
        case .Put(let string):
          Swift.print("### putting: \(string)")
        }
        
      }, onError: { error in
        Swift.print(error)
      }, onCompleted: { 
        Swift.print("ui event observable completed")
      }, onDisposed: {
        Swift.print("ui event observable disposed")
    }).addDisposableTo(self.disposeBag)
  }
  
  override public func drawRect(dirtyRect: NSRect) {
    self.backgroundColor.setFill()
    NSRectFill(dirtyRect)
  }

  required public init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
