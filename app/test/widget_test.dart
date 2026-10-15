import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:porte/main.dart';
import 'package:porte/features/explorer/services/file_service.dart';
import 'package:porte/features/explorer/domain/file_entry.dart';
import 'package:porte/features/terminal/terminal_service.dart'
    show terminalVerdictFromMap, TerminalResult;

void main() {
  testWidgets('PORTE boots to explorer', (WidgetTester tester) async {
    await tester.pumpWidget(const PorteApp());
    await tester.pump(); // sem settle: loading tem animação contínua
    expect(find.textContaining('PORTE'), findsWidgets);
  });

  test('FileEntry category mapping', () {
    FileEntry e(String name) => FileEntry(
          path: '/x/$name',
          name: name,
          kind: PorteEntryKind.file,
          size: 10,
          modified: DateTime(2024),
          extension: name.split('.').last,
        );
    expect(e('a.jpg').category, 'imagens');
    expect(e('a.mp3').category, 'audio');
    expect(e('a.mp4').category, 'video');
    expect(e('a.zip').category, 'pacotes');
  });

  test('FileService round-trip in temp dir', () async {
    final svc = FileService();
    final tmp = Directory.systemTemp.createTempSync('porte_test_');
    try {
      await svc.createFolder(tmp.path, 'sub');
      final list = await svc.list(tmp.path);
      expect(list.any((x) => x.name == 'sub'), isTrue);
      await svc.rename('${tmp.path}/sub', 'sub2');
      await svc.delete('${tmp.path}/sub2');
    } finally {
      await tmp.delete(recursive: true);
    }
  });

  test('FileService.byCategory filtra por extensao', () async {
    final svc = FileService();
    final tmp = Directory.systemTemp.createTempSync('porte_cat_');
    try {
      await File('${tmp.path}/foto.jpg').writeAsBytes([1, 2, 3]);
      await File('${tmp.path}/musica.mp3').writeAsBytes([1, 2, 3]);
      await File('${tmp.path}/nota.txt').writeAsBytes([1, 2, 3]);
      final imgs = await svc.byCategory(tmp.path, 'imagens');
      expect(imgs.map((e) => e.name), contains('foto.jpg'));
      expect(imgs.map((e) => e.name), isNot(contains('musica.mp3')));
      final docs = await svc.byCategory(tmp.path, 'docs');
      expect(docs.map((e) => e.name), contains('nota.txt'));
      expect(await svc.byCategory(tmp.path, 'inexistente'), isEmpty);
    } finally {
      await tmp.delete(recursive: true);
    }
  });

  // Regressão do terminal: o mapeamento do veredito nunca pode mudar
  // de significado sem quebrar este teste (protege o fluxo Termux).
  test('terminalVerdictFromMap preserva contrato', () {
    var o = terminalVerdictFromMap({'hasResult': true, 'err': -1, 'exitCode': 0});
    expect(o.result, TerminalResult.opened);

    o = terminalVerdictFromMap({'hasResult': true, 'err': 401, 'errmsg': 'x'});
    expect(o.result, TerminalResult.failed);
    expect(o.detail, contains('401'));

    o = terminalVerdictFromMap({'hasResult': false});
    expect(o.result, TerminalResult.failed);

    o = terminalVerdictFromMap({'hasResult': true});
    expect(o.result, TerminalResult.failed); // sem err => falha segura
  });
}
