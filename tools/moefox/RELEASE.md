# Moefox Packaging / Release Workflow (Windows)

This document describes the recommended workflow for producing "out-of-the-box" multi-locale installer/zip packages for Moefox on Windows.

## Goals

- Produce a multi-locale package (multiple languages built-in), allowing users to switch languages directly after installation.
- Moefox-specific strings are maintained only in `browser/locales/<locale>/browser/preferences/moefox.ftl`.
- During packaging, only "fill in missing keys" — never overwrite upstream translations.

## Prerequisites

- MozillaBuild installed and configured (able to run `mach.ps1`).
- Clean working tree (`git status` with no uncommitted changes recommended).
- Moefox branding/channel configured in `mozconfig.multilocale`.

## Release Packaging (multi-locale + overlay)

1. Verify Moefox-only string files are complete:
   - `browser/locales/en-US/browser/preferences/moefox.ftl`
   - For each supported language: `browser/locales/<locale>/browser/preferences/moefox.ftl`

2. Run the one-click packaging script:

   - `powershell -NoProfile -ExecutionPolicy Bypass -File tools/moefox/package-multi-locale.ps1`

   This script will execute:
   - `mach configure` (using `mozconfig.multilocale`)
   - `mach artifact install`
   - `mach build`
   - `mach package-multi-locale --locales ...`
   - Run `tools/moefox/l10n_overlay.py` to append Moefox-only keys into the packaged `preferences.ftl`
   - **Auto-deploy uBlock Origin** to `dist/bin/distribution/extensions/` (no need to manually run `stage-extension.ps1`)
   - **Auto-deploy Bitwarden** to `dist/bin/distribution/extensions/` (no need to manually run `stage-extension.ps1`)
   - **Auto-deploy Firefox Multi-Account Containers** to `dist/bin/distribution/extensions/` (no need to manually run `stage-extension.ps1`)
   - Remove old `dist/bin/res/multilocale.txt`, set `MOZ_CHROME_MULTILOCALE` and run `mach package` again

   To deploy extensions individually (e.g. for single-language builds), run manually:
   - `.\tools\moefox\stage-extension.ps1 -Extension ublock -StageToObjDir`
   - `.\tools\moefox\stage-extension.ps1 -Extension bitwarden -StageToObjDir`
   - `.\tools\moefox\stage-extension.ps1 -Extension multi-account-containers -StageToObjDir`
   Note: The script downloads `latest.xpi` from AMO to `dist/bin/distribution/extensions/`, loaded by Firefox's distribution sideload mechanism. These three extensions' buttons will be automatically pinned to the toolbar on first launch.

   > **Security Note**: All three extensions are downloaded live from AMO via HTTPS without version pinning or hash verification. For official releases, manually verify XPI hashes against AMO release pages:
   > ```powershell
   > Get-ChildItem "$objdir\dist\bin\distribution\extensions\*.xpi" |
   >     ForEach-Object { Write-Host $_.Name; (Get-FileHash $_.FullName -Algorithm SHA256).Hash }
   > ```

3. Check artifacts:

   - Directory: `obj-x86_64-pc-windows-msvc-multilocale/dist/`
   - Common files:
     - `firefox-<version>.en-US.win64.installer.exe`
     - `firefox-<version>.en-US.win64.zip`

## Verification Checklist (Highly Recommended)

1. Verify multi-locale declaration (critical):

   - Check `obj-x86_64-pc-windows-msvc-multilocale/dist/bin/res/multilocale.txt`
   - Should contain target locales (e.g. `de,fr,...,zh-CN,...,en-US`), not just `en-US`

   Note: If this file only contains `en-US`, non-en-US locales may fall back to external langpack paths, causing Moefox-only keys to be missing and fall back to English.

2. Verify overlay is in final runtime resources:

   - Spot-check from `obj-x86_64-pc-windows-msvc-multilocale/dist/firefox/omni.ja`:
     - `localization/<locale>/browser/preferences/preferences.ftl` contains Moefox-added l10n-ids.

3. Installation verification (manual):

   - Install using the generated `installer.exe` to a clean directory.
   - Switch to a non-en-US locale (e.g. zh-CN), open settings page, verify Moefox-added strings display in the selected language.

## Clean User Data (Before Reinstalling)

To completely clear Moefox user data (ensuring a fresh state after reinstallation), use the cleanup script:

```powershell
# Interactive mode (with confirmation prompts)
powershell -NoProfile -ExecutionPolicy Bypass -File tools/moefox/clean-user-data.ps1

# Force mode (skip confirmation, use with caution)
powershell -NoProfile -ExecutionPolicy Bypass -File tools/moefox/clean-user-data.ps1 -Force
```

This script will remove:
- All user profiles and settings
- Browsing history, bookmarks, passwords
- Installed extensions and themes
- Cache and temporary files
- Windows registry entries
- Start menu shortcuts

**Note**: This operation is **irreversible**. Ensure important data (bookmarks, passwords, etc.) is backed up.

## Development / Testing Notes

- During development, `mach run` with en-US is sufficient for testing.
- `tools/moefox/l10n_overlay.py` is only used for overlay merging on packaged artifacts, not for profile/langpack modifications.
- If `mach run` works correctly but the installer does not, try:
  1. Re-package with `-Clobber`: `tools/moefox/package-multi-locale.ps1 -Clobber`
  2. Clean all user data with the cleanup script and reinstall for testing
