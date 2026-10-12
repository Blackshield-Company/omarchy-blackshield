#!/usr/bin/env bash
# Static checks. Does not install anything.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
fail=0
bad() { echo "FAIL: $*"; fail=1; }
ok() { echo "ok: $*"; }

python3 - << PY || bad "colors.toml"
import tomllib
from pathlib import Path
p = Path("$ROOT/theme/blackshield/colors.toml")
data = tomllib.loads(p.read_text())
required = [
    "mode", "accent", "selection", "muted",
    "background", "dark_background", "darker_background", "lighter_background",
    "foreground", "dark_foreground", "light_foreground", "bright_foreground",
    "red", "yellow", "orange", "green", "cyan", "blue", "magenta", "brown",
    "bright_red", "bright_yellow", "bright_green", "bright_cyan", "bright_blue", "bright_magenta",
]
missing = [k for k in required if k not in data]
if missing:
    raise SystemExit("missing keys: " + ", ".join(missing))
if data["mode"] != "dark":
    raise SystemExit("mode must be dark")
for k, v in data.items():
    if k == "mode":
        continue
    if not isinstance(v, str) or not (v.startswith("#") or v.startswith("rgba(")):
        raise SystemExit(f"{k} is not a color: {v}")
print("colors.toml keys", len(required))
PY
ok "colors.toml"

python3 - << PY || bad "shell.lock.toml"
import tomllib
from pathlib import Path
data = tomllib.loads(Path("$ROOT/theme/blackshield/shell.lock.toml").read_text())
for k in ("text", "placeholder", "border", "background", "border-active"):
    if k not in data:
        raise SystemExit("missing " + k)
print("shell.lock.toml ok")
PY
ok "shell.lock.toml"

theme="$ROOT/theme/blackshield"
for banned in hyprland.lua alacritty.toml foot.ini ghostty.conf kitty.conf vscode.json; do
  [[ -e "$theme/$banned" ]] && bad "theme ships $banned (stripped or executed on theme install)"
done
if find "$theme" -name '*.lua' | grep -q .; then
  bad "theme contains lua"
fi
ok "theme has no executable configs"

icons="$(tr -d '[:space:]' < "$theme/icons.theme")"
case " $icons " in
  *" Yaru-red "*) ok "icons.theme Yaru-red" ;;
  *) bad "icons.theme must be a shipped Yaru name, got [$icons]" ;;
esac

for f in 01-camp.png 02-horse.png 03-contract.png 04-fight.png; do
  [[ -s "$theme/backgrounds/$f" ]] || bad "missing background $f"
done
ok "backgrounds"

[[ "$(wc -c < "$theme/edid/skg-2560x1080.bin")" -eq 256 ]] || bad "edid bin is not 256 bytes"
if [[ -f /usr/lib/firmware/edid/skg-2560x1080.bin ]]; then
  cmp -s "$theme/edid/skg-2560x1080.bin" /usr/lib/firmware/edid/skg-2560x1080.bin \
    || bad "repo edid does not match the live firmware bin"
  ok "edid matches live firmware"
fi

[[ -s "$ROOT/theme/blackshield/shell.toml" ]] || bad "missing shell.toml"
grep -q 'scale-with-font' "$ROOT/theme/blackshield/shell.toml" || bad "shell.toml missing scale-with-font"
ok "shell.toml"

[[ -s "$ROOT/shell/shell.json" ]] || bad "missing shell/shell.json"
python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "$ROOT/shell/shell.json" || bad "shell.json"
ok "shell.json"

[[ ! -e "$ROOT/fonts/KelmscottMono.otf" ]] || bad "Kelmscott Mono must not be committed (no redistribution license)"
[[ -s "$ROOT/fonts/KELMSCOTT-NOTICE.txt" ]] || bad "missing Kelmscott notice"
ok "fonts"

[[ -s "$ROOT/cursors/Blackshield/index.theme" ]] || bad "missing cursor theme"
ok "cursor"

if command -v luac >/dev/null; then
  while IFS= read -r -d '' f; do
    luac -p "$f"
  done < <(find "$ROOT" -name '*.lua' -print0)
  ok "lua syntax"
else
  echo "notice: luac not found, skipping lua syntax check"
fi

bash -n "$ROOT/install.sh"
bash -n "$ROOT/scripts/install-edid.sh"
bash -n "$ROOT/scripts/hold-wide-mode"
bash -n "$ROOT/validate.sh"
ok "shell syntax"

python3 - << PY || bad "secret scan"
import re
from pathlib import Path
root = Path("$ROOT")
pat = re.compile(r"root=UUID=[0-9a-fA-F-]|gho_[A-Za-z0-9]|ghp_[A-Za-z0-9]|sk-[A-Za-z0-9]{8,}")
hits = []
for p in root.rglob("*"):
    if not p.is_file() or ".git" in p.parts or p.name == "validate.sh":
        continue
    try:
        text = p.read_text()
    except (UnicodeDecodeError, OSError):
        continue
    for i, line in enumerate(text.splitlines(), 1):
        if pat.search(line):
            hits.append(f"{p}:{i}")
if hits:
    print("\n".join(hits))
    raise SystemExit(1)
print("no live secrets")
PY
ok "secret scan"

if grep -nE '^[^#]*\bcp\b.*limine\.conf' "$ROOT/scripts/install-edid.sh" >/dev/null; then
  bad "edid script copies limine.conf"
else
  ok "edid script does not copy limine.conf"
fi

[[ "$fail" -eq 0 ]] || exit 1
echo "validate: clean"
