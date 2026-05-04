# Moefox Build and Release Tools

This directory contains build, packaging, and maintenance tools for the Moefox distribution.

> **Overview**: See [docs/moefox/overview.md](../../docs/moefox/overview.md) for the complete distribution tool and document index.

## File Index

### Build and Compile

- **`build-moefox.ps1`** - Unified build entry point (interactive support)
  - Launches interactive menu when run without arguments
  - `-Dev` for development builds (fast iteration), `-Release` for release builds (multi-locale packaging)
  - Usage: `.\tools\moefox\build-moefox.ps1 -Help`

### Packaging and Release

- **`package-multi-locale.ps1`** - Multi-locale packaging main script
  - Automates the full build and multi-locale packaging workflow
  - Supports `-Clobber` for clean builds (recommended for releases)
  - See [RELEASE.md](RELEASE.md) for the complete workflow

- **`l10n_overlay.py`** - Localization overlay merge tool
  - Merges Moefox-specific translation strings into packaged locale files
  - Only appends missing keys, never overwrites upstream translations
  - Automatically invoked by `package-multi-locale.ps1`

- **`stage-extension.ps1`** - Unified extension staging script
  - Downloads latest XPI from AMO and deploys to distribution/extensions directory
  - Supports preset extensions and custom URLs, auto-parses add-on id
  - Usage: `.\tools\moefox\stage-extension.ps1 -Extension ublock`
  - Supported presets: `ublock`, `bitwarden`, `multi-account-containers`
  - Automatically invoked by `package-multi-locale.ps1`

### User Data Management

- **`clean-user-data.ps1`** - User data cleanup script
  - Thoroughly removes all Moefox user data and settings
  - Ensures a completely clean state before reinstalling
  - Supports interactive confirmation or `-Force` mode
  - **Warning**: This operation is irreversible and will delete all user data

### Documentation

- **`RELEASE.md`** - Complete packaging and release workflow documentation
  - Detailed packaging step instructions
  - Verification checklist
  - Troubleshooting suggestions

## Quick Start

### Interactive Build (Recommended)

```powershell
# Launches interactive menu to guide build mode selection
.\tools\moefox\build-moefox.ps1
```

### Command Line Build

```powershell
# Quick dev iteration (skip configure)
.\tools\moefox\build-moefox.ps1 -Dev -Quick

# Full dev build
.\tools\moefox\build-moefox.ps1 -Dev

# Clean dev build (first time or after major changes)
.\tools\moefox\build-moefox.ps1 -Dev -Clean

# Release build (recommend using -Clobber)
.\tools\moefox\build-moefox.ps1 -Release -Clobber

# Show help
.\tools\moefox\build-moefox.ps1 -Help
```

### Pre-installed Extensions

```powershell
# Download and stage uBlock Origin
.\tools\moefox\stage-extension.ps1 -Extension ublock -StageToObjDir

# Download and stage Bitwarden
.\tools\moefox\stage-extension.ps1 -Extension bitwarden -StageToObjDir

# Download and stage Firefox Multi-Account Containers
.\tools\moefox\stage-extension.ps1 -Extension multi-account-containers -StageToObjDir
```

**Note**: All pre-installed extensions (uBlock Origin, Bitwarden, Firefox Multi-Account Containers) will have their buttons automatically pinned to the toolbar on first Moefox launch.

### Clean User Data (Testing/Debugging)

```powershell
# Interactive cleanup (recommended)
powershell -NoProfile -ExecutionPolicy Bypass -File tools/moefox/clean-user-data.ps1

# Force cleanup (skip confirmation)
powershell -NoProfile -ExecutionPolicy Bypass -File tools/moefox/clean-user-data.ps1 -Force
```

## Important Notes

1. **Dev vs Release Builds**
   - Use `mach run` for development testing (uses `obj-x86_64-pc-windows-msvc`)
   - Use `package-multi-locale.ps1` for release packaging (uses `obj-x86_64-pc-windows-msvc-multilocale`)

2. **When to Clean Build**
   - Use `-Clobber` before official releases
   - Use `-Clobber` when encountering unexplained packaging issues
   - Generally not needed during development

3. **User Data Cleanup**
   - For development and testing only, not intended for end users
   - Ensure important data is backed up before cleaning
   - Useful for verifying "fresh install" experience

4. **Artifact Build Limitations**
   - Cannot modify C/C++/Rust code
   - Configuration files (e.g. search-config-v2.json) come from pre-compiled artifacts
   - Relies on runtime logic (e.g. SearchEngineSelector) for customization

## Troubleshooting

**Issue: UI always shows English after installation**
- Check if `dist/bin/res/multilocale.txt` contains all languages
- Clean user data with cleanup script and reinstall
- Re-package with `-Clobber` parameter

**Issue: Custom settings not applied**
- Verify you are using a fresh profile (not an old one)
- Check relevant pref values in about:config
- Use cleanup script to ensure clean state

**Issue: Missing translation strings**
- Check if `browser/locales/<locale>/browser/preferences/moefox.ftl` exists
- Verify l10n_overlay.py executed successfully
- Unpack `omni.ja` to verify preferences.ftl contains Moefox keys

## References

- [RELEASE.md](RELEASE.md) - Detailed packaging workflow
- [build/docs/locales.rst](../../build/docs/locales.rst) - Firefox localization build docs
- [browser/locales/](../../browser/locales/) - Localization files directory
