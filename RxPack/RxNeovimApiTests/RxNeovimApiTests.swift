/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import MessagePack
import RxSwift
import XCTest

class NvimMsgPackTests: XCTestCase {
  var nvim = RxNeovimApi()
  let disposeBag = DisposeBag()

  override func setUp() {
    super.setUp()

    // $ NVIM_LISTEN_ADDRESS=/tmp/nvim.sock nvim $SOME_FILES
    try? self.nvim.run(at: "/tmp/nvim.sock").wait()
  }

  override func tearDown() {
    super.tearDown()
    try? self.nvim
      .command(command: "q!")
      .wait()
    try? self.nvim.stop().wait()
  }

  func testSth() {
    let colorNames = [
      "Normal", // color and background-color
      "Directory", // a
      "StatusLine", // code background and foreground
      "NonText", // hr and block quote border
      "Question", // blockquote foreground
    ]

    typealias HlResult = [String: RxNeovimApi.Value]
    typealias ColorNameHlResultTuple = (colorName: String, hlResult: HlResult)
    typealias ColorNameObservableTuple = (colorName: String, observable: Observable<HlResult>)

    Observable
      .from(colorNames.map { colorName -> ColorNameObservableTuple in
        (
          colorName: colorName,
          observable: self.nvim
            .getHlByName(name: colorName, rgb: true)
            .asObservable()
        )
      })
      .flatMap { tuple -> Observable<(String, HlResult)> in
        Observable.zip(Observable.just(tuple.colorName), tuple.observable)
      }
      .subscribe(onNext: { (tuple: ColorNameHlResultTuple) in
        print(tuple)
      })
      .disposed(by: self.disposeBag)

//    Observable
//      .concat(colorNames.map { colorName in
//        self.nvim
//          .getHlByName(name: colorName, rgb: true)
//          .asObservable()
//      })
//      .enumerated()
//      .subscribe(onNext: { dict in print(dict) })
//      .disposed(by: self.disposeBag)

//    self.nvim
//      .getHlByName(name: "Normal", rgb: true)
//      .subscribe(onSuccess: { dict in
//        guard let f = dict["foreground"]?.uint64Value,
//              let b = dict["background"]?.uint64Value else { return }
//        print(String(format: "%06X %06X", f, b))
//      }, onError: { err in print(err) })
//      .disposed(by: self.disposeBag)

    sleep(1)
  }

  func testExample() {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .full
    let now = Date()
    let dispose = DisposeBag()
    for i in 0 ... 5 {
      self.nvim
        .command(
          command: "echo '\(formatter.string(from: now)) \(i)'"
        )
        .subscribe(onCompleted: { print("\(i) handled") })
        .disposed(by: dispose)
    }

    sleep(1)
  }
}
