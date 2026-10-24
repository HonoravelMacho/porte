import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/theme/porte_colors.dart';
import '../../services/icon_cache.dart';
import '../../domain/file_entry.dart';
import '../../services/file_service.dart';
import 'package:intl/intl.dart';

String formatSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  const units = ['KB', 'MB', 'GB', 'TB'];
  var v = bytes / 1024.0;
  var i = 0;
  while (v >= 1024 && i < units.length - 1) {
    v /= 1024;
    i++;
  }
  return '${v.toStringAsFixed(1)} ${units[i]}';
}

/// Linha de arquivo — espelha `filelist_item` (ícone, nome, subinfo, checkbox).
/// Agora com suporte a preview de imagem/texto ao tapar.
class FileTile extends StatefulWidget {
  final FileEntry entry;
  final bool selected;
  final bool selectionMode;
  /// Pasta protegida por senha (badge de cadeado).
  final bool locked;
  /// Callback executado APÓS o preview ser fechado (navegar/abrir arquivo).
  final VoidCallback? onOriginalTap;
  final VoidCallback? onLongPress;
  final ValueChanged<bool>? onSelected;

  const FileTile({
    super.key,
    required this.entry,
    this.selected = false,
    this.selectionMode = false,
    this.locked = false,
    this.onOriginalTap,
    this.onLongPress,
    this.onSelected,
  });

  @override
  State<FileTile> createState() => _FileTileState();
}

class _FileTileState extends State<FileTile> {
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
    // Se já tem preview carregado, mostra o dialog
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

  @override
  Widget build(BuildContext context) {
    final sub = widget.entry.isDir
        ? DateFormat('dd/MM/yyyy HH:mm').format(widget.entry.modified)
        : '${formatSize(widget.entry.size)}  •  ${DateFormat('dd/MM/yyyy').format(widget.entry.modified)}';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: widget.selected ? PorteColors.cyanNeon.withValues(alpha: 0.14) : PorteColors.hull.withValues(alpha: 0.7),
        border: Border.all(
          color: widget.selected ? PorteColors.cyanNeon : PorteColors.grid,
        ),
        boxShadow: widget.selected
            ? const [BoxShadow(color: Color(0x4422E6FF), blurRadius: 10)]
            : null,
      ),
      child: ListTile(
        dense: true,
        leading: SizedBox(
          width: 40,
          height: 40,
          child: PorteFileIcon(path: widget.entry.path, category: widget.entry.category, isDir: widget.entry.isDir),
        ),
        title: Text(
          widget.entry.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
        ),
        subtitle: Text(
          sub,
          style: const TextStyle(color: PorteColors.textDim, fontFamily: 'monospace', fontSize: 11),
        ),
        trailing: widget.selectionMode
            ? Checkbox(
                value: widget.selected,
                activeColor: PorteColors.cyanNeon,
                onChanged: (v) => widget.onSelected?.call(v ?? false),
              )
            : widget.entry.isDir
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.locked) ...[
                        const Icon(Icons.lock_rounded, color: PorteColors.amberNeon, size: 14),
                        const SizedBox(width: 4),
                      ],
                      const Icon(Icons.chevron_right, color: PorteColors.amberNeon),
                    ],
                  )
                : const Icon(Icons.more_vert, color: PorteColors.textDim, size: 18),
        onTap: _handleTap,
        onLongPress: widget.onLongPress,
      ),
    );
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
}