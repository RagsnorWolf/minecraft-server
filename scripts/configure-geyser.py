#!/usr/bin/env python3
"""Set Geyser's Java authentication to Floodgate without rewriting other settings."""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
CONFIG = ROOT / "server" / "plugins" / "Geyser-Spigot" / "config.yml"

if not CONFIG.is_file():
    print(f"Geyser config not generated yet: {CONFIG}")
    sys.exit(0)

text = CONFIG.read_text(encoding="utf-8")
lines = text.splitlines(keepends=True)

section_name = None
section_start = None
section_end = len(lines)
for i, line in enumerate(lines):
    if line and not line[0].isspace():
        key = line.split(":", 1)[0].strip()
        if key in ("remote", "java"):
            section_name = key
            section_start = i
            for j in range(i + 1, len(lines)):
                if lines[j].strip() and not lines[j][0].isspace() and re.match(r"^[A-Za-z0-9_-]+:", lines[j]):
                    section_end = j
                    break
            break

if section_start is None:
    print("Could not find Geyser's remote:/java: section; leaving config unchanged.")
    sys.exit(1)

changed = False
auth_found = False
for i in range(section_start + 1, section_end):
    if re.match(r"^\s*auth-type\s*:", lines[i]):
        auth_found = True
        replacement = re.sub(r"^(\s*auth-type\s*:\s*).*$", r"\1floodgate", lines[i].rstrip("\n"))
        if lines[i].rstrip("\n") != replacement:
            lines[i] = replacement + "\n"
            changed = True
        break

if not auth_found:
    lines.insert(section_start + 1, "  auth-type: floodgate\n")
    changed = True

if changed:
    CONFIG.write_text("".join(lines), encoding="utf-8")
    print(f"Updated {section_name}.auth-type=floodgate; restart required.")
    sys.exit(3)

print(f"{section_name}.auth-type is already floodgate.")
sys.exit(0)
