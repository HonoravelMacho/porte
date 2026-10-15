import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Cache de ícones/thumbnails em memória (espelha o cache de ícones do
/// filemanager original). Evita re-decodificar a cada scroll.
class IconCache {
  static final IconCache instance = IconCache._();
  IconCache._();

  final Map<String, ImageProvider> _thumbs = {};
  final Map<String, Uint8List> _bytes = {};
  static const int maxEntries = 300;

  ImageProvider? get(String path) => _thumbs[path];

  void put(String path, ImageProvider provider) {
    if (_thumbs.length >= maxEntries) {
      _thumbs.remove(_thumbs.keys.first); // LRU simplificado
    }
    _thumbs[path] = provider;
  }

  void putBytes(String path, Uint8List bytes) {
    if (_bytes.length >= maxEntries) _bytes.remove(_bytes.keys.first);
    _bytes[path] = bytes;
  }

  Uint8List? getBytes(String path) => _bytes[path];

  void invalidate(String path) {
    _thumbs.remove(path);
    _bytes.remove(path);
  }

  void clear() {
    _thumbs.clear();
    _bytes.clear();
  }

  /// Ícone por categoria — usado enquanto o thumbnail carrega.
  static IconData iconFor(String category, bool isDir) {
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

  /// Cor neon por categoria (ciano base, âmbar para pacotes/executáveis).
  static Color colorFor(String category, bool isDir) {
    if (isDir) return const Color(0xFF22E6FF);
    return switch (category) {
      'pacotes' => const Color(0xFFFFB020),
      'video' => const Color(0xFFB388FF),
      'audio' => const Color(0xFF3DFFA2),
      _ => const Color(0xFF7D93B2),
    };
  }
}

/// Widget de ícone com thumbnail assíncrono + fallback de categoria.
class PorteFileIcon extends StatelessWidget {
  final String path;
  final String category;
  final bool isDir;
  const PorteFileIcon({super.key, required this.path, required this.category, required this.isDir});

  @override
  Widget build(BuildContext context) {
    final cached = IconCache.instance.get(path);
    if (cached != null) {
      return ClipRRect(borderRadius: BorderRadius.circular(4), child: Image(image: cached, fit: BoxFit.cover));
    }
    if (!isDir && (category == 'imagens')) {
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
        IconCache.iconFor(category, isDir),
        color: IconCache.colorFor(category, isDir),
        size: 30,
      );
}
