import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Abre um terminal nativo apontando para [directory].
///
/// - Android: dispara Intent para o Termux (`com.termux`).
///   Requer Termux + Termux:API instalados; sem eles, abre a Play Store.
/// - Linux/macOS/Windows desktop: lança o terminal padrão com cwd.
///   Retorna `true` se o disparo foi aceito.
class TerminalService {
  static const _channel = MethodChannel('dev.porte/terminal');

  Future<bool> openTerminal(String directory) async {
    if (Platform.isAndroid) return _openAndroid(directory);
    if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
      return _openDesktop(directory);
    }
    return false;
  }

  // ---- Android: Termux ----
  Future<bool> _openAndroid(String directory) async {
    // 1) Tenta via plugin de plataforma do app (MainActivity), se registrado.
    try {
      final ok = await _channel.invokeMethod<bool>('openTerminal', {'path': directory});
      if (ok == true) return true;
    } on MissingPluginException catch (_) {
      // cai para o fluxo por Intent abaixo
    } catch (e) {
      debugPrint('PORTE terminal channel: $e');
    }
    // 2) Intent RUN_COMMAND do Termux (workingDirectory = pasta atual).
    // Obs.: RUN_COMMAND é um Service — disparar como Activity falha;
    // por isso o caminho oficial é o MethodChannel (MainActivity).
    // Aqui resta apenas o fallback para a página do Termux no F-Droid
    // (a versão da Play Store está descontinuada).
    try {
      await launchUrl(Uri.parse('https://f-droid.org/packages/com.termux/'),
          mode: LaunchMode.externalApplication);
      return false;
    } catch (e) {
      debugPrint('PORTE termux fallback falhou: $e');
      return false;
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
