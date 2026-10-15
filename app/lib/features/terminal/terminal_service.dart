import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Resultado detalhado da tentativa de abrir o terminal,
/// com o detalhe técnico (ex.: mensagem da exceção) para diagnóstico.
class TerminalOutcome {
  final TerminalResult result;
  final String detail;
  const TerminalOutcome(this.result, [this.detail = '']);
  bool get opened => result == TerminalResult.opened;
}

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

  Future<TerminalOutcome> openTerminal(String directory) async {
    if (Platform.isAndroid) return _openAndroid(directory);
    if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
      return (await _openDesktop(directory))
          ? const TerminalOutcome(TerminalResult.opened)
          : const TerminalOutcome(TerminalResult.failed, 'nenhum emulador encontrado (x-terminal-emulator, gnome-terminal, konsole, xfce4-terminal, xterm)');
    }
    return const TerminalOutcome(TerminalResult.failed, 'plataforma sem suporte');
  }

  // ---- Android: Termux ----
  Future<TerminalOutcome> _openAndroid(String directory) async {
    try {
      final raw = await _channel.invokeMethod<String>('openTerminal', {'path': directory});
      if (raw == null || raw == 'ok') {
        return const TerminalOutcome(TerminalResult.opened);
      }
      // Formato "CODIGO: detalhe" vindo do Kotlin.
      final sep = raw.indexOf(':');
      final code = (sep < 0 ? raw : raw.substring(0, sep)).trim();
      final detail = sep < 0 ? '' : raw.substring(sep + 1).trim();
      return switch (code) {
        'null_service' => TerminalOutcome(TerminalResult.serviceMissing, detail),
        'denied' || 'denied_perm' => TerminalOutcome(TerminalResult.denied, detail),
        _ => TerminalOutcome(TerminalResult.failed, raw),
      };
    } on MissingPluginException catch (_) {
      return _openStoreFallback();
    } catch (e) {
      debugPrint('PORTE terminal channel: $e');
      return TerminalOutcome(TerminalResult.failed, '$e');
    }
  }

  /// Plano B: abre o app Termux (tela inicial) via launch intent.
  /// Não exige a permissão RUN_COMMAND — funciona sempre que o Termux
  /// estiver instalado. Retorna true se o Termux foi aberto.
  Future<bool> launchTermuxApp() async {
    if (!Platform.isAndroid) return false;
    try {
      final raw = await _channel.invokeMethod<String>('launchTermux');
      return raw == 'ok';
    } catch (e) {
      debugPrint('PORTE launchTermux: $e');
      return false;
    }
  }

  /// Sem o canal nativo: abre a página do Termux no F-Droid.
  Future<TerminalOutcome> _openStoreFallback() async {
    try {
      await launchUrl(Uri.parse('https://f-droid.org/packages/com.termux/'),
          mode: LaunchMode.externalApplication);
      return const TerminalOutcome(TerminalResult.serviceMissing, 'canal nativo ausente; aberta página do F-Droid');
    } catch (e) {
      debugPrint('PORTE termux fallback falhou: $e');
      return TerminalOutcome(TerminalResult.failed, '$e');
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
