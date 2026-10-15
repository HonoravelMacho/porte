import 'package:flutter/material.dart';
import '../../../../core/theme/porte_colors.dart';
import '../../../../core/theme/chamfered.dart';
import '../../services/icon_cache.dart';
import '../../domain/file_entry.dart';
import 'file_tile.dart' show formatSize;

/// Bloco da grade — versão compacta do FileTile para o modo grade
/// (espelha o DesktopGridView do original).
class FileGridTile extends StatelessWidget {
  final FileEntry entry;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const FileGridTile({
    super.key,
    required this.entry,
    this.selected = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final c = IconCache.colorFor(entry.category, entry.isDir);
    return ClipPath(
      clipper: const ChamferedClipper(chamfer: 8),
      child: Material(
        color: selected
            ? PorteColors.cyanNeon.withValues(alpha: 0.18)
            : PorteColors.hull.withValues(alpha: 0.8),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: selected ? PorteColors.cyanNeon : c.withValues(alpha: 0.45)),
            ),
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Center(
                    child: SizedBox(
                      width: 52,
                      height: 52,
                      child: PorteFileIcon(path: entry.path, category: entry.category, isDir: entry.isDir),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  entry.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  entry.isDir ? 'PASTA' : formatSize(entry.size),
                  style: const TextStyle(color: PorteColors.textDim, fontFamily: 'monospace', fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
