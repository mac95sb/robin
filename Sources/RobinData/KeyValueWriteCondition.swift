import Foundation

/// Conditions supported by atomic durable key-value writes.
public enum KeyValueWriteCondition: Sendable {
  /// Insert or replace the value.
  case always
  /// Write only when the key is absent.
  case ifAbsent
  /// Write only when the key already exists.
  case ifPresent
  /// Replace an unexpired value only if its bytes still match the previously read value.
  case ifEqual(Data)
}
