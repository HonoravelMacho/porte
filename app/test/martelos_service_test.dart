import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:porte/features/crypto/martelos_service.dart';

/// Teste de integração com o motor M.A.R.T.E.L.O.S. real (CLI `-m`).
/// Usa o binário empacotado no próprio repositório
/// (`packaging/binaries/x86_64/martelos`) para garantir versão/patch do motor;
/// se ausente, o grupo é pulado (CI não tem o binário... olá!).
void main() {
  final repo = File.fromUri(Uri.parse('file://${Directory.current.path}/../packaging/binaries/x86_64/martelos'));
  final repoBin = Directory.current.path.endsWith('/app')
      ? File('${Directory.current.parent.path}/packaging/binaries/x86_64/martelos')
      : repo;
  final motor = repoBin.existsSync() ? repoBin : null;
  if (motor != null) MartelosService.debugBinaryPath = motor.path;
  final ciSemMotor = motor == null;

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
      if (ciSemMotor) return;
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
      if (ciSemMotor) return;
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

    test('genérico -m funciona SEM ffmpeg no PATH (causa do falso sucesso)', () async {
      if (ciSemMotor) return;
      final orig = entrada.readAsStringSync();
      // PATH restrito: o motor não enxerga ffmpeg/ffprobe e nem consegue
      // resolvê-los como lib*.so — modo genérico não deve depender deles.
      final env = {'PATH': '/tmp/opencode/mockbin'};
      final c = await MartelosService.process(
        inputPath: entrada.path,
        encrypt: true,
        passphrases: ['p1', 'p2'],
        constante: 'pi',
        environment: env,
      );
      expect(c.ok, isTrue, reason: 'detalhes: ${c.details}');
      expect(File(c.outputPath ?? '').existsSync(), isTrue);
      final d = await MartelosService.process(
        inputPath: c.outputPath!,
        encrypt: false,
        passphrases: ['p1', 'p2'],
        constante: 'pi',
        environment: env,
      );
      expect(d.ok, isTrue, reason: 'detalhes: ${d.details}');
      expect(File(d.outputPath ?? '').readAsStringSync(), orig);
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('modo imagem sem ffmpeg FALHA (não pode indicar sucesso sem arquivo)', () async {
      if (ciSemMotor) return;
      // BMP "de mentira": extensão válida passa no formato, mas o motor
      // sem ffmpeg (nem empacotado) deve bloquear com [❌] e NÃO criar saída.
      final bmp = File('${tmp.path}/fotinha.bmp');
      bmp.writeAsBytesSync([..._bmpFalso(), ...List.filled(200, 42)]);
      final c = await MartelosService.process(
        inputPath: bmp.path,
        encrypt: true,
        passphrases: ['x'],
        constante: 'clausen',
        alvo: MartelosAlvo.imagem,
        environment: {'PATH': '/tmp/opencode/mockbin'},
      );
      expect(c.ok, isFalse, reason: 'sem ffmpeg o modo imagem não pode concluir (main acao1)');
      final saida = File(c.outputPath ?? '');
      expect(saida.existsSync(), isFalse, reason: 'nenhum arquivo pode ser criado');
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('nome de saída personalizado é honrado (-o)', () async {
      if (ciSemMotor) return;
      final orig = entrada.readAsStringSync();
      final c = await MartelosService.process(
        inputPath: entrada.path,
        encrypt: true,
        passphrases: ['p1'],
        constante: 'pi',
        outputName: 'meu_segredo_cofre',
      );
      expect(c.ok, isTrue, reason: 'detalhes: ${c.details}');
      final esperado = File('${tmp.path}/meu_segredo_cofre');
      expect(esperado.existsSync(), isTrue, reason: c.details ?? c.message);
      final d = await MartelosService.process(
        inputPath: esperado.path,
        encrypt: false,
        passphrases: ['p1'],
        constante: 'pi',
      );
      expect(d.ok, isTrue, reason: 'detalhes: ${d.details}');
      expect(File(d.outputPath ?? '').readAsStringSync(), orig);
    }, timeout: const Timeout(Duration(minutes: 2)));
  }, skip: ciSemMotor ? 'binário empacotado do motor ausente' : false);
}

/// Cabeçalho BMP 1x1 mínimo para os testes.
List<int> _bmpFalso() => [
      0x42, 0x4D, 0x3A, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1A, 0x00, 0x00, 0x00,
      0x0C, 0x00, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x01, 0x00, 0x18, 0x00, 0xFF, 0xFF,
      0xFF, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0x00, 0x00,
    ];
// --------------------- EXTRAS v0.2.4 ---------------------
