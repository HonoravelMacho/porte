import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../core/theme/porte_colors.dart';
import 'lock_service.dart';

const _mono = TextStyle(fontFamily: 'monospace');

/// Portão de senha: pede a senha da pasta protegida antes de navegar.
/// Devolve true quando a senha está correta.
Future<bool> showUnlockGate(BuildContext context, String lockedPath) async {
  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (d) {
      final c = TextEditingController();
      String? err;
      return StatefulBuilder(
        builder: (dCtx, setDState) => AlertDialog(
          backgroundColor: PorteColors.hull,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          title: const Row(
            children: [
              Icon(Icons.lock_rounded, color: PorteColors.amberNeon, size: 20),
              SizedBox(width: 8),
              Text('PASTA PROTEGIDA', style: TextStyle(color: PorteColors.cyanNeon, fontFamily: 'monospace', fontSize: 15, letterSpacing: 2)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                p.basename(LockService.trimTrailingSep(lockedPath)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _mono.copyWith(color: PorteColors.textDim, fontSize: 11),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: c,
                autofocus: true,
                obscureText: true,
                style: _mono.copyWith(color: PorteColors.textMain, fontSize: 13),
                onChanged: (_) => setDState(() => err = null),
                onSubmitted: (_) {
                  if (LockService.instance.verify(lockedPath, c.text)) {
                    Navigator.pop(dCtx, true);
                  } else {
                    setDState(() => err = 'SENHA REJEITADA');
                  }
                },
                decoration: const InputDecoration(
                  hintText: 'senha...',
                  prefixIcon: Icon(Icons.password_rounded, size: 18, color: PorteColors.cyanNeon),
                ),
              ),
              if (err != null) ...[
                const SizedBox(height: 8),
                Text(err!, style: _mono.copyWith(color: PorteColors.danger, fontSize: 11)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dCtx, false),
              child: const Text('CANCELAR', style: TextStyle(color: PorteColors.textDim, fontSize: 12)),
            ),
            TextButton(
              onPressed: () {
                if (LockService.instance.verify(lockedPath, c.text)) {
                  Navigator.pop(dCtx, true);
                } else {
                  setDState(() => err = 'SENHA REJEITADA');
                }
              },
              child: const Text('DESBLOQUEAR', style: TextStyle(color: PorteColors.cyanNeon, fontFamily: 'monospace', fontSize: 12)),
            ),
          ],
        ),
      );
    },
  );
  return ok ?? false;
}

/// Cadastro de senha (o serviço grava em arquivo privado).
/// Devolve null se cancelado ou senhas diferentes.
Future<String?> showProtectPasswordDialog(BuildContext context) => showDialog<String>(
      context: context,
      builder: (d) => const _ProtectDialog(),
    );

/// Cria pasta protegida: devolve (nome, senha) ou null.
Future<(String, String)?> showNewProtectedFolderDialog(BuildContext context) =>
    showDialog<(String, String)>(
      context: context,
      builder: (d) => const _NewProtectedFolderDialog(),
    );

class _ProtectDialog extends StatefulWidget {
  const _ProtectDialog();

  @override
  State<_ProtectDialog> createState() => _ProtectDialogState();
}

class _ProtectDialogState extends State<_ProtectDialog> {
  final _a = TextEditingController();
  final _b = TextEditingController();
  String? _err;

  void _try() {
    setState(() {
      if (_a.text.isEmpty) {
        _err = 'SENHA VAZIA';
      } else if (_a.text != _b.text) {
        _err = 'AS SENHAS NÃO COINCIDEM';
      } else {
        _err = null;
      }
    });
    if (_err == null) Navigator.pop(context, _a.text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: PorteColors.hull,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      title: const Row(
        children: [
          Icon(Icons.shield_moon_rounded, color: PorteColors.cyanNeon, size: 20),
          SizedBox(width: 8),
          Text('PROTEGER PASTA', style: TextStyle(color: PorteColors.cyanNeon, fontFamily: 'monospace', fontSize: 15, letterSpacing: 2)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _field(_a, 'nova senha...'),
          const SizedBox(height: 10),
          _field(_b, 'confirmar senha...'),
          if (_err != null) ...[
            const SizedBox(height: 8),
            Text(_err!, style: _mono.copyWith(color: PorteColors.danger, fontSize: 11)),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR', style: TextStyle(color: PorteColors.textDim, fontSize: 12))),
        TextButton(onPressed: _try, child: const Text('PROTEGER', style: TextStyle(color: PorteColors.cyanNeon, fontFamily: 'monospace', fontSize: 12))),
      ],
    );
  }

  TextField _field(TextEditingController c, String hint) => TextField(
        controller: c,
        autofocus: true,
        obscureText: true,
        style: _mono.copyWith(color: PorteColors.textMain, fontSize: 13),
        onChanged: (_) => setState(() => _err = null),
        onSubmitted: (_) => _try(),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.password_rounded, size: 18, color: PorteColors.cyanNeon),
        ),
      );
}

class _NewProtectedFolderDialog extends StatefulWidget {
  const _NewProtectedFolderDialog();

  @override
  State<_NewProtectedFolderDialog> createState() => _NewProtectedFolderDialogState();
}

class _NewProtectedFolderDialogState extends State<_NewProtectedFolderDialog> {
  final _name = TextEditingController();
  final _a = TextEditingController();
  final _b = TextEditingController();
  String? _err;

  void _try() {
    final n = _name.text.trim();
    setState(() {
      if (n.isEmpty) {
        _err = 'NOME DA PASTA VAZIO';
      } else if (_a.text.isEmpty) {
        _err = 'SENHA VAZIA';
      } else if (_a.text != _b.text) {
        _err = 'AS SENHAS NÃO COINCIDEM';
      } else {
        _err = null;
      }
    });
    if (_err == null) Navigator.pop(context, (n, _a.text));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: PorteColors.hull,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      title: const Row(
        children: [
          Icon(Icons.lock_rounded, color: PorteColors.amberNeon, size: 20),
          SizedBox(width: 8),
          Text('NOVA PASTA PROTEGIDA', style: TextStyle(color: PorteColors.cyanNeon, fontFamily: 'monospace', fontSize: 15, letterSpacing: 1.5)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            style: _mono.copyWith(color: PorteColors.textMain, fontSize: 13),
            onChanged: (_) => setState(() => _err = null),
            decoration: const InputDecoration(hintText: 'nome da pasta...'),
          ),
          const SizedBox(height: 10),
          _pass(_a, 'nova senha...'),
          const SizedBox(height: 10),
          _pass(_b, 'confirmar senha...'),
          if (_err != null) ...[
            const SizedBox(height: 8),
            Text(_err!, style: _mono.copyWith(color: PorteColors.danger, fontSize: 11)),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR', style: TextStyle(color: PorteColors.textDim, fontSize: 12))),
        TextButton(onPressed: _try, child: const Text('CRIAR', style: TextStyle(color: PorteColors.cyanNeon, fontFamily: 'monospace', fontSize: 12))),
      ],
    );
  }

  TextField _pass(TextEditingController c, String hint) => TextField(
        controller: c,
        obscureText: true,
        style: _mono.copyWith(color: PorteColors.textMain, fontSize: 13),
        onChanged: (_) => setState(() => _err = null),
        onSubmitted: (_) => _try(),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.password_rounded, size: 18, color: PorteColors.cyanNeon),
        ),
      );
}
