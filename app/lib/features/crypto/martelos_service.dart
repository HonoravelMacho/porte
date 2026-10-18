import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import '../../../core/theme/porte_colors.dart';

/// Alvo do motor martelos:
/// - arquivo: qualquer arquivo -> .martelos (extensão guardada no cabeçalho)
/// - imagem / audio / video: modos "glitch" (transmutação de mídia, exigem ffmpeg)
enum MartelosAlvo { arquivo, imagem, audio, video }

/// Serviço que invoca o motor M.A.R.T.E.L.O.S. (engine em C, CLI) via processo nativo.
///
/// No Android, o binário vem embutido no próprio APK (jniLibs ARM64) junto com
/// ffmpeg/ffprobe estáticos — não precisa de Termux nem de apps externos.
class MartelosService {
  /// Sobrepõe o binário usado (usado pelos testes para garantir a versão
  /// correta do motor): se não-nulo, tem prioridade sobre tudo.
  static String? debugBinaryPath;
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

  /// No Android, o binário é empacotado em jniLibs (`libmartelos.so`) e
  /// extraído no nativeLibraryDir do próprio APK — o único ponto executável
  /// permitido pelo Android. O caminho do Termux (`/data/data/com.termux/...`)
  /// nunca funciona de dentro de outro app (sandbox/SELinux), por isso o
  /// motor vem embutido no PORTE em todas as ABIs.
  static const _channel = MethodChannel('dev.porte/terminal');

  static Future<List<String>> _jniLibCandidates() async {
    final out = <String>[];
    if (Platform.environment['LD_LIBRARY_PATH'] case final ld? when ld.isNotEmpty) {
      for (final d in ld.split(':')) {
        if (d.isNotEmpty) out.add('$d/libmartelos.so');
      }
    }
    if (Platform.isAndroid) {
      try {
        final env = await _channel.invokeMapMethod<String, dynamic>('nativeEnv');
        final nld = env?['nativeLibraryDir'] as String?;
        if (nld != null && nld.isNotEmpty && !out.contains('$nld/libmartelos.so')) {
          out.add('$nld/libmartelos.so');
        }
      } catch (_) {}
    }
    return out;
  }

