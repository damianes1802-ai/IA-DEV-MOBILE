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

mkdir -p "$ADEV_DATA"
LOG="$ADEV_DATA/setup.log"
: >"$LOG"

say "actualizando paquetes (registro completo en $LOG)"
# Repara instalaciones interrumpidas (p. ej. si se cortó un intento anterior).
dpkg --configure -a >>"$LOG" 2>&1
# Usamos pkg (no apt-get directo): pkg elige el mirror y refresca las listas.
if ! { pkg update && { yes || true; } | pkg upgrade -y; } >>"$LOG" 2>&1; then
  warn "la actualización falló. Últimas líneas del registro:"
  tail -n 5 "$LOG" | sed 's/^/     /'
  warn "si es un problema de mirror, ejecuta 'termux-change-repo', elige otro y relanza setup.sh"
fi

# Uno a uno: si alguno no existe en tu mirror, el resto se instala igual.
# openjdk-17 pesa ~200 MB: puede tardar varios minutos sin mostrar nada.
PKGS=(git openjdk-17 aapt aapt2 apksigner d8 zipalign zip unzip wget android-tools termux-tools micro)
missing=()
for p in "${PKGS[@]}"; do
  printf '   · %-14s' "$p"
  if dpkg -s "$p" >/dev/null 2>&1; then echo "ya instalado"; continue; fi
  [[ "$p" == openjdk-17 ]] && printf '(descargando, paciencia) '
  if pkg install -y "$p" >>"$LOG" 2>&1; then
    echo "ok"
  else
    echo "falló"; missing+=("$p")
    grep -E '^(E:|W:|dpkg:)' "$LOG" | tail -n 2 | sed 's/^/        /'
  fi
done
(( ${#missing[@]} )) && warn "no se instalaron: ${missing[*]} (detalles en $LOG)"

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
