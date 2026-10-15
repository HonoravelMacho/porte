import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:porte/main.dart';
import 'package:porte/features/explorer/services/file_service.dart';
import 'package:porte/features/explorer/domain/file_entry.dart';

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
}
