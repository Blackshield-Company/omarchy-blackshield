#!/usr/bin/env bash
# Blackshield installer. Omarchy only.
# Usage: ./install.sh [phase]
#   desktop (default)  theme + shell + cursor + fonts
#   theme shell cursor fonts hold edid
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
PHASE="${1:-desktop}"
if [[ $# -gt 0 ]]; then
  shift
fi

die() { echo "error: $*" >&2; exit 1; }

require_omarchy() {
  if [[ ! -d /usr/share/omarchy ]] && ! command -v omarchy-theme-set >/dev/null; then
    die "This script only supports Omarchy."
  fi
}

install_theme() {
  local dest="$HOME/.config/omarchy/themes/blackshield"
  mkdir -p "$dest"
  cp -a "$ROOT/theme/blackshield/." "$dest/"
  echo "theme -> $dest"
  if command -v omarchy-theme-set >/dev/null; then
    omarchy-theme-set blackshield
  fi
}

install_shell() {
  local base="$HOME/.config/omarchy"
  mkdir -p "$base/bin" "$base/plugins" "$base/bar" "$base/branding"
  cp -a "$ROOT/shell/bin/." "$base/bin/"
  cp -a "$ROOT/shell/plugins/." "$base/plugins/"
  cp -a "$ROOT/shell/bar/." "$base/bar/"
  cp -a "$ROOT/shell/branding/." "$base/branding/"
  cp -a "$ROOT/shell/shell.json" "$base/shell.json"
  echo "shell -> $base"
}

install_cursor() {
  local dest="$HOME/.local/share/icons/Blackshield"
  mkdir -p "$dest"
  cp -a "$ROOT/cursors/Blackshield/." "$dest/"
  echo "cursor -> $dest"
}

install_fonts() {
  cat "$ROOT/fonts/KELMSCOTT-NOTICE.txt"
  echo
  echo "Install Kelmscott Mono from its source. This kit does not ship the font."
}

install_hold() {
  local dest="$HOME/.config/hypr/scripts"
  mkdir -p "$dest"
  cp -a "$ROOT/scripts/hold-wide-mode" "$dest/hold-wide-mode"
  chmod +x "$dest/hold-wide-mode"
  echo "installed $dest/hold-wide-mode"
  echo "autostart hint: exec-once = $HOME/.config/hypr/scripts/hold-wide-mode"
}

require_omarchy

case "$PHASE" in
  desktop)
    [[ $# -eq 0 ]] || die "unexpected arguments: $*"
    install_theme
    install_shell
    install_cursor
    install_fonts
    ;;
  theme)
    [[ $# -eq 0 ]] || die "unexpected arguments: $*"
    install_theme
    ;;
  shell)
    [[ $# -eq 0 ]] || die "unexpected arguments: $*"
    install_shell
    ;;
  cursor)
    [[ $# -eq 0 ]] || die "unexpected arguments: $*"
    install_cursor
    ;;
  fonts)
    [[ $# -eq 0 ]] || die "unexpected arguments: $*"
    install_fonts
    ;;
  hold)
    [[ $# -eq 0 ]] || die "unexpected arguments: $*"
    install_hold
    ;;
  edid)
    exec "$ROOT/scripts/install-edid.sh" "$@"
    ;;
  *)
    die "unknown phase: $PHASE (desktop, theme, shell, cursor, fonts, hold, edid)"
    ;;
esac
