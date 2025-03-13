/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import AsyncAlgorithms
import Combine
import Foundation

final class Throttler<T> {
  let publisher: AnyPublisher<T, Never>

  init(interval: DispatchQueue.SchedulerTimeType.Stride, latest: Bool = true) {
    self.publisher = self.subject.throttle(
      for: interval,
      scheduler: DispatchQueue.global(qos: .userInteractive),
      latest: latest
    )
    .eraseToAnyPublisher()
  }

  deinit {
    subject.send(completion: .finished)
  }

  func call(_ element: T) {
    self.subject.send(element)
  }

  private let subject = PassthroughSubject<T, Never>()
  private var cancellables = Set<AnyCancellable>()
}
