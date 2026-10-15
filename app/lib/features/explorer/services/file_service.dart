import 'dart:io';
import 'package:path/path.dart' as p;
import '../domain/file_entry.dart';

/// Operações básicas de arquivo (MVP fiel ao original):
/// listar, navegar, renomear, copiar, mover, excluir, criar pasta/arquivo,
/// calcular tamanho de pasta, buscar. Erros viram [FileOpException].
class FileOpException implements Exception {
  final String message;
  FileOpException(this.message);
  @override
  String toString() => 'FileOpException: $message';
}

class FileService {
  /// Lista e ordena (pastas primeiro). Inclui entrada ".." quando houver pai.
  Future<List<FileEntry>> list(String dirPath, {bool showHidden = false}) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) throw FileOpException('Diretório inexistente: $dirPath');
    final out = <FileEntry>[];
    try {
      await for (final e in dir.list(followLinks: false)) {
        final base = p.basename(e.path);
        if (!showHidden && base.startsWith('.')) continue;
        try {
          out.add(FileEntry.fromEntity(e));
        } catch (_) {/* ignora entidade ilegível */}
      }
    } on FileSystemException catch (e) {
      throw FileOpException('Sem acesso a $dirPath (${e.osError?.message ?? e.message})');
    }
    out.sort();
    final parent = Directory(dirPath).parent.path;
    if (parent != dirPath) {
      out.insert(
        0,
        FileEntry(path: parent, name: '..', kind: PorteEntryKind.parent, size: 0, modified: DateTime.now()),
      );
    }
    return out;
  }

  Future<Directory> createFolder(String parent, String name) async {
    final d = Directory(p.join(parent, name));
    if (await d.exists()) throw FileOpException('Pasta já existe: $name');
    return d.create();
  }

  Future<File> createFile(String parent, String name) async {
    final f = File(p.join(parent, name));
    if (await f.exists()) throw FileOpException('Arquivo já existe: $name');
    return f.create();
  }

  Future<void> rename(String path, String newName) async {
    final parent = p.dirname(path);
    final dest = p.join(parent, newName);
    if (await FileSystemEntity.type(dest) != FileSystemEntityType.notFound) {
      throw FileOpException('Destino já existe: $newName');
    }
    final type = await FileSystemEntity.type(path);
    if (type == FileSystemEntityType.directory) {
      await Directory(path).rename(dest);
    } else {
      await File(path).rename(dest);
    }
  }

  Future<void> delete(String path) async {
    final type = await FileSystemEntity.type(path, followLinks: false);
    if (type == FileSystemEntityType.directory) {
      await Directory(path).delete(recursive: true);
    } else if (type != FileSystemEntityType.notFound) {
      await File(path).delete();
    }
  }

  Future<void> copy(String src, String destDir) async {
    final dest = p.join(destDir, p.basename(src));
    final type = await FileSystemEntity.type(src);
    if (type == FileSystemEntityType.directory) {
      await _copyDir(Directory(src), Directory(dest));
    } else {
      await File(src).copy(dest);
    }
  }

  Future<void> move(String src, String destDir) async {
    final dest = p.join(destDir, p.basename(src));
    await File(src).rename(dest).catchError((_) async {
      // cross-device: copia + apaga
      await copy(src, destDir);
      await delete(src);
      return File(dest);
    });
  }

  Future<void> _copyDir(Directory src, Directory dest) async {
    await dest.create(recursive: true);
    await for (final e in src.list(followLinks: false)) {
      final d = p.join(dest.path, p.basename(e.path));
      if (e is Directory) {
        await _copyDir(e, Directory(d));
      } else if (e is File) {
        await e.copy(d);
      }
    }
  }

  /// Tamanho recursivo (usado no carrossel de armazenamento estilo desktop2).
  Future<int> dirSize(String path, {int budget = 4000}) async {
    var total = 0;
    var seen = 0;
    try {
      await for (final e in Directory(path).list(recursive: true, followLinks: false)) {
        if (seen++ > budget) break; // evita travar em árvores gigantes no MVP
        if (e is File) {
          try {
            total += await e.length();
          } catch (_) {}
        }
      }
    } catch (_) {}
    return total;
  }

  Future<List<FileEntry>> search(String root, String query, {int limit = 200}) async {
    final q = query.toLowerCase();
    final out = <FileEntry>[];
    try {
      await for (final e in Directory(root).list(recursive: true, followLinks: false)) {
        if (out.length >= limit) break;
        if (p.basename(e.path).toLowerCase().contains(q)) {
          try {
            out.add(FileEntry.fromEntity(e));
          } catch (_) {}
        }
      }
    } catch (_) {}
    out.sort();
    return out;
  }
}
