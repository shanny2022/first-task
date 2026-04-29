#!/bin/bash
set -euo pipefail

cd "/app/pydantic-assessment"

python3 <<'PY'
from pathlib import Path

path = Path('pydantic/main.py')
text = path.read_text()

replacements = [
    (
        'insert alias-path root tracking',
        "        fields_values: dict[str, Any] = {}\n        fields_set = set()\n",
        "        fields_values: dict[str, Any] = {}\n        fields_set = set()\n        used_alias_path_roots: list[Any] = []\n",
    ),
    (
        'record successful alias-path roots',
        "                            fields_values[name] = value\n                            fields_set.add(name)\n                            break\n",
        "                            fields_values[name] = value\n                            fields_set.add(name)\n                            if alias.path:\n                                used_alias_path_roots.append(alias.path[0])\n                            break\n",
    ),
    (
        'filter consumed alias-path roots from extras',
        "        _extra: dict[str, Any] | None = values if cls.model_config.get('extra') == 'allow' else None\n",
        "        _extra: dict[str, Any] | None = (\n"
        "            {key: value for key, value in values.items() if key not in used_alias_path_roots}\n"
        "            if used_alias_path_roots\n"
        "            else values\n"
        "        ) if cls.model_config.get('extra') == 'allow' else None\n",
    ),
]

# The task runner resets /app/pydantic-assessment to the configured base commit before this script runs, so exact source fragments keep the edit narrowly scoped.
for index, (label, old, new) in enumerate(replacements, start=1):
    if old not in text:
        preview = old.splitlines()[0].strip()
        raise RuntimeError(
            f'replacement {index} of {len(replacements)} failed ({label}): '
            f'expected source fragment not found; first line: {preview!r}'
        )
    text = text.replace(old, new, 1)

path.write_text(text)
PY
