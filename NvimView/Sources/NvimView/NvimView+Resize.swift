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

      let size = self.discreteSize(size: newSize)
      self.ugrid.resize(size)
      self.launchNeoVim(size)

      return
    }

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
    let discreteSize = self.discreteSize(size: size)
    if discreteSize == self.ugrid.size {
      self.markForRenderWholeView()
      return
    }

    self.offset.x = floor((size.width - self.cellSize.width * discreteSize.width.cgf) / 2)
    self.offset.y = floor((size.height - self.cellSize.height * discreteSize.height.cgf) / 2)

    self.api.nvimUiTryResize(width: discreteSize.width, height: discreteSize.height)
      .subscribe(onError: { [weak self] error in
        self?.log.error("Error in \(#function): \(error)")
      })
      .disposed(by: self.disposeBag)
  }

  private func launchNeoVim(_ size: Size) {
    self.log.info("=== Starting neovim...")

    let inPipe: Pipe, outPipe: Pipe, errorPipe: Pipe
    do {
      (inPipe, outPipe, errorPipe) = try self.bridge.runLocalServerAndNvim(
        width: size.width, height: size.height
      )
    } catch let err as RxNeovimApi.Error {
      self.eventsSubject.onNext(.ipcBecameInvalid(
        "Could not launch neovim (\(err))."
      ))

      return
    } catch {
      self.eventsSubject.onNext(.ipcBecameInvalid(
        "Could not launch neovim."
      ))

      return
    }

    // We wait here, since the user of NvimView cannot subscribe
    // on the Completable. We could demand that the user call launchNeoVim()
    // by themselves, but...

    // See https://neovim.io/doc/user/ui.html#ui-startup for startup sequence
    // When we call nvim_command("autocmd VimEnter * call rpcrequest(1, 'vimenter')")
    // Neovim will send us a vimenter request and enter a blocking state.
    // We do some autocmd setup and send a response to exit the blocking state in
    // NvimView.swift
    try? self.api.run(inPipe: inPipe, outPipe: outPipe, errorPipe: errorPipe)
      .andThen(
        self.api.nvimGetApiInfo(errWhenBlocked: false)
          .flatMapCompletable { value in
            guard let info = value.arrayValue,
                  info.count == 2,
                  let channel = info[0].int32Value,
                  let dict = info[1].dictionaryValue,
                  let version = dict["version"]?.dictionaryValue,
                  let major = version["major"]?.intValue,
                  let minor = version["minor"]?.intValue
            else {
              throw RxNeovimApi.Error.exception(message: "Could not convert values to api info.")
            }

            guard (major >= kMinAlphaVersion && minor >= kMinMinorVersion) || major >=
              kMinMajorVersion
            else {
              self.eventsSubject.onNext(.ipcBecameInvalid(
                "Incompatible neovim version \(major).\(minor)"
              ))
              throw RxNeovimApi.Error.exception(message: "Incompatible neovim version.")
            }

            // swiftformat:disable all
          let vimscript = """
          function! GetHiColor(hlID, component)
            let color = synIDattr(synIDtrans(hlID(a:hlID)), a:component)
            if empty(color)
              return -1
            else
              return str2nr(color[1:], 16)
            endif
          endfunction
          let g:gui_vimr = 1
          autocmd VimLeave * call rpcnotify(\(channel), 'autocommand', 'vimleave')
          autocmd VimEnter * call rpcnotify(\(channel), 'autocommand', 'vimenter')
          autocmd ColorScheme * call rpcnotify(\(channel), 'autocommand', 'colorscheme', GetHiColor('Normal', 'fg'), GetHiColor('Normal', 'bg'), GetHiColor('Visual', 'fg'), GetHiColor('Visual', 'bg'), GetHiColor('Directory', 'fg'), GetHiColor('TablineFill', 'bg'), GetHiColor('TablineFill', 'fg'), GetHiColor('Tabline', 'bg'), GetHiColor('Tabline', 'fg'), GetHiColor('TablineSel', 'bg'), GetHiColor('TablineSel', 'fg'))
          autocmd VimEnter * call rpcrequest(\(channel), 'vimenter')
          """

          return self.api.nvimExec2(src: vimscript, opts: [:], errWhenBlocked: false)
            .asCompletable()
          // swiftformat:enable all
          }
      )
      .andThen(
        self.api.nvimUiAttach(width: size.width, height: size.height, options: [
          "ext_linegrid": true,
          "ext_multigrid": false,
          "ext_tabline": MessagePackValue(self.usesCustomTabBar),
          "rgb": true,
        ])
      )
      .wait()
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
