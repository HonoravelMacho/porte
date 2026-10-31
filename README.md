# PORTE — Plataforma de Organização de Rede, Terminal e Exploração

> PORTE — gerenciador de arquivos Sci-Fi/Skeuomorphic em Flutter: exploração local, terminal integrado (Termux/Linux), cofre com criptografia e HUD neon ciano/âmbar. Open-source, multiplataforma (Android/Linux).

Gerenciador de arquivos multiplataforma (Android + Linux), responsivo e open-source, com HUD futurista, terminal nativo e cofre criptografado.

## Estrutura

- `app/` — projeto Flutter (código oficial do PORTE)
  - `lib/core/` — tema Sci-Fi (`porte_colors`, `porte_theme`, `chamfered`) + widgets HUD
  - `lib/features/explorer/` — listagem/navegação/operações de arquivo, cache de ícones, PathBar, carrossel de armazenamento, grade de categorias
  - `lib/features/terminal/` — "Abrir Terminal" (Termux no Android, terminal padrão no Linux)
  - `lib/features/crypto/` — cofre AES + motor M.A.R.T.E.L.O.S. (cripto/descripto de qualquer arquivo com N senhas)
- `.github/workflows/release.yml` — gera `.apk` + `.deb` a cada tag `v*`
- `packaging/deb/build-deb.sh` — empacota o bundle Linux em `.deb` (inclui o motor martelos embutido em `/usr/lib/porte`)
- `packaging/binaries/x86_64/martelos` — motor estático x86_64 para o .deb
- `app/android/app/src/main/jniLibs/{arm64-v8a,armeabi-v7a,x86_64}/libmartelos.so` — motor embutido no `.apk` (uma cópia por ABI)
- `app_descompilado/` + `filemanager.apk` — **referência local, fora do Git** (app original que inspirou o MVP)

## Rodar local

```bash
cd app
flutter pub get
flutter analyze
flutter test
flutter run          # Android/Linux
```

## Releases de teste (calma, passo a passo)

Versão atual: **0.3.4** — novidades:

- 0.3.0 trouxe pastas protegidas por senha: cadeado nas pastas protegidas,
  pedido de senha ao entrar (inclusive subpastas via PathBar/busca), "Criar
  pasta protegida" no botão + e "Proteger com senha" no menu de contexto.

- **M.A.R.T.E.L.O.S. de imagem/áudio/vídeo dentro do app** (bug de navegação nas
  categorias corrigido: IMAGENS agora abre diretamente a câmera/Pictures e
  AUDIO/VÍDEO/DOCUMENTOS/PACOTES acham suas pastas no Android).
- Ao criptografar, o dialog M.A.R.T.E.L.O.S. já sugere o alvo pela extensão
  (foto → imagem, música → audio, vídeo → video); artefatos de chiado (.bmp/
  .wav/.avi) sugerem o mesmo alvo na descriptografia.
- Diagnóstico de falhas do motor exibido direto no aviso do app.
- Motor M.A.R.T.E.L.O.S. **v6.3.7** embutido em todas as ABIs (arm64 e x86_64
  já com ffmpeg/ffprobe; armeabi-v7a segue sem ffmpeg — o modo genérico de
  arquivo funciona normal).

```bash
git tag v0.2.1
git push origin v0.2.1   # dispara o Actions: APK + DEB na página Releases
```

Baixe os artefatos em **GitHub → Releases** (ou em Actions → artifacts, se ainda estiver rodando).
No Android, instale o APK e confira: navegação por pastas, PathBar, categorias, menu "Abrir Terminal" (pede Termux instalado).

## Assinatura do APK (opcional)

Sem secrets, o CI assina com chaves de debug — suficiente para teste.
Para release final, cadastre em Settings → Secrets → Actions:

- `ANDROID_KEYSTORE_B64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

## Licença

A definir (sugestão: MIT ou GPL-3.0 por ser open-source).
