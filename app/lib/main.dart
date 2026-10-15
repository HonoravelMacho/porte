import 'dart:async';
import 'package:flutter/material.dart';
import 'core/theme/porte_colors.dart';
import 'core/theme/porte_theme.dart';
import 'features/explorer/presentation/explorer_page.dart';

void main() {
  runZonedGuarded(() {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
    };
    ErrorWidget.builder = (details) => PorteCrashScreen(details: details.toString());
    runApp(const PorteApp());
  }, (error, stack) {
    debugPrint('PORTE fatal: $error\n$stack');
  });
}

class PorteApp extends StatelessWidget {
  const PorteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PORTE',
      debugShowCheckedModeBanner: false,
      theme: buildPorteTheme(),
      home: const ExplorerPage(),
    );
  }
}

/// Tela de falha legível (HUD) — em vez de cinza silencioso, mostra o erro
/// para o usuário copiar e reportar (`/usr/lib/porte/porte` no terminal).
class PorteCrashScreen extends StatelessWidget {
  final String details;
  const PorteCrashScreen({super.key, required this.details});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: PorteColors.abyss,
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '// PORTE FALHOU NA INICIALIZAÇÃO',
                style: TextStyle(color: PorteColors.danger, fontFamily: 'monospace', letterSpacing: 2),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: SelectableText(details, style: const TextStyle(color: PorteColors.textMain, fontSize: 12)),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Reporte em github.com/HonoravelMacho/porte/issues',
                style: TextStyle(color: PorteColors.textDim, fontFamily: 'monospace', fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
