import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Serviço de pastas protegidas por senha (v0.3.0):
/// - guarda caminho + salt + hash sha256(salt::senha) em JSON no armazenamento
///   privado do app (`.porte_locks.json`);
/// - funciona como barreira de UI: o PORTE pede senha antes de navegar/abrir
///   pastas protegidas (inclusive subpastas — ver [blockedBy]).
///
/// IMPORTANTE: NÃO cifra o conteúdo. Outros apps, o terminal ou um PC com
/// acesso ao armazenamento continuam lendo os arquivos. Confidencialidade
/// real continua sendo via cofre/MARTELOS (`vault_service.dart`).
class LockService {
  LockService({String? storePath}) : _storePathOverride = storePath;

  /// Instância global usada pela UI.
  static final LockService instance = LockService();

  final String? _storePathOverride;
  final Map<String, _LockRecord> _locks = {};
  bool _loaded = false;

  /// Carrega o store do disco (apenas uma vez). Silencioso: se falhar ou
  /// estiver corrompido, segue com nada protegido (fail-open).
  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    final f = await _storeFile();
    if (f == null || !await f.exists()) return;
    try {
      final raw = jsonDecode(await f.readAsString()) as Map;
      final data = (raw['locks'] as Map?) ?? const {};
      data.forEach((k, v) {
        try {
          final rec = _LockRecord.fromMap(Map<String, dynamic>.from(v as Map));
          if (rec != null) _locks[_norm(k as String)] = rec;
        } catch (_) {}
      });
    } catch (_) {}
  }

  /// A pasta [target] (ou um ancestral dela) está protegida?
  /// Devolve o caminho bloqueado mais próximo (pasta em si) ou null.
  String? blockedBy(String target) {
    final t = _norm(target);
    if (isLocked(t)) return t;
    String? best;
    for (final lockPath in _locks.keys) {
      if (p.isWithin(lockPath, t)) {
        if (best == null || lockPath.length > best.length) best = lockPath;
      }
    }
    return best;
  }

  bool isLocked(String path) => _locks.containsKey(_norm(path));

  /// Confere a senha de uma pasta protegida.
  bool verify(String dirPath, String password) {
    final rec = _locks[_norm(dirPath)];
    return rec?.matches(password) ?? false;
  }

  /// Protege [dirPath] com [password] (salt aleatório por pasta).
  Future<bool> protect(String dirPath, String password) async {
    if (password.isEmpty) return false;
    _locks[_norm(dirPath)] = _LockRecord.fresh(password);
    await _save();
    return true;
  }

  /// Remove a proteção (chamar só após [verify] passar).
  Future<void> unprotect(String dirPath) async {
    if (_locks.remove(_norm(dirPath)) == null) return;
    await _save();
  }

  /// Move locks quando pastas são renomeadas/movidas (inclui subpastas).
  Future<void> rekey(String oldPath, String newPath) async {
    final o = _norm(oldPath);
    final n = _norm(newPath);
    if (o == n) return;
    final moved = <String, _LockRecord>{};
    for (final k in List<String>.from(_locks.keys)) {
      if (k == o) {
        moved[n] = _locks.remove(k)!;
      } else if (p.isWithin(o, k)) {
        moved[p.normalize(p.join(n, p.relative(k, from: o)))] = _locks.remove(k)!;
      }
    }
    _locks.addAll(moved);
    if (moved.isNotEmpty) {
      await _save();
    }
  }

  String _norm(String path) => p.normalize(trimTrailingSep(path));

  static String trimTrailingSep(String path) {
    while (path.length > 1 && path.endsWith(Platform.pathSeparator)) {
      path = path.substring(0, path.length - 1);
    }
    return path;
  }

  Future<File?> _storeFile() async {
    try {
      final override = _storePathOverride;
      if (override != null) return File(override);
      final dir = await getApplicationSupportDirectory();
      return File(p.join(dir.path, '.porte_locks.json'));
    } catch (_) {
      return null;
    }
  }

  Future<void> _save() async {
    final f = await _storeFile();
    if (f == null) return;
    try {
      await f.parent.create(recursive: true);
      final tmp = File('${f.path}.tmp');
      await tmp.writeAsString(jsonEncode({
        'v': 1,
        'locks': {for (final e in _locks.entries) e.key: e.value.toMap()},
      }));
      await tmp.rename(f.path);
    } catch (_) {}
  }
}

class _LockRecord {
  _LockRecord(this.salt, this.hash);

  final String salt;
  final String hash;

  static final Random _rand = Random.secure();

  factory _LockRecord.fresh(String password) {
    final salt = List.generate(8, (_) => _rand.nextInt(256))
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    return _LockRecord(salt, digest(salt, password));
  }

  static String digest(String salt, String password) =>
      sha256.convert(utf8.encode('$salt::$password')).toString();

  bool matches(String password) => digest(salt, password) == hash;

  Map<String, dynamic> toMap() => {'salt': salt, 'hash': hash};

  static _LockRecord? fromMap(Map<String, dynamic> m) {
    final salt = m['salt'];
    final hash = m['hash'];
    if (salt is! String || hash is! String || salt.isEmpty || hash.isEmpty) return null;
    return _LockRecord(salt, hash);
  }
}
