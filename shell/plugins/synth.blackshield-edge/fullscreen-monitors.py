#!/usr/bin/env python3
"""Print Hyprland monitor names that currently have a fullscreen window."""
import json
import subprocess


def hypr(cmd):
    return json.loads(subprocess.check_output(["hyprctl", *cmd, "-j"]))


mons = {m["id"]: m["name"] for m in hypr(["monitors"])}
covered = set()
for client in hypr(["clients"]):
    if not client.get("fullscreen"):
        continue
    name = mons.get(client.get("monitor"))
    if name:
        covered.add(name)
print("\n".join(sorted(covered)))
