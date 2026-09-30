import 'dart:math';

/// Utility to generate RFC 4122 compliant version 4 UUIDs.
class UuidGenerator {
  static final Random _random = Random.secure();

  /// Generates a RFC 4122 compliant version 4 UUID.
  static String generate() {
    final values = List<int>.generate(16, (i) => _random.nextInt(256));
    // Set version to 4 (bits 12-15 = 0100)
    values[6] = (values[6] & 0x0f) | 0x40;
    // Set variant to RFC 4122 (bits 6-7 = 10)
    values[8] = (values[8] & 0x3f) | 0x80;

    final buffer = StringBuffer();
    for (var i = 0; i < 16; i++) {
      if (i == 4 || i == 6 || i == 8 || i == 10) {
        buffer.write('-');
      }
      buffer.write(values[i].toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }
}
