import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/theme/porte_colors.dart';
import '../../../../core/theme/chamfered.dart';
import '../../services/icon_cache.dart';
import '../../services/file_service.dart';
import '../../domain/file_entry.dart';
import 'file_tile.dart' show formatSize;

/// Bloco da grade — versão compacta do FileTile para o modo grade
/// (espelha o DesktopGridView do original). Agora com preview.
class FileGridTile extends StatefulWidget {
  final FileEntry entry;
  final bool selected;
  /// Pasta protegida por senha (badge de cadeado).
  final bool locked;
  /// Callback executado APÓS o preview ser fechado (navegar/abrir arquivo).
  final VoidCallback? onOriginalTap;
  final VoidCallback? onLongPress;

  const FileGridTile({
    super.key,
    required this.entry,
    this.selected = false,
    this.locked = false,
    this.onOriginalTap,
    this.onLongPress,
  });

  @override
  State<FileGridTile> createState() => _FileGridTileState();
}

class _FileGridTileState extends State<FileGridTile> {
  FileService _svc = FileService();
  Map<String, dynamic>? _previewData;
  bool _hasPreview = false;
  bool _isLoadingPreview = false;

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    if (_hasPreview) return;
    setState(() => _isLoadingPreview = true);
    final data = await _svc.getPreviewData(widget.entry.path);
    if (!mounted) return;
    setState(() {
      _previewData = data;
      _hasPreview = data != null;
      _isLoadingPreview = false;
    });
  }

  @override
  void dispose() {
    _previewData = null;
    super.dispose();
  }

  /// Mostra preview e, após o fechamento, chama onOriginalTap.
  Future<void> _handleTap() async {
    // Mostra preview primeiro (se houver dados compatíveis)
    if (_hasPreview && _previewData != null) {
      await _showPreviewDialog(context!);
      // Após o preview ser fechado, executa a ação original
      if (widget.onOriginalTap != null) widget.onOriginalTap!();
      return;
    }
    // Carrega preview sob demanda e mostra
    await _loadPreview();
    if (_hasPreview && _previewData != null) {
      await _showPreviewDialog(context!);
      if (widget.onOriginalTap != null) widget.onOriginalTap!();
    } else if (widget.onOriginalTap != null) {
      // Nenhum preview disponível; executa ação original imediatamente
      widget.onOriginalTap!();
    }
  }

  Future<void> _showPreviewDialog(BuildContext context) async {
    if (_previewData!['type'] == 'image') {
      await _showImagePreview(context);
    } else if (_previewData!['type'] == 'text') {
      await _showTextPreview(context);
    }
  }

  Future<void> _showImagePreview(BuildContext context) async {
    final bytes = _previewData!['bytes'] as List<int>;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: PorteColors.hull,
        title: Center(child: Text('Preview: ${widget.entry.name}', style: const TextStyle(color: PorteColors.cyanNeon, fontFamily: 'monospace'))),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.6,
          child: Image.memory(
            Uint8List.fromList(bytes),
            fit: BoxFit.contain,
            errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image, color: PorteColors.textDim),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('FECHAR', style: TextStyle(color: PorteColors.cyanNeon, fontFamily: 'monospace')),
          ),
        ],
      ),
    );
  }

  Future<void> _showTextPreview(BuildContext context) async {
    final text = _previewData!['text'] as String;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: PorteColors.hull,
        title: Center(child: Text('Preview: ${widget.entry.name}', style: const TextStyle(color: PorteColors.cyanNeon, fontFamily: 'monospace'))),
        content: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 400),
            child: SelectableText(
              text,
              style: const TextStyle(color: PorteColors.textMain, fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('FECHAR', style: TextStyle(color: PorteColors.cyanNeon, fontFamily: 'monospace')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = colorFor(widget.entry.category, widget.entry.isDir);
    return ClipPath(
      clipper: const ChamferedClipper(chamfer: 8),
      child: Material(
        color: widget.selected
            ? PorteColors.cyanNeon.withValues(alpha: 0.18)
            : PorteColors.hull.withValues(alpha: 0.8),
        child: InkWell(
          onTap: _handleTap,
          onLongPress: widget.onLongPress,
          child: Container(
            decoration: BoxDecoration(
              border: Border(),
            ),
            padding: const EdgeInsets.all(8),
            child: Stack(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Center(
                        child: SizedBox(
                          width: 52,
                          height: 52,
                          child: PorteFileIcon(path: widget.entry.path, category: widget.entry.category, isDir: widget.entry.isDir),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.entry.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.entry.isDir ? 'PASTA' : formatSize(widget.entry.size),
                      style: const TextStyle(color: PorteColors.textDim, fontFamily: 'monospace', fontSize: 10),
                    ),
                  ],
                ),
                if (widget.locked)
                  const Positioned(
                    top: 0,
                    right: 0,
                    child: Icon(Icons.lock_rounded, color: PorteColors.amberNeon, size: 14),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}