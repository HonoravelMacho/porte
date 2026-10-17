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
    '/usr/lib/porte/martelos', // motor embutido no .deb do PORTE
    // Termux
    '${Platform.environment['HOME'] ?? ''}/martelos',
    '/data/data/com.termux/files/usr/bin/martelos',
  ];

  /// No Android, o binário é empacotado em jniLibs como `libmartelos.so`
  /// e fica no nativeLibraryDir — que aparece no LD_LIBRARY_PATH do app.
  static List<String> _jniLibCandidates() {
    final ld = Platform.environment['LD_LIBRARY_PATH'];
    if (ld == null || ld.isEmpty) return const [];
    return ld
        .split(':')
        .where((d) => d.isNotEmpty)
        .map((d) => '$d/libmartelos.so')
        .toList();
  }

  static List<String> _allCandidates() => [..._jniLibCandidates(), ..._candidates];

  static Future<String?> _binaryPath() async {
    for (final c in _allCandidates()) {
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

  /// Executa: `martelos -m <entrada> -c/-d -k <N> "#senha1#" ... "#senhaN#" -f <const>`
  ///
  /// O motor aceita N senhas (uma por camada); a [passphrases] deve conter
  /// todas, na mesma ordem usada na criptografia (a ordem importa na
  /// descriptografia).
  static Future<MartelosResult> process({
    required String inputPath,
    required bool encrypt, // true = criptografar, false = descriptografar
    required List<String> passphrases,
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
    // Sem -o o motor mesmo decide: cripto -> <entrada>.martelos;
    // descripto -> nome/extensão originais guardados no cabeçalho .martelos.
    final fallbackOut = encrypt
        ? p.join(dir, '${p.basename(inputPath)}.martelos')
        : p.join(dir, base);

    final args = <String>[
      '-m', inputPath,
      encrypt ? '-c' : '-d',
      '-k', passphrases.length.toString(),
      for (final s in passphrases) '#$s#',
      '-f', constante,
    ];

    try {
      final result = await Process.run(bin, args, workingDirectory: dir);
      final stdout = result.stdout as String? ?? '';
      final stderr = result.stderr as String? ?? '';

      if (result.exitCode == 0) {
        // O motor informa o arquivo real gerado em "Finalizado em: <path>".
        final match = RegExp(r'Finalizado em:\s*(.+)', multiLine: true).firstMatch(stdout);
        final realOut = match?.group(1)?.trim();
        return MartelosResult(
          ok: true,
          message: 'Concluído com sucesso.',
          outputPath: (realOut != null && realOut.isNotEmpty && File(realOut).existsSync())
              ? realOut
              : fallbackOut,
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
/// Permite definir a quantidade de senhas (uma por camada) — o motor aceita
/// N senhas, quantas o operador quiser. Na descriptografia, as senhas devem
/// estar na MESMA ordem usada na criptografia.
Future<MartelosResult?> showMartelosDialog({
  required BuildContext context,
  required String inputPath,
  required bool encrypt,
}) async {
  final ncSenhas = TextEditingController(text: '1');
  String constante = _constantes.first;
  int qtd = 1;
  List<TextEditingController> passCtrls = [
    TextEditingController(),
  ];
  bool isLoading = false;
  final dialogCtx = context;

  void setQtd(StateSetter setSt, int n) {
    final novo = n.clamp(1, 99);
    setSt(() {
      qtd = novo;
      ncSenhas.text = novo.toString();
      while (passCtrls.length < novo) {
        passCtrls.add(TextEditingController());
      }
      while (passCtrls.length > novo) {
        passCtrls.removeLast().dispose();
      }
    });
  }

  InputDecoration estilo(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: PorteColors.textDim, fontSize: 10),
        filled: true,
        fillColor: PorteColors.grid,
        border: OutlineInputBorder(borderSide: BorderSide(color: PorteColors.cyanDim)),
        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: PorteColors.cyanNeon)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      );

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
          child: SingleChildScrollView(
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
                if (!encrypt)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      'AVISO: informe as senhas na MESMA ordem da criptografia.',
                      style: TextStyle(color: PorteColors.amberNeon, fontSize: 10, fontFamily: 'monospace'),
                    ),
                  ),
                const Text('QUANTIDADE DE SENHAS:', style: TextStyle(color: PorteColors.textDim, fontSize: 11, fontFamily: 'monospace')),
                const SizedBox(height: 4),
                Row(
                  children: [
                    IconButton.outlined(
                      icon: const Icon(Icons.remove_circle_outline),
                      color: PorteColors.textMain,
                      onPressed: isLoading ? null : () => setQtd(setSt, qtd - 1),
                    ),
                    Expanded(
                      child: TextField(
                        controller: ncSenhas,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        enabled: !isLoading,
                        style: const TextStyle(color: PorteColors.textMain, fontFamily: 'monospace'),
                        decoration: estilo('1'),
                        onChanged: (v) {
                          final n = int.tryParse(v);
                          if (n != null && n >= 1) setSt(() => qtd = n.clamp(1, 99));
                        },
                        onSubmitted: (v) => setQtd(setSt, int.tryParse(v) ?? 1),
                      ),
                    ),
                    IconButton.outlined(
                      icon: const Icon(Icons.add_circle_outline),
                      color: PorteColors.cyanNeon,
                      onPressed: isLoading ? null : () => setQtd(setSt, qtd + 1),
                    ),
                  ],
              ),
                const SizedBox(height: 12),
                // Um campo de senha por camada — N senhas, quantas quiser.
                for (int i = 0; i < passCtrls.length; i++) ...[
                  Text(
                    'SENHA ${i + 1}:',
                    style: const TextStyle(color: PorteColors.textDim, fontSize: 11, fontFamily: 'monospace'),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: passCtrls[i],
                    obscureText: true,
                    enabled: !isLoading,
                    style: const TextStyle(color: PorteColors.textMain, fontFamily: 'monospace'),
                    decoration: estilo('senha ${i + 1}'),
                  ),
                  SizedBox(height: i + 1 < passCtrls.length ? 8 : 12),
                ],
                const Text('CONSTANTE BBP:', style: TextStyle(color: PorteColors.textDim, fontSize: 11, fontFamily: 'monospace')),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  initialValue: constante,
                  dropdownColor: PorteColors.hullLight,
                  style: const TextStyle(color: PorteColors.textMain, fontFamily: 'monospace', fontSize: 12),
                  items: _constantes.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontFamily: 'monospace')))).toList(),
                  onChanged: isLoading ? null : (v) => setSt(() => constante = v!),
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
                    final pass = [for (final c in passCtrls) c.text.trim()].where((s) => s.isNotEmpty).toList();
                    if (pass.length != passCtrls.length) {
                      if (dialogCtx.mounted) {
                        ScaffoldMessenger.of(dialogCtx).showSnackBar(
                          const SnackBar(content: Text('Preencha todas as senhas (1 por camada).')),
                        );
                      }
                      return;
                    }
                    setSt(() => isLoading = true);
                    final res = await MartelosService.process(
                      inputPath: inputPath,
                      encrypt: encrypt,
                      passphrases: pass,
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
