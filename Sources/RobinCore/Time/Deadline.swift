/// A deadline tied to the injected clock that created it.
public struct Deadline<ClockType: Clock>: Sendable where ClockType: Sendable {
  public let clock: ClockType
  public let instant: ClockType.Instant

  public init(clock: ClockType, instant: ClockType.Instant) {
    self.clock = clock
    self.instant = instant
  }

  public init(clock: ClockType, after duration: ClockType.Duration) {
    self.init(clock: clock, instant: clock.now.advanced(by: duration))
  }

  public var hasPassed: Bool { clock.now >= instant }
  public var remaining: ClockType.Duration { clock.now.duration(to: instant) }
}
