import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;

/// Serviço abstrato para geração de miniaturas de arquivos.
/// Define a interface que pode ser implementada por:
/// - [CacheThumbnailService]: usa o cache de ícones existente (fallback seguro)
/// - [NativeThumbnailService]: tenta usar ffmpeg para miniaturas de vídeo/imagem
abstract class ThumbnailService {
  /// Gera dados de preview para um arquivo.
  /// Retorna mapa com tipo ('image' ou 'text') e bytes/textos correspondentes.
  /// Retorna null se não for possível gerar preview.
  Future<Map<String, dynamic>?> getPreviewData(String path);
}

/// Serviço que usa o cache de ícones existente (seguro, sem dependências nativas).
/// Retorna miniaturas de imagem quando o arquivo for do tipo 'imagens', 
/// ou preview de texto para arquivos documentais.
class CacheThumbnailService extends ThumbnailService {
  @override
  Future<Map<String, dynamic>?> getPreviewData(String path) async {
    final ext = p.extension(path).toLowerCase();
    final file = File(path);
    if (!await file.exists()) return null;

    // Imagens: retorna os primeiros bytes (limite 500KB) para display rápido
    if (['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp', '.svg', '.heic'].contains(ext)) {
      try {
        final bytes = await file.readAsBytes();
        if (bytes.isNotEmpty) {
          final int limit = 500 * 1024;
          final subBytes = bytes.length <= limit ? bytes : bytes.sublist(0, limit);
          return {'type': 'image', 'bytes': subBytes};
        }
      } catch (_) {}
    }

    // Textos/Documentos: retorna primeiras 200 caracteres
    if (ext == '.txt' || ext == '.md' || ext == '.csv' || ext == '.json' || ext == '.html' || ext == '.xml') {
      try {
        final text = await file.readAsString();
        final trimmed = text.length > 200 ? '${text.substring(0, 200)}...' : text;
        return {'type': 'text', 'text': trimmed};
      } catch (_) {}
    }

    return null;
  }
}

/// Serviço que tenta usar ffmpeg nativo para gerar miniaturas.
/// Se ffmpeg não estiver disponível ou houver erro, cai para [CacheThumbnailService].
/// Nota: tratamento completo de miniatura ffmpeg virá na versão 1.0.0.
/// Por enquanto, o serviço sempre cai para o cache para garantir funcionamento.
class NativeThumbnailService extends ThumbnailService {
  @override
  Future<Map<String, dynamic>?> getPreviewData(String path) async {
    // Tenta extrair miniatura de vídeo usando ffmpeg
    if (_isVideoFile(path)) {
      // Tenta ffmpeg, mas cai para cache (tratamento completo virá em 1.0.0)
      await _tryFFmpegExtract(path);
    }

    // Para arquivos de imagem, usa o cache
    if (_isImageFile(path)) {
      // Usa cache para miniatura de imagem
      final cacheService = CacheThumbnailService();
      return cacheService.getPreviewData(path);
    }

    // Para outros tipos, tenta o fallback (cache)
    final cacheService = CacheThumbnailService();
    return cacheService.getPreviewData(path);
  }

  bool _isVideoFile(String path) {
    final ext = p.extension(path).toLowerCase();
    return ['.mp4', '.mkv', '.webm', '.3gp', '.avi', '.mov'].contains(ext);
  }

  bool _isImageFile(String path) {
    final ext = p.extension(path).toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp', '.svg', '.heic'].contains(ext);
  }

  /// Tenta extrair miniatura de vídeo usando ffmpeg.
  /// Por enquanto, apenas verifica se ffmpeg está disponível e cai para cache.
  /// O tratamento completo de miniatura (frame-a-frame, scaling, etc.) virá na versão 1.0.0.
  Future<void> _tryFFmpegExtract(String videoPath) async {
    try {
      final result = await Process.run(
        'ffmpeg',
        [
          '-i',
          videoPath,
          '-ss',
          '00:00:01.000',
          '-vframes',
          '1',
          '-f',
          'image2pipe',
          '-vcodec',
          'png',
          '-',
        ],
      );
      // Se chegou aqui, ffmpeg funcionou - mas ainda usamos cache para consistência
      // O tratamento completo de miniatura ffmpeg virá em versão futura
    } catch (_) {
      // ffmpeg não disponível - cai silenciosamente para cache
    }
  }
}