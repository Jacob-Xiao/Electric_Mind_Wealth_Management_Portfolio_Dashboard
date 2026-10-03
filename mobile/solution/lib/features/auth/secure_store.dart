import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Minimal key/value interface over the platform's secure storage, so the
/// auth logic can be unit-tested with an in-memory fake.
abstract class SecureKeyValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// Backed by `flutter_secure_storage`:
/// - Android: values are AES-256-GCM encrypted with a key that is wrapped by
///   an RSA key held in the Android Keystore (hardware-backed where
///   available), then stored in a private SharedPreferences file. A dump of
///   shared_prefs only shows ciphertext.
/// - iOS: Keychain, accessible only after first unlock on this device and
///   never migrated to other devices/backups.
class PlatformSecureStore implements SecureKeyValueStore {
  PlatformSecureStore([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            );

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

class InMemorySecureStore implements SecureKeyValueStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}
