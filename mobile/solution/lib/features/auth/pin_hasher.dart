import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Hashes app PINs with PBKDF2-HMAC-SHA256 and a random per-install salt, so
/// the PIN itself is never stored (not even in secure storage).
///
/// Stored format: `pbkdf2-sha256$<iterations>$<salt b64>$<hash b64>`.
class PinHasher {
  const PinHasher({this.iterations = 60000});

  final int iterations;

  Future<String> hash(String pin) async {
    final random = Random.secure();
    final salt = Uint8List.fromList(
        List<int>.generate(16, (_) => random.nextInt(256)));
    final iterations = this.iterations;
    final derived =
        await Isolate.run(() => _pbkdf2(utf8.encode(pin), salt, iterations));
    return 'pbkdf2-sha256\$$iterations\$${base64Encode(salt)}\$${base64Encode(derived)}';
  }

  Future<bool> verify(String pin, String stored) async {
    final parts = stored.split(r'$');
    if (parts.length != 4 || parts[0] != 'pbkdf2-sha256') return false;
    final iterations = int.tryParse(parts[1]);
    if (iterations == null || iterations < 1) return false;
    final Uint8List salt;
    final Uint8List expected;
    try {
      salt = base64Decode(parts[2]);
      expected = base64Decode(parts[3]);
    } on FormatException {
      return false;
    }
    final actual =
        await Isolate.run(() => _pbkdf2(utf8.encode(pin), salt, iterations));
    return _constantTimeEquals(actual, expected);
  }
}

/// PBKDF2 with a single 32-byte output block (RFC 8018 §5.2).
Uint8List _pbkdf2(List<int> password, List<int> salt, int iterations) {
  final hmac = Hmac(sha256, password);
  var u = hmac.convert([...salt, 0, 0, 0, 1]).bytes;
  final out = Uint8List.fromList(u);
  for (var i = 1; i < iterations; i++) {
    u = hmac.convert(u).bytes;
    for (var j = 0; j < out.length; j++) {
      out[j] ^= u[j];
    }
  }
  return out;
}

bool _constantTimeEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a[i] ^ b[i];
  }
  return diff == 0;
}
