/*
import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';

class AesEncryptionServiceSimple {
  static const String encryptionKey = 'A1mZ14_c0BUQXS9zH7IwlIgi6c8dVc2r-xGQvumdDpw=';

  // Fixed: Properly derive key using SHA-256
  static encrypt.Key get _key {
    final bytes = utf8.encode(encryptionKey);
    final digest = sha256.convert(bytes);
    // Take first 32 bytes for AES-256 key
    final keyBytes = digest.bytes.sublist(0, 32);
    return encrypt.Key(Uint8List.fromList(keyBytes));
  }

  static encrypt.Encrypter get _encrypter {
    return encrypt.Encrypter(
        encrypt.AES(_key, mode: encrypt.AESMode.cbc)
    );
  }

  static String encryptAes(dynamic plaintext) {
    final text = plaintext is String ? plaintext : jsonEncode(plaintext);
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypted = _encrypter.encrypt(text, iv: iv);
    // Return IV + ciphertext combined as base64
    final combined = Uint8List(iv.bytes.length + encrypted.bytes.length);
    combined.setAll(0, iv.bytes);
    combined.setAll(iv.bytes.length, encrypted.bytes);
    return base64Encode(combined);
  }

  static String decryptAes(String ciphertextB64) {
    // Decode combined data
    final combined = base64Decode(ciphertextB64);

    // Extract IV (first 16 bytes)
    final ivBytes = combined.sublist(0, 16);
    final iv = encrypt.IV(Uint8List.fromList(ivBytes));

    // Extract ciphertext (remaining bytes)
    final ciphertextBytes = combined.sublist(16);
    final encrypted = encrypt.Encrypted(Uint8List.fromList(ciphertextBytes));

    // Decrypt
    final decrypted = _encrypter.decrypt(encrypted, iv: iv);
    return decrypted;
  }
}*/
