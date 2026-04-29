#!/bin/bash
set -euo pipefail

cd "/app/pydantic-assessment"

python3 <<'PY'
from pathlib import Path

path = Path('pydantic/main.py')
text = path.read_text()

replacements = [
    (
        "        fields_values: dict[str, Any] = {}\n        fields_set = set()\n",
        "        fields_values: dict[str, Any] = {}\n        fields_set = set()\n        used_alias_path_roots: list[Any] = []\n",
    ),
    (
        "                            fields_values[name] = value\n                            fields_set.add(name)\n                            break\n",
        "                            fields_values[name] = value\n                            fields_set.add(name)\n                            if alias.path:\n                                used_alias_path_roots.append(alias.path[0])\n                            break\n",
    ),
    (
        "        _extra: dict[str, Any] | None = values if cls.model_config.get('extra') == 'allow' else None\n",
        "        if cls.model_config.get('extra') == 'allow':\n"
        "            if used_alias_path_roots:\n"
        "                _extra: dict[str, Any] | None = {\n"
        "                    key: value for key, value in values.items() if key not in used_alias_path_roots\n"
        "                }\n"
        "            else:\n"
        "                _extra = values\n"
        "        else:\n"
        "            _extra = None\n",
    ),
]

for old, new in replacements:
    if old not in text:
        raise RuntimeError(f'expected source fragment not found: {old!r}')
    text = text.replace(old, new, 1)

path.write_text(text)
PY
