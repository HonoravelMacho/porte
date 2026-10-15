import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';

// ---------- Ícones estáticos ----------
IconData iconFor(String category, bool isDir) {
  if (isDir) return Icons.folder_special_rounded;
  return switch (category) {
    'imagens' => Icons.image_rounded,
    'audio' => Icons.audio_file_rounded,
    'video' => Icons.movie_rounded,
    'docs' => Icons.description_rounded,
    'pacotes' => Icons.inventory_2_rounded,
    _ => Icons.insert_drive_file_rounded,
  };
}

Color colorFor(String category, bool isDir) {
  if (isDir) return const Color(0xFF22E6FF);
  return switch (category) {
    'pacotes' => const Color(0xFFFFB020),
    'video' => const Color(0xFFB388FF),
    'audio' => const Color(0xFF3DFFA2),
    _ => const Color(0xFF7D93B2),
  };
}

// ---------- Widget PorteFileIcon ----------
class PorteFileIcon extends StatelessWidget {
  /// Caminho do arquivo para cache/thumbnail.
  final String path;
  /// Categoria do arquivo (imagens, audio, video, docs, pacotes).
  final String category;
  /// Se é diretório.
  final bool isDir;
  const PorteFileIcon({
    super.key,
    required this.path,
    required this.category,
    required this.isDir,
  });

  @override
  Widget build(BuildContext context) {
    final cached = IconCache.instance.get(path);
    if (cached != null) {
      return ClipRRect(borderRadius: BorderRadius.circular(4), child: Image(image: cached, fit: BoxFit.cover));
    }
    if (!isDir && category == 'imagens') {
      return FutureBuilder<File>(
        future: Future.value(File(path)),
        builder: (context, snap) {
          final f = snap.data;
          if (f != null && f.existsSync()) {
            final provider = FileImage(f);
            IconCache.instance.put(path, provider);
            return ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image(image: provider, fit: BoxFit.cover, errorBuilder: (ctx, err, stack) => _fallback()),
            );
          }
          return _fallback();
        },
      );
    }
    return _fallback();
  }

  Widget _fallback() => Icon(
    iconFor(category, isDir),
    color: colorFor(category, isDir),
    size: 30,
  );
}

// ---------- IconCache ----------
class IconCache {
  static final IconCache instance = IconCache._();
  IconCache._();

  final Map<String, ImageProvider> _thumbs = {};
  final Map<String, Uint8List> _bytes = {};
  final Map<String, DateTime> _lastAccessed = {};
  static const int maxEntries = 200;

  ImageProvider? get(String path) => _thumbs[path];

  void put(String path, ImageProvider provider) {
    // LRU: remove entradas não acessadas há mais tempo
    _cleanIfNeeded();
    _thumbs[path] = provider;
    _lastAccessed[path] = DateTime.now();
  }

  void putBytes(String path, Uint8List bytes) {
    if (_bytes.length >= maxEntries) _bytes.remove(_bytes.keys.first);
    _bytes[path] = bytes;
  }

  Uint8List? getBytes(String path) => _bytes[path];

  void invalidate(String path) {
    _thumbs.remove(path);
    _bytes.remove(path);
    _lastAccessed.remove(path);
  }

  void clear() {
    _thumbs.clear();
    _bytes.clear();
    _lastAccessed.clear();
  }

  /// Remove entradas antigas (> 5min sem acesso) se acima do limite.
  void _cleanIfNeeded() {
    if (_thumbs.length <= maxEntries) return;
    final now = DateTime.now();
    final toRemove = _lastAccessed.entries
        .where((e) => now.difference(e.value).inMinutes > 5)
        .take(_thumbs.length - maxEntries)
        .map((e) => e.key)
        .toList();
    for (final key in toRemove) {
      _thumbs.remove(key);
      _lastAccessed.remove(key);
    }
  }
}