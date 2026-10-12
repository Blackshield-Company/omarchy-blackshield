#!/usr/bin/env bash
# Install the forged 2560x1080 EDID on Omarchy.
# Never edits /boot/limine.conf. Never writes root=UUID.
# The driver loads this firmware before the rootfs mounts, so it has to be in the initramfs.
#
# Usage:
#   OUTPUT=DP-1 ./scripts/install-edid.sh --check
#   OUTPUT=DP-1 ./scripts/install-edid.sh
#
# OUTPUT     Connector name (default DP-2). Must be present under /sys/class/drm/.
# --check    Print connectors, the cmdline param, and whether the live EDID
#            matches the bin. Writes nothing.
# EDID_NAME  Firmware filename under theme/blackshield/edid/ (default skg-2560x1080.bin).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT="${OUTPUT:-DP-2}"
EDID_NAME="${EDID_NAME:-skg-2560x1080.bin}"
PARAM="drm.edid_firmware=${OUTPUT}:edid/${EDID_NAME}"
SRC="$ROOT/theme/blackshield/edid/$EDID_NAME"
CHECK_ONLY=0

if [[ "${1:-}" == "--check" ]]; then
  CHECK_ONLY=1
fi

die() { echo "error: $*" >&2; exit 1; }

[[ -f "$SRC" ]] || die "missing $SRC"

echo "connectors:"
ls /sys/class/drm/ | sed 's/^/  /'

if ! compgen -G "/sys/class/drm/card*-${OUTPUT}" >/dev/null; then
  die "connector ${OUTPUT} is not present. Refusing to write a cmdline for a display that is not plugged in."
fi

echo "connector ${OUTPUT} is present"
echo "param: ${PARAM}"

if [[ "$CHECK_ONLY" -eq 1 ]]; then
  python3 - << PY
import hashlib, pathlib
src = pathlib.Path("$SRC").read_bytes()
live = None
for p in pathlib.Path("/sys/class/drm").glob("card*-${OUTPUT}/edid"):
    live = p.read_bytes()
    break
print(f"bin {len(src)} bytes {hashlib.sha256(src).hexdigest()[:16]}")
if live is None:
    print("live edid unreadable")
else:
    print("live match" if live == src else "live DIFFERS from repo bin")
PY
  echo "check only — no files written"
  exit 0
fi

if [[ ! -d /usr/share/omarchy ]] && ! command -v omarchy-theme-set >/dev/null; then
  die "This script only supports Omarchy."
fi

if [[ ! -d /etc/limine-entry-tool.d ]]; then
  die "/etc/limine-entry-tool.d is missing. Omarchy keeps kernel cmdline in that drop-in dir. Refusing to rewrite /boot/limine.conf."
fi

sudo mkdir -p /usr/lib/firmware/edid
sudo cp "$SRC" "/usr/lib/firmware/edid/$EDID_NAME"
sudo chmod 644 "/usr/lib/firmware/edid/$EDID_NAME"

# Append-only drop-in. omarchy-refresh-limine overwrites /boot/limine.conf from
# the package and then runs limine-update, which re-reads this directory.
sudo tee /etc/limine-entry-tool.d/99-blackshield-edid.conf >/dev/null << EOF
# Blackshield EDID forge. Appended to the default cmdline. Do not put root=UUID here.
KERNEL_CMDLINE[default]+=" ${PARAM}"
EOF

sudo tee /etc/mkinitcpio.conf.d/blackshield-edid.conf >/dev/null << EOF
# Loaded by amdgpu before root mounts. A cmdline reference without this file in
# the initramfs fails with "Direct firmware load failed with error -2".
FILES+=(/usr/lib/firmware/edid/${EDID_NAME})
EOF

echo "rebuilding initramfs"
sudo mkinitcpio -P

if command -v limine-update >/dev/null; then
  echo "regenerating limine entries from drop-ins (not copying limine.conf)"
  sudo limine-update
fi

found=0
shopt -s nullglob
for img in /boot/initramfs-*.img /efi/EFI/Linux/*.efi /boot/EFI/Linux/*.efi; do
  [[ -f "$img" ]] || continue
  if sudo lsinitcpio "$img" 2>/dev/null | grep -q "$EDID_NAME"; then
    echo "edid present in $img"
    found=1
  fi
done
shopt -u nullglob

if [[ "$found" -ne 1 ]]; then
  die "EDID bin was not found in any initramfs or UKI. Do not reboot until this is fixed."
fi

echo "done. reboot to apply. after boot:"
echo "  edid-decode /sys/class/drm/card*-${OUTPUT}/edid | grep 2560x1080"
