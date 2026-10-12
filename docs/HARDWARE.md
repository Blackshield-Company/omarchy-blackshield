# Hardware

Connector names are not portable. The EDID script refuses to write a cmdline if the named connector is not in `/sys/class/drm/`. Select it with `OUTPUT=` (default `DP-2`).

## Mode drop after lock and DPMS

The forged EDID preferred timing is `2560x1080 @ 60`. `2560x1080 @ 120` is the fastest ultrawide mode the bin advertises. The daily pin is `2560x1080@119.87`. A fuzzy `@120` match can land on `1920x1080@120.00`, which the sink always advertises, when the forged timing is missing from the list for a beat after lock + DPMS. No connector-disconnect event fires for that DPMS cycle.

`hold-wide-mode` polls and re-asserts the wide mode if wake lands on 1080p or on `2560x1080` below 100Hz. It does not touch the other output. Install it with `./install.sh hold` and autostart it. Override the target with `OUTPUT`, `DESC`, `MODE`, `POS`, and `SCALE`.

Lock blank must not DPMS the panels. The other output can treat DPMS-off as a disconnect and come back lit while the ultrawide stays black. `shell/bin/omarchy-brightness-display` skips `off` while the session is locked.

## EDID and Limine

`omarchy-refresh-limine` moves `/boot/limine.conf` aside and copies the package default over it, then runs `limine-update`. Do not hand-edit `/boot/limine.conf` and do not full-copy a limine.conf. That is the boot-panic class of mistake.

Kernel cmdline extras belong in `/etc/limine-entry-tool.d/`. `scripts/install-edid.sh` writes `99-blackshield-edid.conf` as an append (`KERNEL_CMDLINE[default]+=`) and never writes `root=UUID`.

The firmware file also has to be inside the initramfs. amdgpu probes before root mounts. A cmdline reference without the bin in the image fails with `Direct firmware load failed with error -2`. The script adds `/etc/mkinitcpio.conf.d/blackshield-edid.conf`, runs `mkinitcpio -P`, runs `limine-update`, and refuses to finish unless `lsinitcpio` finds the bin.

After a kernel bump, re-run `./install.sh edid`. If the named connector is gone, the script stops and prints the connectors it can see.

## Cursor

Set `no_hardware_cursors` in the Hyprland cursor config. Without it the cursor is a black box. `hold-wide-mode` reasserts `no_hardware_cursors` and a CPU cursor buffer on `OUTPUT` after a modeset, because the modeset rebuilds the cursor plane. Append that block to the user looknfeel file. Do not replace the package defaults.
