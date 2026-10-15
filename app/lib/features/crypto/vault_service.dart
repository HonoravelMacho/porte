import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:path/path.dart' as p;

/// Motor de criptografia do cofre PORTE (MVP):
/// - chave derivada via SHA-256(passphrase + salt);
/// - arquivos cifrados com AES-CBC (pacote encrypt);
/// - cada arquivo gera `.porte` (salt-len + salt + IV 16B + ciphertext).
/// NÃO é auditoria de segurança — evoluir para Argon2 + AES-GCM + autenticação.
class VaultService {
  final Directory vaultDir;
  VaultService(this.vaultDir);

  static Future<VaultService> open(Directory base) async {
    final v = Directory(p.join(base.path, '.porte_vault'));
    if (!await v.exists()) await v.create(recursive: true);
    return VaultService(v);
  }

  enc.Key _key(String passphrase, String salt) {
    final digest = sha256.convert(utf8.encode('$salt::$passphrase'));
    return enc.Key(Uint8List.fromList(digest.bytes));
  }

  Future<File> lock(File plain, String passphrase) async {
    final salt = DateTime.now().millisecondsSinceEpoch.toString();
    final key = _key(passphrase, salt);
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final bytes = await plain.readAsBytes();
    final cipher = encrypter.encryptBytes(bytes, iv: iv);
    final out = File(p.join(vaultDir.path, '${p.basename(plain.path)}.porte'));
    final saltBytes = utf8.encode(salt);
    final blob = <int>[saltBytes.length, ...saltBytes, ...iv.bytes, ...cipher.bytes];
    await out.writeAsBytes(blob);
    return out;
  }

  Future<File> unlock(File locked, String passphrase, String destPath) async {
    final blob = await locked.readAsBytes();
    final saltLen = blob[0];
    final salt = utf8.decode(blob.sublist(1, 1 + saltLen));
    final iv = enc.IV(Uint8List.fromList(blob.sublist(1 + saltLen, 1 + saltLen + 16)));
    final cipherBytes = blob.sublist(1 + saltLen + 16);
    final key = _key(passphrase, salt);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final plain = encrypter.decryptBytes(enc.Encrypted(Uint8List.fromList(cipherBytes)), iv: iv);
    final out = File(destPath);
    await out.writeAsBytes(plain);
    return out;
  }
}
