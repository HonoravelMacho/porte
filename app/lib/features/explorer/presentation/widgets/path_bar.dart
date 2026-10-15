import 'package:flutter/material.dart';
import '../../../../core/theme/porte_colors.dart';

/// PathBar estilo HUD — espelha `PathBar` do original (navegação por segmentos).
class PathBar extends StatelessWidget {
  final String currentPath;
  final ValueChanged<String> onNavigate;
  const PathBar({super.key, required this.currentPath, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final segs = currentPath.split('/').where((s) => s.isNotEmpty).toList();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: const BoxDecoration(
        color: Color(0xCC0B1220),
        border: Border(bottom: BorderSide(color: PorteColors.cyanDim)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        reverse: true,
        child: Row(
          children: [
            _seg(context, 'ROOT', '/', true),
            for (var i = 0; i < segs.length; i++)
              _seg(
                context,
                segs[i].toUpperCase(),
                '/${segs.sublist(0, i + 1).join('/')}',
                i == segs.length - 1,
              ),
          ],
        ),
      ),
    );
  }

  Widget _seg(BuildContext context, String label, String path, bool active) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('›', style: TextStyle(color: PorteColors.amberNeon)),
        TextButton(
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: () => onNavigate(path),
          child: Text(
            label,
            style: TextStyle(
              color: active ? PorteColors.cyanNeon : PorteColors.textDim,
              fontFamily: 'monospace',
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }
}
