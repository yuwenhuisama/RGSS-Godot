"""Reject literal machine paths in test and verification source files."""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SUFFIXES = {".gd", ".rb", ".ps1", ".cmd", ".sh", ".py", ".js", ".cs", ".m"}
PATTERN = re.compile(r"(?<![A-Za-z])[A-Za-z]:(?:/|\\(?![nrt](?:\s|['\"]|$)))|/Users/[A-Za-z]|\$HOME/RGSS-Godot-Verification|Voicemeeter Out")
failures: list[str] = []
for directory in (ROOT / "tests", ROOT / "tools"):
    for source in directory.rglob("*"):
        if source.suffix not in SUFFIXES or "bin" in source.parts or "obj" in source.parts or ".tmp." in source.name:
            continue
        if source.name == "check_test_paths.py":
            continue
        for number, line in enumerate(source.read_text(encoding="utf-8-sig").splitlines(), 1):
            if PATTERN.search(line):
                failures.append(f"{source.relative_to(ROOT)}:{number}: {line.strip()}")
if failures:
    print("\n".join(failures), file=sys.stderr)
    sys.exit(1)
print("TEST_MACHINE_PATH_SCAN_PASS")
