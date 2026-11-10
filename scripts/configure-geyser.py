#!/usr/bin/env python3
"""Apply runtime-only Playit Geyser settings without committing credentials."""
from __future__ import annotations
import os
import sys
from pathlib import Path
from typing import Any
import yaml


def deep_merge(target: dict[str, Any], source: dict[str, Any]) -> None:
    for key, value in source.items():
        if isinstance(value, dict) and isinstance(target.get(key), dict):
            deep_merge(target[key], value)
        else:
            target[key] = value


def get_bedrock_advertise_address(config: dict[str, Any]) -> str:
    explicit = os.environ.get("PLAYIT_BEDROCK_ADDRESS", "").strip()
    if explicit:
        address = explicit
    else:
        bedrock = config.get("bedrock", {})
        signaling = bedrock.get("signaling", {}) if isinstance(bedrock, dict) else {}
        candidates: list[Any] = []
        if isinstance(signaling, dict):
            for value in signaling.values():
                if isinstance(value, dict):
                    found = value.get("advertise-addresses")
                    if isinstance(found, list):
                        candidates.extend(found)
        address = str(candidates[0]).strip() if candidates else ""
    if not address:
        return ""
    if address.startswith("["):
        if "]:" not in address:
            port = config.get("bedrock", {}).get("port", 19132)
            address = f"{address}:{port}"
    elif address.count(":") == 0:
        port = config.get("bedrock", {}).get("port", 19132)
        address = f"{address}:{port}"
    return address


def main() -> int:
    if len(sys.argv) < 2:
        print("Uso: configure-geyser.py RUTA_SERVER", file=sys.stderr)
        return 2
    server_dir = Path(sys.argv[1]).resolve()
    config_path = server_dir / "plugins" / "Geyser-Spigot" / "config.yml"
    address_path = server_dir / "GEYSER_BEDROCK_ADDRESS.txt"
    if not config_path.is_file():
        print(f"ERROR: no existe {config_path}", file=sys.stderr)
        return 1
    try:
        config = yaml.safe_load(config_path.read_text(encoding="utf-8")) or {}
        if not isinstance(config, dict):
            raise ValueError("la raíz del archivo Geyser no es un mapa YAML")
        snippet_text = os.environ.get("PLAYIT_GEYSER_CONFIG", "").strip()
        if snippet_text:
            snippet = yaml.safe_load(snippet_text)
            if not isinstance(snippet, dict):
                raise ValueError("PLAYIT_GEYSER_CONFIG debe contener un bloque YAML con secciones")
            deep_merge(config, snippet)
        bedrock = config.setdefault("bedrock", {})
        if not isinstance(bedrock, dict):
            raise ValueError("la sección bedrock de Geyser no es válida")
        bedrock.setdefault("address", "0.0.0.0")
        bedrock.setdefault("port", 19132)
        bedrock.setdefault("transport", "both")
        found = 0
        for section_name in ("remote", "java"):
            section = config.get(section_name)
            if isinstance(section, dict):
                section["auth-type"] = "floodgate"
                found += 1
        if found == 0:
            config["remote"] = {
                "address": "127.0.0.1",
                "port": 25565,
                "auth-type": "floodgate",
            }
        address = get_bedrock_advertise_address(config)
        rendered = yaml.safe_dump(
            config, sort_keys=False, allow_unicode=True,
            default_flow_style=False, width=120
        )
        temp_path = config_path.with_suffix(".yml.tmp")
        temp_path.write_text(rendered, encoding="utf-8")
        temp_path.replace(config_path)
        if address:
            address_path.write_text(address + "\n", encoding="utf-8")
        elif address_path.exists():
            address_path.unlink()
        print("Geyser configurado: autenticación Floodgate habilitada.")
        print("Configuración NetherNet privada: " + ("aplicada" if snippet_text else "pendiente"))
        print("Dirección Bedrock: " + ("detectada" if address else "pendiente"))
        return 0
    except Exception as exc:
        # Never print the secret value or the parsed YAML payload.
        print(f"ERROR al configurar Geyser: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