  static Future<String?> _binaryPath() async {
    if (debugBinaryPath != null) return debugBinaryPath;
    for (final c in [...await _jniLibCandidates(), ..._candidates]) {
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

  /// Executa: `martelos -m/-i/-a/-v <entrada> -c/-d -k <N> "#senha1#" ... "#senhaN#" -f <const> [-o <nome>]`
  ///
  /// O motor aceita N senhas (uma por camada); [passphrases] deve conter
  /// todas, na mesma ordem usada na criptografia (a ordem importa na
  /// descriptografia). [alvo] escolhe o modo; [outputName] é o nome do
  /// arquivo de saída (opcional, só o nome — fica na pasta do arquivo).
  static Future<MartelosResult> process({
    required String inputPath,
    required bool encrypt, // true = criptografar, false = descriptografar
    required List<String> passphrases,
    required String constante, // pi | catalan | apery | clausen | arctan | log3
    MartelosAlvo alvo = MartelosAlvo.arquivo,
    String? outputName,
    Map<String, String>? environment, // para testes (simular PATH restrito)
  }) async {
    final bin = await _binaryPath();
    if (bin == null) {
      String diag = '';
      if (Platform.isAndroid) {
        String abis = '?';
        try {
          final env = await _channel.invokeMapMethod<String, dynamic>('nativeEnv');
          abis = env?['abis'] as String? ?? '?';
        } catch (_) {}
        diag = ' (ABI do aparelho: $abis)';
      }
      return MartelosResult(
        ok: false,
        message: 'Binário martelos não encontrado$diag. Instale o motor M.A.R.T.E.L.O.S. '
            '(engine em C com GMP) e coloque-o no PATH ou em /usr/local/bin/martelos.',
      );
    }

    final dir = p.dirname(inputPath);
    final fname = p.basename(inputPath);

    // Fallback do caminho de saída se o motor não reportar "Finalizado em:".
    final String fallbackOut;
    switch (alvo) {
      case MartelosAlvo.imagem:
        fallbackOut = p.join(dir, '$fname${encrypt ? '_glitch.bmp' : '_fix.bmp'}');
        break;
      case MartelosAlvo.audio:
        fallbackOut = p.join(dir, '$fname${encrypt ? '_glitch.wav' : '_fix.wav'}');
        break;
      case MartelosAlvo.video:
        fallbackOut = p.join(dir, '$fname${encrypt ? '_glitch.avi' : '_fix.avi'}');
        break;
      case MartelosAlvo.arquivo:
        fallbackOut = encrypt
            ? p.join(dir, '$fname.martelos') // cripto: <arquivo>.martelos
            : p.join(dir, fname.replaceAll('.martelos', '')); // descripto: cabeçalho recupera o nome
        break;
    }

    final flag = switch (alvo) {
      MartelosAlvo.imagem => '-i',
      MartelosAlvo.audio => '-a',
      MartelosAlvo.video => '-v',
      MartelosAlvo.arquivo => '-m',
    };

    final args = <String>[
      flag, inputPath,
      encrypt ? '-c' : '-d',
      '-k', passphrases.length.toString(),
      for (final s in passphrases) '#$s#',
      '-f', constante,
      if (outputName != null && outputName.trim().isNotEmpty) ...['-o', p.join(dir, outputName.trim())],
    ];

    try {
      final result = await Process.run(bin, args, workingDirectory: dir, environment: environment);
      final stdout = result.stdout as String? ?? '';
      final stderr = result.stderr as String? ?? '';

      // O motor informa o arquivo real gerado em "Finalizado em: <path>".
      final match = RegExp(r'Finalizado em:\s*(.+)', multiLine: true).firstMatch(stdout);
      final realOut = match?.group(1)?.trim();
      final caminhoRelativo = realOut != null && !p.isAbsolute(realOut) ? p.join(dir, realOut) : realOut;

      // SUCESSO DE VERDADE: o motor pode terminar com exit 0 mesmo em falha
      // (ex.: ffmpeg ausente imprimia "[❌]" e voltava 0). Um arquivo de saída
      // existente é o único veredito confiável.
      final saidaExiste = (caminhoRelativo != null && caminhoRelativo.isNotEmpty && File(caminhoRelativo).existsSync()) ||
          (outputName != null && outputName.trim().isNotEmpty && File(p.join(dir, outputName.trim())).existsSync()) ||
          File(fallbackOut).existsSync();
      final temErro = stdout.contains('[❌]') || stderr.contains('[❌]');
      final detalhes = stdout.trim().isEmpty ? stderr.trim() : stdout.trim();

      if (result.exitCode == 0 && saidaExiste && !temErro) {
        return MartelosResult(
          ok: true,
          message: 'Concluído com sucesso.',
          outputPath: caminhoRelativo ?? fallbackOut,
          details: detalhes,
        );
      }
      // Não deixa resíduo de tentativa falha.
      if (temErro) {
        for (final c in [caminhoRelativo, if (outputName != null) p.join(dir, outputName.trim())]) {
          try {
            if (c != null && c.isNotEmpty && File(c).existsSync()) File(c).deleteSync();
          } catch (_) {}
        }
      }
      // Primeira linha com "[❌ ...]" (e continuação indentada) explica a falha real.
      final falha = RegExp(r'\[❌\][^\n]*(?:\n    [^\n]*)*').firstMatch(detalhes);
      return MartelosResult(
        ok: false,
        message: falha?.group(0)?.replaceAll('\n', '  ') ?? 'Falha no motor martelos (exit ${result.exitCode}).',
        details: detalhes,
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
  final ctrlSaida = TextEditingController();
  String constante = _constantes.first;
  MartelosAlvo alvo = _alvoSugerido(inputPath, encrypt);
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
                const SizedBox(height: 12),
                const Text('ALVO:', style: TextStyle(color: PorteColors.textDim, fontSize: 11, fontFamily: 'monospace')),
                const SizedBox(height: 4),
                DropdownButtonFormField<MartelosAlvo>(
                  initialValue: alvo,
                  dropdownColor: PorteColors.hullLight,
                  style: const TextStyle(color: PorteColors.textMain, fontFamily: 'monospace', fontSize: 12),
                  items: const [
                    DropdownMenuItem(value: MartelosAlvo.arquivo, child: Text('arquivo (.martelos)', style: TextStyle(fontFamily: 'monospace'))),
                    DropdownMenuItem(value: MartelosAlvo.imagem, child: Text('imagem (.bmp de chiado)', style: TextStyle(fontFamily: 'monospace'))),
                    DropdownMenuItem(value: MartelosAlvo.audio, child: Text('audio (.wav de chiado)', style: TextStyle(fontFamily: 'monospace'))),
                    DropdownMenuItem(value: MartelosAlvo.video, child: Text('video (.avi de chiado)', style: TextStyle(fontFamily: 'monospace'))),
                  ],
                  onChanged: isLoading ? null : (v) => setSt(() => alvo = v!),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: PorteColors.grid,
                    border: OutlineInputBorder(borderSide: BorderSide(color: PorteColors.cyanDim)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: PorteColors.cyanNeon)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('NOME DO ARQUIVO DE SAÍDA (opcional):', style: TextStyle(color: PorteColors.textDim, fontSize: 11, fontFamily: 'monospace')),
                const SizedBox(height: 4),
                TextField(
                  controller: ctrlSaida,
                  enabled: !isLoading,
                  style: const TextStyle(color: PorteColors.textMain, fontFamily: 'monospace'),
                  decoration: estilo('Enter = nome automático do motor'),
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
                      alvo: alvo,
                      outputName: ctrlSaida.text,
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

/// Sugere um alvo pela extensão do arquivo escolhido.
MartelosAlvo _alvoSugerido(String path, bool encrypt) {
  if (encrypt) return MartelosAlvo.arquivo;
  // Na descriptografia, o arquivo pode ser um .martelos ou um artefato de chiado.
  final e = p.extension(path).toLowerCase();
  final e2 = e == '.martelos' || e == ''
      ? p.extension(p.basenameWithoutExtension(path)).toLowerCase()
      : e;
  if (e2 == '.bmp') return MartelosAlvo.imagem;
  if (e2 == '.wav') return MartelosAlvo.audio;
  if (e2 == '.avi') return MartelosAlvo.video;
  return MartelosAlvo.arquivo;
}
