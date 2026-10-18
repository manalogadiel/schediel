"""Rebuild the readable spec bundle and LF-canonical document hashes.

Run from any directory with Python 3.12+. No network or third-party packages.
The machine contracts remain separate files under contracts/.
"""
from __future__ import annotations

import argparse
import hashlib
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DOCS = ['SCHEDULER_SPEC.md', 'DESIGN.md', 'CONTRACTS.md', 'SOURCES.md', 'VALIDATION.md']
APPENDICES = [
    ('DESIGN.md', 'Appendix A: Visual system and design tokens'),
    ('CONTRACTS.md', 'Appendix B: Typed integration contracts'),
    ('SOURCES.md', 'Appendix C: Primary-source register'),
    ('VALIDATION.md', 'Appendix D: Implementation validation'),
]

def slug(title: str) -> str:
    title = re.sub(r'[`*_]', '', title.lower())
    title = re.sub(r'[^\w\-\s]', '', title)
    return re.sub(r'\s', '-', title)

def text(name: str) -> str:
    return (ROOT / name).read_text(encoding='utf-8').replace('\r\n', '\n')

def bundle() -> str:
    value = text('SCHEDULER_SPEC.md')
    first, rest = value.split('\n', 1)
    contents = '\n'.join(f'- [{title}](#{slug(title)})' for _, title in APPENDICES)
    value = (first + '\n\n**Generated readable edition.** Rebuild with `python3 tools/spec_bundle.py`. '
             'Product requirements and validation are combined here; authoritative serialized schemas, fixtures, '
             'OpenAPI and native calls remain in `contracts/`. No deployment or real-device certification is implied.\n\n'
             + rest.lstrip() + '\n\n## Standalone appendices\n\n' + contents + '\n')
    for filename, title in APPENDICES:
        body = text(filename)
        if filename == 'DESIGN.md' and body.startswith('---\n'):
            _, yaml, body = body.split('---\n', 2)
            body = '```yaml\n' + yaml + '```\n\n' + body.lstrip()
        elif body.startswith('# '):
            body = body.split('\n', 1)[1].lstrip()
        value += '\n\n---\n\n# ' + title + '\n\n' + body.rstrip() + '\n'
    for filename, title in APPENDICES:
        value = value.replace(f']({filename})', f'](#{slug(title)})')
    return value.rstrip() + '\n'

def checksums(full: str) -> str:
    names = ['.gitattributes', 'CONTRACTS.md', 'DESIGN.md', 'FULL_SPEC.md', 'README.md',
             'SCHEDULER_SPEC.md', 'SOURCES.md', 'VALIDATION.md']
    return ''.join(hashlib.sha256((full if n == 'FULL_SPEC.md' else text(n)).encode('utf-8')).hexdigest()
                   + '  ' + n + '\n' for n in names)

def validate() -> dict[str, int]:
    spec = text('SCHEDULER_SPEC.md')
    reqs = re.findall(r'^\| (R\d{2}) \|', spec, re.M)
    ats = re.findall(r'^\| (AT\d{2}) \|', spec, re.M)
    assert reqs == [f'R{i:02}' for i in range(1, 25)], 'Requirement IDs changed'
    assert ats == [f'AT{i:02}' for i in range(1, 49)], 'Acceptance IDs changed'
    sources = text('SOURCES.md')
    registered = set(re.findall(r'^\[(\d+)\]\s', sources, re.M))
    if not registered:
        registered = set(re.findall(r'^\|\s*\[?(\d+)\]?\s*\|', sources, re.M))
    assert len(registered) == 35, f'Unexpected source registry: {len(registered)}'
    for name in DOCS:
        body = text(name)
        assert len(re.findall(r'^```', body, re.M)) % 2 == 0, f'Unbalanced code fences: {name}'
        cited = set(re.findall(r'\[(\d+)\](?!\()', body))
        assert cited <= registered, f'Undefined citations in {name}: {cited - registered}'
        for target in re.findall(r'\]\(([^)]+)\)', body):
            if target.startswith(('https:', 'http:', '#', 'mailto:')):
                continue
            path = target.split('#')[0]
            assert not path or (ROOT / path).exists(), f'Broken document link: {name}: {target}'
    headings = {slug(h) for h in re.findall(r'^#{1,6} (.+)$', spec, re.M)}
    for anchor in re.findall(r'\]\(#([^)]*)\)', spec):
        assert anchor in headings, f'Broken main-spec anchor: {anchor}'
    return {'requirements': len(reqs), 'acceptance_checks': len(ats), 'registered_sources': len(registered)}

def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument('--check', action='store_true', help='Verify without writing')
    args = parser.parse_args()
    counts = validate()
    full = bundle()
    hashes = checksums(full)
    if args.check:
        assert text('FULL_SPEC.md') == full, 'FULL_SPEC.md is stale'
        assert text('CHECKSUMS.sha256') == hashes, 'CHECKSUMS.sha256 is stale'
    else:
        (ROOT / 'FULL_SPEC.md').write_text(full, encoding='utf-8', newline='\n')
        (ROOT / 'CHECKSUMS.sha256').write_text(hashes, encoding='utf-8', newline='\n')
    print({'status': 'ok', **counts, 'mode': 'check' if args.check else 'rebuild'})

if __name__ == '__main__':
    main()
