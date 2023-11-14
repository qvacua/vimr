/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import MessagePack
import RxNeovim
import RxSwift

extension NvimView {
  override public func setFrameSize(_ newSize: NSSize) {
    super.setFrameSize(newSize)

    if self.isInitialResize {
      self.isInitialResize = false
      self.launchNeoVim(self.discreteSize(size: newSize))
      // FIXME: not clear why this is needed but otherwise
      // grid is too large
      self.resizeNeoVimUi(to: newSize)
      return
    }

    if self.usesLiveResize {
      self.resizeNeoVimUi(to: newSize)
      return
    }

    if self.inLiveResize || self.currentlyResizing { return }

    // There can be cases where the frame is resized not by live resizing,
    // eg when the window is resized by window management tools.
    // Thus, we make sure that the resize call is made when this happens.
    self.resizeNeoVimUi(to: newSize)
  }

  override public func viewDidEndLiveResize() {
    super.viewDidEndLiveResize()
    self.resizeNeoVimUi(to: self.bounds.size)
  }

  func discreteSize(size: CGSize) -> Size {
    Size(
      width: Int(floor(size.width / self.cellSize.width)),
      height: Int(floor(size.height / self.cellSize.height))
    )
  }

  func resizeNeoVimUi(to size: CGSize) {
    self.currentEmoji = self.randomEmoji()

    let discreteSize = self.discreteSize(size: size)
    if discreteSize == self.ugrid.size {
      self.markForRenderWholeView()
      return
    }

    self.offset.x = floor((size.width - self.cellSize.width * discreteSize.width.cgf) / 2)
    self.offset.y = floor((size.height - self.cellSize.height * discreteSize.height.cgf) / 2)

    self.api.uiTryResize(width: discreteSize.width, height: discreteSize.height)
      .subscribe(onError: { [weak self] error in
        self?.log.error("Error in \(#function): \(error)")
      })
      .disposed(by: self.disposeBag)
  }

  private func launchNeoVim(_ size: Size) {
    self.log.info("=== Starting neovim...")
    let sockPath = self.bridge.listenAddress

    self.log.info("NVIM_LISTEN_ADDRESS=\(sockPath)")

    self.bridge.runLocalServerAndNvim(width: size.width, height: size.height)

    // Wait for listen and socket creation to occur
    let timeout = Duration.seconds(4)
    let start_time = ContinuousClock.now
    while !FileManager.default.fileExists(atPath: sockPath) {
      usleep(1000)
      if ContinuousClock.now - start_time > timeout {
        self.eventsSubject.onNext(.ipcBecameInvalid(
          "Timeout waiting for neovim."
        ))
        return
      }
    }

    // We wait here, since the user of NvimView cannot subscribe
    // on the Completable. We could demand that the user call launchNeoVim()
    // by themselves, but...
    try?
      self.api.run(at: sockPath)
      .andThen(
        self.api.getApiInfo().map {
          value in
          guard let info = value.arrayValue,
                info.count == 2,
                let channel = info[0].int32Value,
                let dict = info[1].dictionaryValue,
                let version = dict["version"]?.dictionaryValue,
                let major = version["major"]?.intValue,
                let minor = version["minor"]?.intValue
          else {
            throw RxNeovimApi.Error
              .exception(message: "Could not convert values to api info.")
          }
          guard major >= 0 && minor >= 10 || major >= 1
          else {
            self.eventsSubject.onNext(.ipcBecameInvalid(
              "Incompatible neovim version \(major).\(minor)"
            ))
            throw RxNeovimApi.Error
              .exception(message: "Could not convert values to api info.")
          }

          Swift.print("######################### \(channel)")
          return channel
        }.flatMapCompletable {
          // FIXME: make lua
          self.api.exec2(src: """
          ":augroup vimr
          ":augroup!
          :autocmd VimEnter * call rpcnotify(\($0), 'autocommand', 'vimenter')
          :autocmd BufWinEnter * call rpcnotify(\(
            $0
          ), 'autocommand', 'bufwinenter', str2nr(expand('<abuf>')))
          :autocmd BufWinEnter * call rpcnotify(\(
            $0
          ), 'autocommand', 'bufwinleave', str2nr(expand('<abuf>')))
          :autocmd TabEnter * call rpcnotify(\(
            $0
          ), 'autocommand', 'tabenter', str2nr(expand('<abuf>')))
          :autocmd BufWritePost * call rpcnotify(\(
            $0
          ), 'autocommand', 'bufwritepost', str2nr(expand('<abuf>')))
          :autocmd BufEnter * call rpcnotify(\(
            $0
          ), 'autocommand', 'bufenter', str2nr(expand('<abuf>')))
          :autocmd DirChanged * call rpcnotify(\(
            $0
          ), 'autocommand', 'dirchanged', expand('<afile>'))
          :autocmd ColorScheme * call rpcnotify(\($0), 'autocommand', 'colorscheme', \
              get(nvim_get_hl(0, {'id': hlID('Normal')}), 'fg', -1), \
              get(nvim_get_hl(0, {'id': hlID('Normal')}), 'bg', -1), \
              get(nvim_get_hl(0, {'id': hlID('Visual')}), 'fg', -1), \
              get(nvim_get_hl(0, {'id': hlID('Visual')}), 'bg', -1), \
              get(nvim_get_hl(0, {'id': hlID('Directory')}), 'fg', -1))
          :autocmd ExitPre * call rpcnotify(\($0), 'autocommand', 'exitpre')
          :autocmd BufModifiedSet * call rpcnotify(\($0), 'autocommand', 'bufmodifiedset', \
              str2nr(expand('<abuf>')), getbufinfo(str2nr(expand('<abuf>')))[0].changed)
          :let g:gui_vimr = 1
          ":augroup END
          """, opts: [:]).asCompletable()

            .andThen(self.api.uiAttach(width: size.width, height: size.height, options: [
              "ext_linegrid": true,
              "ext_multigrid": false,
              "ext_tabline": MessagePackValue(self.usesCustomTabBar),
              "rgb": true,
            ]))
            .andThen(
              self.sourceFileUrls.reduce(Completable.empty()) { prev, url in
                prev
                  .andThen(
                    self.api.exec2(src: "source \(url.shellEscapedPath)", opts: ["output": true])
                      .map {
                        retval in
                        guard let output_value = retval["output"] ?? retval["output"],
                              let output = output_value.stringValue
                        else {
                          throw RxNeovimApi.Error
                            .exception(message: "Could not convert values to output.")
                        }
                        return output
                      }
                      .asCompletable()
                  )
              }
            )
        }
      ).wait()
  }

  private func randomEmoji() -> String {
    let idx = Int.random(in: 0..<emojis.count)
    guard let scalar = UnicodeScalar(emojis[idx]) else { return "😎" }

    return String(scalar)
  }
}

private let emojis: [UInt32] = [
  0x1F600...0x1F64F,
  0x1F910...0x1F918,
  0x1F980...0x1F984,
  0x1F9C0...0x1F9C0,
].flatMap { $0 }
