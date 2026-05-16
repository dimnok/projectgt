#!/usr/bin/env python3
"""Поднимает строку `version:` в pubspec.yaml (семантическая часть и/или build)."""

from __future__ import annotations

import argparse
import re
from pathlib import Path


def bump_patch(version: str) -> str:
    parts = version.split(".")
    if not parts:
        raise ValueError(f"Пустая версия: {version!r}")
    parts[-1] = str(int(parts[-1]) + 1)
    return ".".join(parts)


def main() -> None:
    parser = argparse.ArgumentParser(description="Bump pubspec version line.")
    parser.add_argument(
        "--pubspec",
        type=Path,
        default=Path("pubspec.yaml"),
        help="Путь к pubspec.yaml",
    )
    parser.add_argument(
        "--build-only",
        action="store_true",
        help="Только увеличить номер после + (marketing version без изменений).",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Только показать новую строку, файл не менять.",
    )
    args = parser.parse_args()

    text = args.pubspec.read_text(encoding="utf-8")
    m = re.search(r"^version:\s*([\d.]+)\+(\d+)\s*$", text, re.MULTILINE)
    if not m:
        raise SystemExit(
            "Не найдена строка вида `version: X.Y.Z+N` в pubspec.yaml"
        )

    marketing, build_str = m.group(1), int(m.group(2))
    if args.build_only:
        new_marketing = marketing
        new_build = build_str + 1
    else:
        new_marketing = bump_patch(marketing)
        new_build = build_str + 1

    new_line = f"version: {new_marketing}+{new_build}"
    new_text = re.sub(
        r"^version:\s*[\d.]+\+\d+\s*$",
        new_line,
        text,
        count=1,
        flags=re.MULTILINE,
    )

    print(f"{marketing}+{build_str} → {new_marketing}+{new_build}")

    if args.dry_run:
        return

    args.pubspec.write_text(new_text, encoding="utf-8")


if __name__ == "__main__":
    main()
