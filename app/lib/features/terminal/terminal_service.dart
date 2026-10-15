import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Resultado detalhado da tentativa de abrir o terminal,
/// para feedback exato na interface (em vez de true/false cego).
enum TerminalResult {
  /// Comando despachado. No Android, se o Termux abrir e fechar na hora,
  /// falta `termux-setup-storage` (permissão de arquivos do Termux).
  opened,
  /// O serviço do Termux não existe no aparelho (Termux ausente ou
  /// incompatível) — app já abriu a página de instalação.
  serviceMissing,
  /// O Android bloqueou o disparo (SecurityException). Geralmente restrição
  /// de execução em segundo plano ou política do fabricante.
  denied,
  /// Outra falha (sem terminal padrão no Linux, erro de Intent, etc).
  failed,
}

/// Abre um terminal nativo apontando para [directory].
///
/// - Android: via MethodChannel (MainActivity) que dispara o RUN_COMMAND
///   do Termux com cwd = pasta atual. Exige o Termux do **F-Droid**
///   (a versão da Play Store está descontinuada) + `termux-setup-storage`.
/// - Linux: lança o terminal padrão com workingDirectory.
class TerminalService {
  static const _channel = MethodChannel('dev.porte/terminal');

  Future<TerminalResult> openTerminal(String directory) async {
    if (Platform.isAndroid) return _openAndroid(directory);
    if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
      return (await _openDesktop(directory)) ? TerminalResult.opened : TerminalResult.failed;
    }
    return TerminalResult.failed;
  }

  // ---- Android: Termux ----
  Future<TerminalResult> _openAndroid(String directory) async {
    try {
      final status = await _channel.invokeMethod<String>('openTerminal', {'path': directory});
      return switch (status) {
        'ok' => TerminalResult.opened,
        'null_service' => TerminalResult.serviceMissing,
        'denied' => TerminalResult.denied,
        _ => TerminalResult.failed,
      };
    } on MissingPluginException catch (_) {
      return _openStoreFallback();
    } catch (e) {
      debugPrint('PORTE terminal channel: $e');
      return TerminalResult.failed;
    }
  }

  /// Sem o canal nativo: abre a página do Termux no F-Droid.
  Future<TerminalResult> _openStoreFallback() async {
    try {
      await launchUrl(Uri.parse('https://f-droid.org/packages/com.termux/'),
          mode: LaunchMode.externalApplication);
      return TerminalResult.serviceMissing;
    } catch (e) {
      debugPrint('PORTE termux fallback falhou: $e');
      return TerminalResult.failed;
    }
  }

  // ---- Desktop (Linux): terminal padrão com workingDirectory ----
  Future<bool> _openDesktop(String directory) async {
    const candidates = [
      ['x-terminal-emulator'],
      ['gnome-terminal', '--working-directory'],
      ['konsole', '--workdir'],
      ['xfce4-terminal', '--working-directory'],
      ['xterm', '-e', 'bash'],
    ];
    for (final cmd in candidates) {
      try {
        final exe = cmd.first;
        final args = cmd.length > 1 ? [...cmd.sublist(1), directory] : <String>[];
        final proc = await Process.start(exe, args,
            workingDirectory: directory, mode: ProcessStartMode.detached);
        // detached: não esperamos exitCode; se não lançou exceção, considera OK.
        unawaited(proc.exitCode.catchError((_) => -1));
        return true;
      } catch (_) {
        continue; // tenta o próximo emulador
      }
    }
    return false;
  }
}
