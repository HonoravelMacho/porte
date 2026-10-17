import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../../../core/theme/porte_colors.dart';

/// Serviço que invoca o motor M.A.R.T.E.L.O.S. (engine em C, CLI) via processo nativo.
///
/// Requer o binário `martelos` instalado no dispositivo (ex.: `/usr/local/bin/martelos`
/// no Linux, ou no PATH do Termux no Android). Para arquivos genéricos (`-m`) o motor
/// só depende do GMP; não precisa de ffmpeg.
class MartelosService {
  static final List<String> _candidates = <String>[
    'martelos', // PATH
    '/usr/local/bin/martelos',
    '/usr/bin/martelos',
    '/opt/martelos/bin/martelos',
    // Termux
    '${Platform.environment['HOME'] ?? ''}/martelos',
    '/data/data/com.termux/files/usr/bin/martelos',
  ];

  static Future<String?> _binaryPath() async {
    for (final c in _candidates) {
      try {
        if (c == 'martelos') {
          final r = await Process.run('which', ['martelos']);
          if (r.exitCode == 0) return 'martelos';
          continue;
        }
        final f = File(c);
        if (await f.exists()) return c;
      } catch (_) {}
    }
    return null;
  }

  /// Executa: martelos -m <entrada> -c/-d -k <n> "#<chave>#" -f <const> -o <saida>
  static Future<MartelosResult> process({
    required String inputPath,
    required bool encrypt, // true = criptografar, false = descriptografar
    required String passphrase,
    required int layers,
    required String constante, // pi | catalan | apery | clausen | arctan | log3
    String? outputPath,
  }) async {
    final bin = await _binaryPath();
    if (bin == null) {
      return MartelosResult(
        ok: false,
        message: 'Binário martelos não encontrado. Instale o motor M.A.R.T.E.L.O.S. '
            '(engine em C com GMP) e coloque-o no PATH ou em /usr/local/bin/martelos.',
      );
    }

    final dir = p.dirname(inputPath);
    final base = p.basenameWithoutExtension(inputPath);
    final out = outputPath ?? p.join(dir, '${base}_martelos.${encrypt ? 'martelos' : 'out'}');

    final args = <String>[
      '-m', inputPath,
      encrypt ? '-c' : '-d',
      '-k', layers.toString(), '#$passphrase#',
      '-f', constante,
      '-o', out,
    ];

    try {
      final result = await Process.run(bin, args, workingDirectory: dir);
      final stdout = result.stdout as String? ?? '';
      final stderr = result.stderr as String? ?? '';

      if (result.exitCode == 0) {
        return MartelosResult(
          ok: true,
          message: 'Concluído com sucesso.',
          outputPath: out,
          details: stdout.trim().isEmpty ? stderr.trim() : stdout.trim(),
        );
      }
      return MartelosResult(
        ok: false,
        message: 'Falha no motor martelos (exit ${result.exitCode}).',
        details: stdout.trim().isNotEmpty ? stdout.trim() : stderr.trim(),
      );
    } on ProcessException catch (e) {
      return MartelosResult(
        ok: false,
        message: 'Não foi possível executar o martelos: ${e.message}',
      );
    } catch (e) {
      return MartelosResult(
        ok: false,
        message: 'Erro inesperado: $e',
      );
    }
  }

  static void showNotInstalled(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: PorteColors.danger,
        content: const Text(
          'M.A.R.T.E.L.O.S. não instalado. '
          'Instale o motor em C (engine + GMP) e coloque o binário `martelos` no PATH.',
          style: TextStyle(fontFamily: 'monospace', fontSize: 12),
        ),
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
          textColor: PorteColors.ok,
        ),
      ),
    );
  }
}

class MartelosResult {
  final bool ok;
  final String message;
  final String? outputPath;
  final String? details;
  MartelosResult({
    required this.ok,
    required this.message,
    this.outputPath,
    this.details,
  });
}

const List<String> _constantes = <String>['pi', 'catalan', 'apery', 'clausen', 'arctan', 'log3'];

