#!/usr/bin/env python3
"""Validates the widget snapshot fixtures against their JSON Schemas.

Needs the `jsonschema` package (Draft 2020-12). Run from the repository root:
    python tools/check_widget_contracts.py
"""
import json
import sys
from pathlib import Path

try:
    import jsonschema
except ImportError:  # pragma: no cover
    print('jsonschema is not installed (pip install jsonschema)')
    sys.exit(2)

CASES = [
    ('contracts/schemas/widget-snapshot-v1.schema.json', 'contracts/fixtures/widget-snapshot-cases.json'),
    ('contracts/schemas/widget-snapshot-v1_1.schema.json', 'contracts/fixtures/widget-snapshot-cases.json'),
    ('contracts/schemas/widget-snapshot-v1_1.schema.json', 'contracts/fixtures/widget-snapshot-v1_1-cases.json'),
]


def main() -> int:
    failures = 0
    for schema_path, fixture_path in CASES:
        schema = json.loads(Path(schema_path).read_text(encoding='utf-8'))
        jsonschema.Draft202012Validator.check_schema(schema)
        snapshot = json.loads(Path(fixture_path).read_text(encoding='utf-8'))['snapshot']
        validator = jsonschema.Draft202012Validator(schema, format_checker=jsonschema.FormatChecker())
        errors = list(validator.iter_errors(snapshot))
        failures += len(errors)
        print(f'{Path(schema_path).name} <- {Path(fixture_path).name}: {len(errors)} errors')
        for e in errors[:5]:
            print('  ', '/'.join(map(str, e.path)), e.message[:160])
    return 1 if failures else 0


if __name__ == '__main__':
    sys.exit(main())
