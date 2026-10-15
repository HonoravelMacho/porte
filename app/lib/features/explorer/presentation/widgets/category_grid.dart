import 'package:flutter/material.dart';
import '../../../../core/theme/porte_colors.dart';
import '../../../../core/theme/chamfered.dart';

/// Grade de categorias — releitura do `DesktopGridView` do original
/// (Imagens, Áudio, Vídeo, Docs, Pacotes, Downloads, Câmera, Vault...).
class CategoryGrid extends StatelessWidget {
  final ValueChanged<String> onOpen;
  const CategoryGrid({super.key, required this.onOpen});

  static const items = [
    ('imagens', Icons.image_rounded, 'IMAGENS'),
    ('audio', Icons.audio_file_rounded, 'ÁUDIO'),
    ('video', Icons.movie_rounded, 'VÍDEO'),
    ('docs', Icons.description_rounded, 'DOCS'),
    ('pacotes', Icons.inventory_2_rounded, 'APKs'),
    ('downloads', Icons.download_rounded, 'DOWNLOADS'),
    ('camera', Icons.photo_camera_rounded, 'CÂMERA'),
    ('vault', Icons.lock_rounded, 'COFRE'),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.86,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final (key, icon, label) = items[i];
        final amber = key == 'vault' || key == 'pacotes';
        final c = amber ? PorteColors.amberNeon : PorteColors.cyanNeon;
        return ClipPath(
          clipper: const ChamferedClipper(chamfer: 10),
          child: Material(
            color: PorteColors.hull.withValues(alpha: 0.85),
            child: InkWell(
              onTap: () => onOpen(key),
              child: Container(
                decoration: BoxDecoration(border: Border.all(color: c.withValues(alpha: 0.5))),
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: c, size: 26),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      style: TextStyle(
                        color: c,
                        fontSize: 9,
                        fontFamily: 'monospace',
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
