#!/data/data/com.termux/files/usr/bin/bash
# Instala el entorno de desarrollo Android en Termux (todo local, sin nube).
# Uso:  bash setup.sh
set -uo pipefail

REPO="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
ADEV_DATA="$HOME/.adev"
PLATFORM_ZIP_URL="https://dl.google.com/android/repository/platform-33_r02.zip"

say()  { printf '\e[32m==>\e[0m %s\n' "$*"; }
warn() { printf '\e[33m!!\e[0m %s\n' "$*"; }

[[ -n "${PREFIX:-}" && -d "$PREFIX" ]] || { echo "Este script es para Termux (Android)."; exit 1; }

say "actualizando paquetes"
yes | pkg update >/dev/null 2>&1 || warn "pkg update falló; sigo igualmente"

# Uno a uno: si alguno no existe en tu mirror, el resto se instala igual.
PKGS=(git openjdk-17 aapt aapt2 apksigner d8 zipalign zip unzip wget android-tools termux-tools micro)
for p in "${PKGS[@]}"; do
  printf '   · %-14s' "$p"
  if pkg install -y "$p" >/dev/null 2>&1; then echo "ok"; else echo "no disponible"; fi
done

mkdir -p "$ADEV_DATA"

# android.jar: lo trae el paquete aapt; si no, se descarga la plataforma oficial.
have_jar=0
for j in "$ADEV_DATA/android.jar" "$PREFIX/share/aapt/android.jar" "$PREFIX/share/java/android.jar"; do
  [[ -f "$j" ]] && have_jar=1
done
if (( ! have_jar )); then
  say "descargando android.jar (API 33)"
  tmp="$(mktemp -d)"
  if wget -q -O "$tmp/p.zip" "$PLATFORM_ZIP_URL" && unzip -q -j "$tmp/p.zip" '*/android.jar' -d "$ADEV_DATA"; then
    say "android.jar en $ADEV_DATA/android.jar"
  else
    warn "no pude descargar android.jar; cópialo a $ADEV_DATA/android.jar"
  fi
  rm -rf "$tmp"
fi

say "instalando el comando adev"
ln -sf "$REPO/bin/adev" "$PREFIX/bin/adev"
chmod +x "$REPO/bin/adev"

echo
bash "$REPO/bin/adev" doctor && cat <<'EOF'

Prueba rápida:
  mkdir -p ~/proyectos && cd ~/proyectos
  adev new Hola
  cd Hola && adev build && adev install
EOF
