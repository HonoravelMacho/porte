import 'dart:io';

/// Entrada de arquivo/pasta — espelha `filelist_item` do app original
/// (ícone + nome + subinfo tamanho/data/permissão).
enum PorteEntryKind { parent, directory, file, link }

class FileEntry implements Comparable<FileEntry> {
  final String path;
  final String name;
  final PorteEntryKind kind;
  final int size;
  final DateTime modified;
  final String extension;

  const FileEntry({
    required this.path,
    required this.name,
    required this.kind,
    required this.size,
    required this.modified,
    this.extension = '',
  });

  bool get isDir => kind == PorteEntryKind.directory || kind == PorteEntryKind.parent;

  factory FileEntry.fromEntity(FileSystemEntity e) {
    final stat = e.statSync();
    final name = e.path.split(Platform.pathSeparator).lastWhere((s) => s.isNotEmpty, orElse: () => e.path);
    if (e is Directory) {
      return FileEntry(path: e.path, name: name, kind: PorteEntryKind.directory, size: 0, modified: stat.modified);
    }
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    return FileEntry(path: e.path, name: name, kind: PorteEntryKind.file, size: stat.size, modified: stat.modified, extension: ext);
  }

  /// Categoria estilo "desktop2" do original: imagens/áudio/vídeo/docs/apk/etc.
  String get category {
    const img = {'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'svg'};
    const aud = {'mp3', 'flac', 'ogg', 'aac', 'wav', 'm4a'};
    const vid = {'mp4', 'mkv', 'webm', '3gp', 'avi'};
    const doc = {'pdf', 'txt', 'md', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'csv'};
    const arc = {'zip', 'rar', '7z', 'tar', 'gz', 'jar', 'apk', 'apks', 'xapk'};
    if (isDir) return 'pasta';
    if (img.contains(extension)) return 'imagens';
    if (aud.contains(extension)) return 'audio';
    if (vid.contains(extension)) return 'video';
    if (doc.contains(extension)) return 'docs';
    if (arc.contains(extension)) return 'pacotes';
    return 'outros';
  }

  @override
  int compareTo(FileEntry other) {
    if (isDir != other.isDir) return isDir ? -1 : 1;
    return name.toLowerCase().compareTo(other.name.toLowerCase());
  }
}
