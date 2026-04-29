"""Loader for permission_map.yaml — uses stdlib only, no PyYAML dependency."""
from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path


@dataclass
class PermissionSignal:
    permission: str
    service_name: str
    method_names: list[str]
    log_type: str
    notes: str


def _parse_minimal_yaml(text: str) -> dict[str, dict[str, object]]:
    """Tiny YAML subset parser sufficient for permission_map.yaml.

    Supports: top-level keys, 2-space-indented scalar key/value, list-of-strings,
    block scalar (``|``). Comments and blank lines are skipped. Emits a clear
    error if it encounters anything unexpected so the file format stays disciplined.
    """
    result: dict[str, dict[str, object]] = {}
    current_key: str | None = None
    current_field: str | None = None
    current_block: list[str] | None = None
    current_list: list[str] | None = None

    lines = text.splitlines()
    i = 0
    while i < len(lines):
        line = lines[i]
        stripped = line.strip()

        if not stripped or stripped.startswith("#"):
            if current_block is not None and not stripped:
                current_block.append("")
            i += 1
            continue

        indent = len(line) - len(line.lstrip(" "))

        if current_block is not None and indent >= 4:
            current_block.append(line[4:] if line.startswith("    ") else line.lstrip(" "))
            i += 1
            continue
        if current_block is not None:
            assert current_key is not None and current_field is not None
            result[current_key][current_field] = "\n".join(current_block).rstrip() + "\n"
            current_block = None

        if current_list is not None and stripped.startswith("- ") and indent >= 4:
            current_list.append(stripped[2:].strip())
            i += 1
            continue
        if current_list is not None:
            assert current_key is not None and current_field is not None
            result[current_key][current_field] = current_list
            current_list = None

        if indent == 0 and stripped.endswith(":"):
            current_key = stripped[:-1].strip()
            result[current_key] = {}
            current_field = None
            i += 1
            continue

        if indent == 2 and ":" in stripped:
            key, _, value = stripped.partition(":")
            key = key.strip()
            value = value.strip()
            if not current_key:
                raise ValueError(f"Field {key!r} outside of a top-level key at line {i + 1}")
            current_field = key
            if value == "":
                next_idx = i + 1
                while next_idx < len(lines) and not lines[next_idx].strip():
                    next_idx += 1
                if next_idx < len(lines) and lines[next_idx].lstrip().startswith("- "):
                    current_list = []
                else:
                    raise ValueError(f"Empty inline value at line {i + 1}; only lists are inferred")
            elif value == "|":
                current_block = []
            else:
                result[current_key][current_field] = value
            i += 1
            continue

        raise ValueError(f"Unparseable YAML line {i + 1}: {line!r}")

    if current_block is not None and current_key and current_field:
        result[current_key][current_field] = "\n".join(current_block).rstrip() + "\n"
    if current_list is not None and current_key and current_field:
        result[current_key][current_field] = current_list

    return result


def load(path: str | Path | None = None) -> dict[str, PermissionSignal]:
    if path is None:
        path = Path(__file__).parent / "permission_map.yaml"
    raw = _parse_minimal_yaml(Path(path).read_text(encoding="utf-8"))
    out: dict[str, PermissionSignal] = {}
    for perm, body in raw.items():
        out[perm] = PermissionSignal(
            permission=perm,
            service_name=str(body.get("service_name", "")),
            method_names=list(body.get("method_names", [])),
            log_type=str(body.get("log_type", "")),
            notes=str(body.get("notes", "")).strip(),
        )
    return out
