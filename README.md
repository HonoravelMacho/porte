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

Versão atual: **0.2.4** — martelos 100% funcional no `.apk`: motor **+ ffmpeg/ffprobe estáticos** embutidos
(arm64), selo de "concluído" só com arquivo de saída real, escolha do nome de saída e modos de mídia
(arquivo/imagem/áudio/vídeo — arquivos de chiado `*.bmp/*.wav/*.avi`). Fonte do motor: `martelos_projeto`
v6.3.4 (`-m` não exige mais ffmpeg; descoberta de `libffmpeg.so` ao lado do binário).

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
