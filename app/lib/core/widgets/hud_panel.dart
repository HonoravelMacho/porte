import 'package:flutter/material.dart';
import '../theme/chamfered.dart';
import '../theme/porte_colors.dart';
import '../theme/porte_theme.dart';

/// Painel translúcido HUD com chanfro, header metálico e scanlines sutis.
/// Substitui Card/Material plano em todo o PORTE.
class HudPanel extends StatelessWidget {
  final String? title;
  final Widget child;
  final bool amber;
  final EdgeInsetsGeometry padding;
  final double chamfer;

  const HudPanel({
    super.key,
    this.title,
    required this.child,
    this.amber = false,
    this.padding = const EdgeInsets.all(12),
    this.chamfer = 14,
  });

  @override
  Widget build(BuildContext context) {
    final edge = amber ? PorteColors.amberNeon : PorteColors.cyanNeon;
    return ClipPath(
      clipper: ChamferedClipper(chamfer: chamfer),
      child: Container(
        decoration: hudDecoration(amber: amber),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      edge.withValues(alpha: 0.28),
                      Colors.transparent,
                    ],
                  ),
                  border: Border(bottom: BorderSide(color: edge.withValues(alpha: 0.5))),
                ),
                child: Text(
                  '// $title',
                  style: TextStyle(
                    color: edge,
                    fontFamily: 'monospace',
                    letterSpacing: 2,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            // Scanlines táteis (skeuomorphic)
            Container(
              padding: padding,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, PorteColors.scanline, Colors.transparent],
                  stops: [0.4, 0.5, 0.6],
                ),
              ),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

/// Botão neon chanfrado (ação primária = ciano, perigosa/alerta = âmbar).
class NeonButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool amber;
  const NeonButton({super.key, required this.label, this.icon, this.onPressed, this.amber = false});

  @override
  Widget build(BuildContext context) {
    final c = amber ? PorteColors.amberNeon : PorteColors.cyanNeon;
    return ClipPath(
      clipper: const ChamferedClipper(chamfer: 10),
      child: Material(
        color: c.withValues(alpha: 0.16),
        child: InkWell(
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(border: Border.all(color: c, width: 1.2)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: c),
                  const SizedBox(width: 8),
                ],
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    color: c,
                    fontFamily: 'monospace',
                    letterSpacing: 1.6,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// AppBar HUD do PORTE.
class PorteAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  const PorteAppBar({super.key, required this.title, this.actions, this.leading});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 8);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PorteColors.hull.withValues(alpha: 0.9),
        border: const Border(bottom: BorderSide(color: PorteColors.cyanDim)),
        boxShadow: const [
          BoxShadow(color: Color(0x5522E6FF), blurRadius: 12, spreadRadius: -6),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Builder(builder: (context) {
              if (leading != null) return leading!;
              if (Navigator.of(context).canPop()) {
                return IconButton(
                  icon: const Icon(Icons.chevron_left, color: PorteColors.cyanNeon),
                  onPressed: () => Navigator.of(context).maybePop(),
                );
              }
              return const SizedBox.shrink();
            }),
            const SizedBox(width: 4),
            const Icon(Icons.radar, color: PorteColors.amberNeon, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title.toUpperCase(),
                style: const TextStyle(
                  color: PorteColors.cyanNeon,
                  fontFamily: 'monospace',
                  letterSpacing: 2.4,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
            ...?actions,
          ],
        ),
      ),
    );
  }
}
