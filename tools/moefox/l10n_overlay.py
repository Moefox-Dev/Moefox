# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

"""
Merge Moefox-local overlay Fluent strings into packaged locale files.

This script handles two types of overlays:
1. preferences.ftl - Moefox-specific UI strings (merged as missing keys)
2. branding/brand.ftl - Moefox brand names (force-copied from branding source)

The branding files need special handling because:
- l10n-central contains branding for 'official' Firefox only
- Moefox uses custom branding ('moefox') which has its own translations
- The build system may create empty brand.ftl files for non-en-US locales
"""

from __future__ import annotations

import argparse
import re
import shutil
from pathlib import Path


_KEY_RE = re.compile(r"^([A-Za-z0-9][A-Za-z0-9_-]*)\s*=", re.MULTILINE)


def _read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def _write_text(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8", newline="\n")


def _keys_in_ftl(content: str) -> set[str]:
    return set(_KEY_RE.findall(content))


def _merge_missing_keys_content(base_content: str, overlay_content: str) -> tuple[str, bool]:
    base_keys = _keys_in_ftl(base_content)
    overlay_keys = _keys_in_ftl(overlay_content)

    missing = [k for k in sorted(overlay_keys) if k not in base_keys]
    if not missing:
        return base_content, False

    suffix = overlay_content.strip()
    if not suffix:
        return base_content, False

    out = base_content.rstrip()
    if out:
        out += "\n\n"
    out += suffix
    out += "\n"
    return out, True


def merge_missing_keys(base_ftl: Path, overlay_ftl: Path) -> bool:
    """Merge missing Fluent messages from overlay into base.

    Only appends messages whose message ids are not already present in base.
    This ensures upstream/localization changes in base always win.

    Returns True if base was modified.
    """

    base_content = _read_text(base_ftl) if base_ftl.exists() else ""
    overlay_content = _read_text(overlay_ftl)

    out, changed = _merge_missing_keys_content(base_content, overlay_content)
    if not changed:
        return False

    _write_text(base_ftl, out)
    return True


def _replace_or_add_keys_content(base_content: str, overlay_content: str) -> tuple[str, bool]:
    """Replace existing keys or add new keys from overlay into base.
    
    Unlike merge_missing_keys, this will REPLACE values for keys that exist in both.
    """
    base_keys = _keys_in_ftl(base_content)
    overlay_keys = _keys_in_ftl(overlay_content)
    
    if not overlay_keys:
        return base_content, False
    
    # Parse overlay into key-value blocks
    overlay_blocks = {}
    current_key = None
    current_lines = []
    
    for line in overlay_content.split('\n'):
        match = _KEY_RE.match(line)
        if match:
            # Save previous block if exists
            if current_key:
                overlay_blocks[current_key] = '\n'.join(current_lines)
            current_key = match.group(1)
            current_lines = [line]
        elif current_key:
            # Continue current block (multi-line values, attributes like .aria-label)
            if line.strip() and not line.startswith('#'):
                current_lines.append(line)
            elif line.strip().startswith('#'):
                # Comment before next key, save current
                if current_key:
                    overlay_blocks[current_key] = '\n'.join(current_lines)
                    current_key = None
                    current_lines = []
    
    # Don't forget the last block
    if current_key:
        overlay_blocks[current_key] = '\n'.join(current_lines)
    
    changed = False
    result_lines = []
    skip_until_next_key = False
    
    for line in base_content.split('\n'):
        match = _KEY_RE.match(line)
        if match:
            key = match.group(1)
            if key in overlay_blocks:
                # Replace with overlay version
                result_lines.append(overlay_blocks[key])
                del overlay_blocks[key]  # Mark as used
                skip_until_next_key = True
                changed = True
                continue
            else:
                skip_until_next_key = False
        
        if skip_until_next_key:
            # Skip continuation lines of replaced key
            if line.strip() and not line.startswith('#') and not _KEY_RE.match(line):
                continue
            skip_until_next_key = False
        
        result_lines.append(line)
    
    # Append any remaining overlay keys that weren't in base
    if overlay_blocks:
        result_lines.append('')
        for key, block in overlay_blocks.items():
            result_lines.append(block)
        changed = True
    
    return '\n'.join(result_lines), changed


def replace_or_add_keys(base_ftl: Path, overlay_ftl: Path) -> bool:
    """Replace or add Fluent messages from overlay into base.
    
    This will REPLACE values for keys that exist in both files,
    and ADD keys that only exist in overlay.
    
    Returns True if base was modified.
    """
    base_content = _read_text(base_ftl) if base_ftl.exists() else ""
    overlay_content = _read_text(overlay_ftl)
    
    out, changed = _replace_or_add_keys_content(base_content, overlay_content)
    if not changed:
        return False
    
    _write_text(base_ftl, out)
    return True


def force_copy(src: Path, dst: Path) -> bool:
    """Force copy src to dst, overwriting if necessary.
    
    Returns True if dst was modified (or created).
    """
    if not src.exists():
        return False
    
    dst.parent.mkdir(parents=True, exist_ok=True)
    
    # Check if content differs
    if dst.exists():
        src_content = _read_text(src)
        dst_content = _read_text(dst)
        if src_content == dst_content:
            return False
    
    shutil.copy2(src, dst)
    return True


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Merge Moefox-local overlay Fluent strings into packaged locale files."
    )
    parser.add_argument(
        "--objdir",
        required=True,
        type=Path,
        help="Path to the object directory (e.g. obj-x86_64-pc-windows-msvc).",
    )
    parser.add_argument(
        "--locales",
        required=True,
        nargs="+",
        help="Locales to patch (e.g. zh-CN de fr).",
    )
    parser.add_argument(
        "--overlay-root",
        default=Path("browser/locales"),
        type=Path,
        help="Path to overlay root containing per-locale moefox.ftl files.",
    )
    parser.add_argument(
        "--branding-root",
        default=Path("browser/branding/moefox/locales"),
        type=Path,
        help="Path to Moefox branding locales root.",
    )

    args = parser.parse_args()

    objdir = args.objdir
    overlay_root = args.overlay_root
    branding_root = args.branding_root

    # Packaged localization directory (multi-locale repacks).
    dist_l10n_root = objdir / "dist" / "bin" / "browser" / "localization"

    changed_any = False
    
    for locale in args.locales:
        # --- 1) Patch preferences.ftl with Moefox overlay strings ---
        overlay = overlay_root / locale / "browser" / "preferences" / "moefox.ftl"
        if overlay.exists():
            base = (
                dist_l10n_root
                / locale
                / "browser"
                / "preferences"
                / "preferences.ftl"
            )

            if base.exists():
                if merge_missing_keys(base, overlay):
                    print(f"[l10n-overlay] patched preferences {locale}: {base}")
                    changed_any = True
                else:
                    print(f"[l10n-overlay] ok preferences {locale}: no changes")
            else:
                print(f"[l10n-overlay] skip preferences {locale}: missing {base}")
        
        # --- 2) Patch newtab.ftl with Moefox overlay strings (wallpaper etc.) ---
        newtab_overlay = overlay_root / locale / "browser" / "newtab" / "moefox.ftl"
        if newtab_overlay.exists():
            newtab_base = (
                dist_l10n_root
                / locale
                / "browser"
                / "newtab"
                / "newtab.ftl"
            )

            if newtab_base.exists():
                if merge_missing_keys(newtab_base, newtab_overlay):
                    print(f"[l10n-overlay] patched newtab {locale}: {newtab_base}")
                    changed_any = True
                else:
                    print(f"[l10n-overlay] ok newtab {locale}: no changes")
            else:
                print(f"[l10n-overlay] skip newtab {locale}: missing {newtab_base}")
        
        # --- 2.5) Patch onboarding.ftl with Moefox overlay strings ---
        # Use replace_or_add_keys to OVERRIDE existing translations (not just add missing)
        onboarding_overlay = overlay_root / locale / "browser" / "newtab" / "onboarding.ftl"
        if onboarding_overlay.exists():
            onboarding_base = (
                dist_l10n_root
                / locale
                / "browser"
                / "newtab"
                / "onboarding.ftl"
            )

            if onboarding_base.exists():
                if replace_or_add_keys(onboarding_base, onboarding_overlay):
                    print(f"[l10n-overlay] patched onboarding {locale}: {onboarding_base}")
                    changed_any = True
                else:
                    print(f"[l10n-overlay] ok onboarding {locale}: no changes")
            else:
                print(f"[l10n-overlay] skip onboarding {locale}: missing {onboarding_base}")
        
        # --- 3) Force-copy Moefox branding files ---
        # The build system may create empty brand.ftl for non-en-US locales
        # because l10n-central only has 'official' branding, not 'moefox'.
        branding_src = branding_root / locale / "brand.ftl"
        branding_dst = dist_l10n_root / locale / "branding" / "brand.ftl"
        
        if branding_src.exists():
            if force_copy(branding_src, branding_dst):
                print(f"[l10n-overlay] copied branding {locale}: {branding_dst}")
                changed_any = True
            else:
                print(f"[l10n-overlay] ok branding {locale}: unchanged")
        else:
            print(f"[l10n-overlay] skip branding {locale}: missing source {branding_src}")

    if not changed_any:
        print("[l10n-overlay] no files changed")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
