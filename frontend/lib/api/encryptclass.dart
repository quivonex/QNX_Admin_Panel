/*
import 'dart:convert';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import 'package:pointycastle/block/aes_fast.dart';

class AesEncryptionService {
  static const String _encryptionKey = 'YOUR_ENCRYPTION_KEY_HERE'; // Replace with your Django ENCRYPTION_KEY

  /// Derive 32-byte AES key using SHA-256
  static Uint8List _deriveKey() {
    final bytes = utf8.encode(_encryptionKey);
    final digest = SHA256Digest();
    final hash = Uint8List(32);
    digest.update(bytes, 0, bytes.length);
    digest.doFinal(hash, 0);
    return hash;
  }

  /// Encrypt data using AES-256-CBC
  static String encryptAes(dynamic plaintext) {
    String textToEncrypt;
    if (plaintext is String) {
      textToEncrypt = plaintext;
    } else {
      textToEncrypt = jsonEncode(plaintext);
    }

    final key = _deriveKey();
    final iv = _generateRandomBytes(16);

    // Create AES cipher in CBC mode
    final cipher = _createAESCipher(key, iv, true);

    // Pad the plaintext
    final plainBytes = utf8.encode(textToEncrypt);
    final paddedBytes = _padPKCS7(plainBytes, 16);

    // Encrypt
    final ciphertext = cipher.process(paddedBytes);

    // Combine IV + ciphertext and encode to base64
    final combined = Uint8List(iv.length + ciphertext.length);
    combined.setAll(0, iv);
    combined.setAll(iv.length, ciphertext);

    return base64Encode(combined);
  }

  /// Decrypt AES-256-CBC encrypted data
  static String decryptAes(String ciphertextB64) {
    print("Decrypting AES Starting...");

    try {
      final key = _deriveKey();
      final combined = base64Decode(ciphertextB64);

      // Extract IV (first 16 bytes)
      final iv = Uint8List.sublistView(combined, 0, 16);

      // Extract ciphertext (remaining bytes)
      final ciphertext = Uint8List.sublistView(combined, 16);

      // Create AES cipher in CBC mode for decryption
      final cipher = _createAESCipher(key, iv, false);

      // Decrypt
      final decryptedPadded = cipher.process(ciphertext);

      // Unpad
      final unpadded = _unpadPKCS7(decryptedPadded);

      String result = utf8.decode(unpadded);

      // ✅ Handle double-encoded JSON
      try {
        // Try to parse as JSON to unescape
        final parsed = jsonDecode(result);
        if (parsed is String) {
          // If it's a string, try to parse it again
          try {
            final nestedParsed = jsonDecode(parsed);
            return jsonEncode(nestedParsed);
          } catch (_) {
            return parsed;
          }
        }
        return jsonEncode(parsed);
      } catch (_) {
        // If not JSON, return as is
        return result;
      }
    } catch (e) {
      print('❌ AES Decryption Error: $e');
      // If decryption fails, return the original text
      return ciphertextB64;
    }
  }

  /// Create AES cipher in CBC mode
  static BlockCipher _createAESCipher(Uint8List key, Uint8List iv, bool forEncryption) {
    // ✅ FIXED: Properly create the parameters
    final params = ParametersWithIV<KeyParameter>(
      KeyParameter(key),
      iv,
    );

    final cipher = AESFastEngine();
    // ✅ FIXED: Initialize with the correct parameter type
    cipher.init(forEncryption, params as KeyParameter);
    return cipher;
  }

  /// Generate random bytes
  static Uint8List _generateRandomBytes(int length) {
    final secureRandom = SecureRandom('Fortuna')
      ..seed(KeyParameter(Uint8List(32)));
    return secureRandom.nextBytes(length);
  }

  /// PKCS#7 Padding
  static Uint8List _padPKCS7(List<int> data, int blockSize) {
    final padLength = blockSize - (data.length % blockSize);
    final padded = Uint8List(data.length + padLength);
    padded.setAll(0, data);
    padded.fillRange(data.length, padded.length, padLength);
    return padded;
  }

  /// PKCS#7 Unpadding
  static Uint8List _unpadPKCS7(Uint8List data) {
    if (data.isEmpty) {
      throw Exception('Invalid data for unpadding');
    }

    final padLength = data[data.length - 1];
    if (padLength < 1 || padLength > 16) {
      throw Exception('Invalid padding length');
    }

    for (var i = 0; i < padLength; i++) {
      if (data[data.length - 1 - i] != padLength) {
        throw Exception('Invalid padding');
      }
    }

    return Uint8List.sublistView(data, 0, data.length - padLength);
  }
}*/