/// Dialog para configurar e executar criptografia/descriptografia martelos.
Future<MartelosResult?> showMartelosDialog({
  required BuildContext context,
  required String inputPath,
  required bool encrypt,
}) async {
  final ctrlPass = TextEditingController();
  final ctrlLayers = TextEditingController(text: '1');
  String constante = _constantes.first;
  bool isLoading = false;
  final dialogCtx = context;

  final result = await showDialog<MartelosResult>(
    context: context,
    barrierDismissible: false,
    builder: (d) => StatefulBuilder(
      builder: (ctx, setSt) => AlertDialog(
        backgroundColor: PorteColors.hull,
        title: Text(
          encrypt ? 'MARTELOS // CRIPTOGRAFAR' : 'MARTELOS // DESCRIPTOGRAFAR',
          style: const TextStyle(color: PorteColors.cyanNeon, fontFamily: 'monospace', fontSize: 14),
        ),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('ARQUIVO:', style: TextStyle(color: PorteColors.textDim, fontSize: 11, fontFamily: 'monospace')),
              const SizedBox(height: 4),
              Text(
                p.basename(inputPath),
                style: const TextStyle(color: PorteColors.textMain, fontSize: 11, fontFamily: 'monospace'),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 14),
              const Text('CHAVE (senha):', style: TextStyle(color: PorteColors.textDim, fontSize: 11, fontFamily: 'monospace')),
              const SizedBox(height: 4),
              TextField(
                controller: ctrlPass,
                obscureText: true,
                style: const TextStyle(color: PorteColors.textMain, fontFamily: 'monospace'),
                decoration: InputDecoration(
                  hintText: 'sua senha aqui',
                  hintStyle: const TextStyle(color: PorteColors.textDim, fontSize: 10),
                  filled: true,
                  fillColor: PorteColors.grid,
                  border: OutlineInputBorder(borderSide: BorderSide(color: PorteColors.cyanDim)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: PorteColors.cyanNeon)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                ),
              ),
              const SizedBox(height: 12),
              const Text('CAMADAS:', style: TextStyle(color: PorteColors.textDim, fontSize: 11, fontFamily: 'monospace')),
              const SizedBox(height: 4),
              TextField(
                controller: ctrlLayers,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: PorteColors.textMain, fontFamily: 'monospace'),
                decoration: InputDecoration(
                  hintText: '1',
                  hintStyle: const TextStyle(color: PorteColors.textDim, fontSize: 10),
                  filled: true,
                  fillColor: PorteColors.grid,
                  border: OutlineInputBorder(borderSide: BorderSide(color: PorteColors.cyanDim)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: PorteColors.cyanNeon)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                ),
              ),
              const SizedBox(height: 12),
              const Text('CONSTANTE BBP:', style: TextStyle(color: PorteColors.textDim, fontSize: 11, fontFamily: 'monospace')),
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                initialValue: constante,
                dropdownColor: PorteColors.hullLight,
                style: const TextStyle(color: PorteColors.textMain, fontFamily: 'monospace', fontSize: 12),
                items: _constantes.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontFamily: 'monospace')))).toList(),
                onChanged: (v) => setSt(() => constante = v!),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: PorteColors.grid,
                  border: OutlineInputBorder(borderSide: BorderSide(color: PorteColors.cyanDim)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: PorteColors.cyanNeon)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: isLoading ? null : () => Navigator.pop(d),
            child: const Text('CANCELAR', style: TextStyle(color: PorteColors.textDim, fontFamily: 'monospace')),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: PorteColors.cyanNeon,
              foregroundColor: PorteColors.abyss,
            ),
            onPressed: isLoading
                ? null
                : () async {
                    final pass = ctrlPass.text.trim();
                    if (pass.isEmpty) {
                      if (dialogCtx.mounted) {
                        ScaffoldMessenger.of(dialogCtx).showSnackBar(
                          const SnackBar(content: Text('Informe a senha (chave).')),
                        );
                      }
                      return;
                    }
                    final layers = int.tryParse(ctrlLayers.text.trim()) ?? 1;
                    setSt(() => isLoading = true);
                    final res = await MartelosService.process(
                      inputPath: inputPath,
                      encrypt: encrypt,
                      passphrase: pass,
                      layers: layers,
                      constante: constante,
                    );
                    if (!dialogCtx.mounted) return;
                    setSt(() => isLoading = false);
                    Navigator.pop(d, res);
                  },
            child: isLoading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('EXECUTAR', style: TextStyle(color: PorteColors.abyss, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
          ),
        ],
      ),
    ),
  );
  return result;
}
