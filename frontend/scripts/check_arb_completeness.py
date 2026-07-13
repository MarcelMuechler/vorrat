#!/usr/bin/env python3
"""Fails if a non-English ARB file is missing a key present in app_en.arb.

Run from the frontend/ directory: python3 scripts/check_arb_completeness.py
"""
import json
import sys
from pathlib import Path

L10N_DIR = Path(__file__).parent.parent / "lib" / "l10n"


def keys(path: Path) -> set[str]:
    data = json.loads(path.read_text())
    return {k for k in data if not k.startswith("@")}


def main() -> int:
    en_keys = keys(L10N_DIR / "app_en.arb")
    failed = False
    for arb in sorted(L10N_DIR.glob("app_*.arb")):
        if arb.name == "app_en.arb":
            continue
        missing = en_keys - keys(arb)
        if missing:
            failed = True
            print(f"{arb.name} is missing keys: {', '.join(sorted(missing))}")
    if failed:
        return 1
    print("All translations have every key from app_en.arb.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
