import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:porte/features/crypto/martelos_service.dart';

/// Teste de integração com o motor M.A.R.T.E.L.O.S. real (CLI `-m`).
/// Requer o binário `martelos` no PATH; se ausente, o grupo é pulado
/// (CI não tem o motor instalado).
void main() {
  final rn = Process.runSync('which', ['martelos']);
  final temMotor = rn.exitCode == 0 && rn.stdout.toString().trim().isNotEmpty;

  group('MartelosService (motor real)', () {
    late Directory tmp;
    late File entrada;

    setUp(() {
      tmp = Directory.systemTemp.createTempSync('porte_martelos_test');
      entrada = File('${tmp.path}/segredo.txt');
      entrada.writeAsStringSync('PORTE 0.2.1 :: cone martelos :: ${DateTime.now()}');
    });

    tearDown(() {
      tmp.deleteSync(recursive: true);
    });

    test('cripto + descripto com N senhas (ordem importa)', () async {
      if (!temMotor) return;
      const senhas = <String>['alpha-01', 'beta-02', 'gama-03'];

      final cripto = await MartelosService.process(
        inputPath: entrada.path,
        encrypt: true,
        passphrases: senhas,
        constante: 'pi',
      );
      final original = entrada.readAsStringSync();
      expect(cripto.ok, isTrue, reason: cripto.details ?? cripto.message);
      final criptografado = File(cripto.outputPath ?? '');
      expect(criptografado.existsSync(), isTrue);
      expect(criptografado.path.endsWith('.martelos'), isTrue);
      expect(criptografado.lengthSync(), greaterThan(0));

      // Descripto com as mesmas senhas -> recupera o arquivo original.
      final descripto = await MartelosService.process(
        inputPath: criptografado.path,
        encrypt: false,
        passphrases: senhas,
        constante: 'pi',
      );
      expect(descripto.ok, isTrue, reason: descripto.details ?? descripto.message);
      final resturado = File(descripto.outputPath ?? '');
      expect(resturado.existsSync(), isTrue);
      expect(resturado.readAsStringSync(), original);

      // Ordem trocada NÃO recupera o conteúdo original (corrompe ou falha).
      final errado = await MartelosService.process(
        inputPath: criptografado.path,
        encrypt: false,
        passphrases: senhas.reversed.toList(),
        constante: 'pi',
      );
      final arquivoErrado = File(errado.outputPath ?? '');
      if (errado.ok && arquivoErrado.existsSync()) {
        String felizOuCorrompido;
        try {
          felizOuCorrompido = arquivoErrado.readAsStringSync();
        } on FileSystemException {
          felizOuCorrompido = '\u{FFFD}corrompido'; // binário inválido vindo da descripto errada
        }
        expect(felizOuCorrompido != original, isTrue,
            reason: 'senhas fora de ordem não deveriam decifrar igual');
        arquivoErrado.deleteSync();
      }
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('1 senha (single layer) roundtrip', () async {
      if (!temMotor) return;
      final c = await MartelosService.process(
        inputPath: entrada.path,
        encrypt: true,
        passphrases: ['s#enha com espaços'],
        constante: 'catalan',
      );
      expect(c.ok, isTrue, reason: c.details ?? c.message);
      final d = await MartelosService.process(
        inputPath: c.outputPath!,
        encrypt: false,
        passphrases: ['s#enha com espaços'],
        constante: 'catalan',
      );
      expect(d.ok, isTrue, reason: d.details ?? d.message);
      expect(File(d.outputPath ?? '').readAsStringSync(), entrada.readAsStringSync());
    }, timeout: const Timeout(Duration(minutes: 2)));
  }, skip: temMotor ? false : 'motor martelos não instalado');
}
