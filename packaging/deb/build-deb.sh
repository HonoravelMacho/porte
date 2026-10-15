#!/usr/bin/env bash
# Empacota build/linux/*/release/bundle em um .deb instalável.
# Uso: ./packaging/deb/build-deb.sh v0.1.0
set -euo pipefail
TAG="${1:-v0.1.0}"
VER="${TAG#v}"
APP_DIR="app"
BUNDLE="$(ls -d "$APP_DIR"/build/linux/*/release/bundle | head -n1)"
PKG="porte_${VER}_amd64"

rm -rf "/tmp/$PKG" dist
mkdir -p "/tmp/$PKG/DEBIAN" "/tmp/$PKG/usr/lib/porte" "/tmp/$PKG/usr/bin" \
         "/tmp/$PKG/usr/share/applications" "/tmp/$PKG/usr/share/icons/hicolor/256x256/apps" dist

cp -r "$BUNDLE"/* "/tmp/$PKG/usr/lib/porte/"
cat > "/tmp/$PKG/usr/bin/porte" <<'EOF'
#!/bin/sh
exec /usr/lib/porte/porte "$@"
EOF
chmod +x "/tmp/$PKG/usr/bin/porte"

cat > "/tmp/$PKG/DEBIAN/control" <<EOF
Package: porte
Version: $VER
Section: utils
Priority: optional
Architecture: amd64
Depends: libgtk-3-0, libblkid1, liblzma5
Maintainer: PORTE Contributors <https://github.com/HonoravelMacho/porte>
Description: PORTE - gerenciador de arquivos Sci-Fi em Flutter
 Plataforma de Organizacao de Rede, Terminal e Exploracao.
 Com terminal integrado e cofre criptografado.
EOF

cat > "/tmp/$PKG/usr/share/applications/porte.desktop" <<'EOF'
[Desktop Entry]
Name=PORTE
Comment=Gerenciador de arquivos Sci-Fi com terminal integrado
Exec=/usr/bin/porte
Icon=porte
Terminal=false
Type=Application
Categories=Utility;FileManager;
EOF

# ícone: usa o launcher android como placeholder se não houver arte linux
ICON_SRC="$APP_DIR/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png"
if [ -f "$ICON_SRC" ]; then
  cp "$ICON_SRC" "/tmp/$PKG/usr/share/icons/hicolor/256x256/apps/porte.png"
fi

dpkg-deb --build "/tmp/$PKG" "dist/${PKG}.deb"
echo "OK: dist/${PKG}.deb"
