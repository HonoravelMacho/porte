import 'package:flutter/material.dart';
import 'core/theme/porte_theme.dart';
import 'features/explorer/presentation/explorer_page.dart';

void main() {
  runApp(const PorteApp());
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
