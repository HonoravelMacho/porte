import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:porte/features/security/lock_service.dart';

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('porte_locks');
  });

  tearDown(() async {
    await tmp.delete(recursive: true);
  });

  LockService make() => LockService(storePath: p.join(tmp.path, '.porte_locks.json'));

  test('protect + verify + isLocked', () async {
    final svc = make();
    await svc.load();
    final dir = p.join(tmp.path, 'docs');
    expect(LockService.instance.isLocked(dir), isFalse);

    expect(await svc.protect(dir, 'abc123'), isTrue);
    expect(svc.isLocked(dir), isTrue);
    expect(svc.verify(dir, 'abc123'), isTrue);
    expect(svc.verify(dir, 'errado'), isFalse);
  });

  test('password vazio não protege', () async {
    final svc = make();
    await svc.load();
    final dir = p.join(tmp.path, 'docs');
    expect(await svc.protect(dir, ''), isFalse);
    expect(svc.isLocked(dir), isFalse);
  });

  test('locks persistem entre instâncias (mesmo store)', () async {
    final dir = p.join(tmp.path, 'docs');
    final a = make();
    await a.load();
    await a.protect(dir, 'senha1');

    final b = make();
    await b.load();
    expect(b.isLocked(dir), isTrue);
    expect(b.verify(dir, 'senha1'), isTrue);
    expect(b.verify(dir, 'nope'), isFalse);
  });

  test('blockedBy pega a pasta em si e o ancestral más profundo', () async {
    final svc = make();
    await svc.load();
    final locked = p.join(tmp.path, 'docs');
    final child = p.join(locked, 'private');
    final free = p.join(tmp.path, 'music');
    expect(svc.blockedBy(free), isNull);

    await svc.protect(locked, 'x');
    expect(svc.blockedBy(locked), locked);
    expect(svc.blockedBy(child), locked);
    expect(svc.blockedBy(free), isNull);
  });

  test('unprotect após checagem remove o lock', () async {
    final svc = make();
    await svc.load();
    final dir = p.join(tmp.path, 'docs');
    await svc.protect(dir, 'abc');
    expect(svc.verify(dir, 'abc'), isTrue);

    await svc.unprotect(dir);
    expect(svc.isLocked(dir), isFalse);
  });

  test('rekey renomeia o lock e move subpastas junto', () async {
    final svc = make();
    await svc.load();
    final root = p.join(tmp.path, 'videos');
    final sub = p.join(root, 'secret');
    await svc.protect(root, 'um');
    await svc.protect(sub, 'dois');

    final novoRoot = p.join(tmp.path, 'vdeos');
    await svc.rekey(root, novoRoot);

    expect(svc.isLocked(root), isFalse);
    expect(svc.isLocked(novoRoot), isTrue);
    expect(svc.isLocked(p.join(sub)), isFalse);
    expect(svc.isLocked(p.join(novoRoot, 'secret')), isTrue);
    expect(svc.verify(novoRoot, 'um'), isTrue);
    expect(svc.verify(p.join(novoRoot, 'secret'), 'dois'), isTrue);
  });

  test('rekey idempotente (mesmo caminho) não quebra', () async {
    final svc = make();
    await svc.load();
    final dir = p.join(tmp.path, 'docs');
    await svc.protect(dir, 'z');
    await svc.rekey(dir, dir);
    expect(svc.isLocked(dir), isTrue);
    expect(svc.verify(dir, 'z'), isTrue);
  });

  test('store corrompido não explode (fail-open)', () async {
    await File(p.join(tmp.path, '.porte_locks.json')).writeAsString('{lixo json');
    final svc = make();
    await svc.load();
    expect(svc.isLocked(p.join(tmp.path, 'anything')), isFalse);
  });
}
