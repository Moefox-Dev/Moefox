# Moefox Icon Generator

Interactive menu to generate all brand icons.

## Usage

```bash
# 1. Place source file in source/ directory
source/icon.svg  # or source/icon.png

# 2. Run
python generate_icons.py

# 3. Follow menu prompts
```

## Dependencies

```bash
pip install Pillow
# SVG: conda install -c conda-forge cairosvg
```

## Notes

- Source file name is fixed: `source/icon.svg` or `source/icon.png`
- Target location is fixed: `browser/branding/moefox/`
- SVG resolution does not affect quality, lossless scaling
