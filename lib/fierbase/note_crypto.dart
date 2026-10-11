// lib/fierbase/note_crypto.dart  (new file)
import 'dart:convert';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class NoteCrypto {
  NoteCrypto._();
  static final NoteCrypto instance = NoteCrypto._();

  final _storage = const FlutterSecureStorage();
  final _keys = <String, enc.Key>{};

  Future<enc.Key?> _key(String uid, {required bool create}) async {
    final cached = _keys[uid];
    if (cached != null) return cached;
    final name = 'marsa_note_key_$uid';
    final stored = await _storage.read(key: name);
    if (stored != null) return _keys[uid] = enc.Key.fromBase64(stored);
    if (!create) return null;
    final key = enc.Key.fromSecureRandom(32);
    await _storage.write(key: name, value: key.base64);
    return _keys[uid] = key;
  }

  Future<Map<String, String>> encryptJson(String uid, Map<String, dynamic> data) async {
    final key = (await _key(uid, create: true))!;
    final iv = enc.IV.fromSecureRandom(12);
    final sealed = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm))
        .encrypt(jsonEncode(data), iv: iv);
    return {'cipher': sealed.base64, 'iv': iv.base64};
  }

  Future<Map<String, dynamic>?> decryptJson(String uid, String cipher, String iv) async {
    try {
      final key = await _key(uid, create: false);
      if (key == null) return null;
      final plain = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm))
          .decrypt(enc.Encrypted.fromBase64(cipher), iv: enc.IV.fromBase64(iv));
      return jsonDecode(plain) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}