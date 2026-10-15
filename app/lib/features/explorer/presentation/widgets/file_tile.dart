import 'package:flutter/material.dart';
import '../../../../core/theme/porte_colors.dart';
import '../../services/icon_cache.dart';
import '../../domain/file_entry.dart';
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
class FileTile extends StatelessWidget {
  final FileEntry entry;
  final bool selected;
  final bool selectionMode;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final ValueChanged<bool>? onSelected;

  const FileTile({
    super.key,
    required this.entry,
    this.selected = false,
    this.selectionMode = false,
    this.onTap,
    this.onLongPress,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final sub = entry.isDir
        ? DateFormat('dd/MM/yyyy HH:mm').format(entry.modified)
        : '${formatSize(entry.size)}  •  ${DateFormat('dd/MM/yyyy').format(entry.modified)}';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: selected ? PorteColors.cyanNeon.withValues(alpha: 0.14) : PorteColors.hull.withValues(alpha: 0.7),
        border: Border.all(
          color: selected ? PorteColors.cyanNeon : PorteColors.grid,
        ),
        boxShadow: selected
            ? const [BoxShadow(color: Color(0x4422E6FF), blurRadius: 10)]
            : null,
      ),
      child: ListTile(
        dense: true,
        leading: SizedBox(
          width: 40,
          height: 40,
          child: PorteFileIcon(path: entry.path, category: entry.category, isDir: entry.isDir),
        ),
        title: Text(
          entry.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
        ),
        subtitle: Text(
          sub,
          style: const TextStyle(color: PorteColors.textDim, fontFamily: 'monospace', fontSize: 11),
        ),
        trailing: selectionMode
            ? Checkbox(
                value: selected,
                activeColor: PorteColors.cyanNeon,
                onChanged: (v) => onSelected?.call(v ?? false),
              )
            : entry.isDir
                ? const Icon(Icons.chevron_right, color: PorteColors.amberNeon)
                : const Icon(Icons.more_vert, color: PorteColors.textDim, size: 18),
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }
}
