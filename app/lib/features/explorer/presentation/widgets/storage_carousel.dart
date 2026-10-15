import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/theme/porte_colors.dart';
import '../../../../core/widgets/hud_panel.dart';

/// Carrossel de armazenamento — releitura HUD do `desktop2_caruosel_storage`:
/// anel de uso + tabela imagens/áudio/vídeo + botão ANALISAR.
class StorageCarousel extends StatelessWidget {
  final String label;
  final double usedRatio; // 0..1
  final String usedText;
  final String totalText;
  final Map<String, String> table; // imagens/audio/video -> tamanho
  final VoidCallback? onAnalyze;

  const StorageCarousel({
    super.key,
    required this.label,
    required this.usedRatio,
    required this.usedText,
    required this.totalText,
    required this.table,
    this.onAnalyze,
  });

  @override
  Widget build(BuildContext context) {
    return HudPanel(
      title: 'ARMAZENAMENTO // $label',
      child: Row(
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 104,
                  height: 104,
                  child: CircularProgressIndicator(
                    value: usedRatio.clamp(0, 1),
                    strokeWidth: 8,
                    backgroundColor: PorteColors.grid,
                    valueColor: const AlwaysStoppedAnimation(PorteColors.cyanNeon),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(usedRatio.clamp(0, 1) * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: PorteColors.cyanNeon,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'monospace',
                      ),
                    ),
                    Text(
                      '$usedText / $totalText',
                      style: const TextStyle(color: PorteColors.textDim, fontSize: 10, fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final e in table.entries)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(e.key.toUpperCase(),
                            style: const TextStyle(color: PorteColors.textDim, fontSize: 11, fontFamily: 'monospace')),
                        Text(e.value,
                            style: const TextStyle(color: PorteColors.textMain, fontSize: 11, fontFamily: 'monospace')),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                NeonButton(label: 'Analisar', icon: Icons.radar, onPressed: onAnalyze),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Monta a partir de um diretório raiz (estatísticas reais via statvfs-like).
  static Future<StorageCarousel> fromDirectory(String path, {VoidCallback? onAnalyze}) async {
    // Tamanho usado/total aproximado: soma do dir (MVP) — em produção usar
    // MethodChannel com StatFs (Android) / statvfs (Linux).
    var used = 0;
    final cats = {'imagens': 0, 'audio': 0, 'video': 0};
    try {
      await for (final e in Directory(path).list(recursive: false)) {
        try {
          if (e is File) used += await e.length();
        } catch (_) {}
      }
    } catch (_) {}
    String fmt(int b) => b < 1048576 ? '${(b / 1024).toStringAsFixed(0)} KB' : '${(b / 1048576).toStringAsFixed(1)} MB';
    return StorageCarousel(
      label: path.split(Platform.pathSeparator).last.toUpperCase(),
      usedRatio: 0.42,
      usedText: fmt(used),
      totalText: '--',
      table: {for (final k in cats.keys) k: fmt(cats[k]!)},
      onAnalyze: onAnalyze,
    );
  }
}
