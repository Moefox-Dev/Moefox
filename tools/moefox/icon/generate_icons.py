#!/usr/bin/env python3
"""
Moefox Icon Generator - Interactive Menu

Source file location (fixed):
    source/icon.png  - Bitmap source (at least 1024x1024)
    source/icon.svg  - Vector source (recommended)

Target location (fixed):
    browser/branding/moefox/

SVG support (optional):
    Requires: conda install -c conda-forge cairosvg
    Or use PNG only: pip install Pillow

Generated files:
    - default*.png (16,22,24,32,48,64,128,256)
    - VisualElements_*.png (70,150)
    - PrivateBrowsing_*.png (70,150)
    - firefox.ico, firefox64.ico, document.ico
    - newtab.ico, newwindow.ico, pbmode.ico
    - about-logo.png, about-logo@2x.png, about-logo.svg
    - msix/Assets/*.png (8 files)
"""

import sys
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    print("\nError: Pillow is required")
    print("   Install: pip install Pillow\n")
    sys.exit(1)

# SVG support (optional)
SVG_SUPPORT = False
try:
    import cairosvg
    SVG_SUPPORT = True
except (ImportError, OSError):
    pass


class IconGenerator:
    """Icon generator"""

    # Icon specs: (filename, size)
    WINDOWS_DEFAULT = [
        ("default16.png", 16),
        ("default22.png", 22),
        ("default24.png", 24),
        ("default32.png", 32),
        ("default48.png", 48),
        ("default64.png", 64),
        ("default128.png", 128),
        ("default256.png", 256),
    ]

    WINDOWS_VISUALELEMENTS = [
        ("VisualElements_70.png", 70),
        ("VisualElements_150.png", 150),
    ]

    PRIVATEMODE_VISUALELEMENTS = [
        ("PrivateBrowsing_70.png", 70),
        ("PrivateBrowsing_150.png", 150),
    ]

    ABOUT_LOGOS = [
        ("content/about-logo.png", 192),
        ("content/about-logo@2x.png", 384),
    ]

    MSIX_ASSETS = [
        ("msix/Assets/Square44x44Logo.scale-200.png", 88),
        ("msix/Assets/Square44x44Logo.targetsize-256.png", 256),
        ("msix/Assets/Square44x44Logo.altform-unplated_targetsize-256.png", 256),
        ("msix/Assets/Square44x44Logo.altform-lightunplated_targetsize-256.png", 256),
        ("msix/Assets/Square150x150Logo.scale-200.png", 300),
        ("msix/Assets/SmallTile.scale-200.png", 142),
        ("msix/Assets/LargeTile.scale-200.png", 620),
        ("msix/Assets/StoreLogo.scale-200.png", 100),
    ]

    def __init__(self, source_path: Path, output_dir: Path):
        self.source_path = source_path
        self.output_dir = output_dir
        self.is_svg = source_path.suffix.lower() in ['.svg', '.svgz']
        
        if self.is_svg:
            if not SVG_SUPPORT:
                raise ValueError("SVG requires cairosvg")
            self.image = None
        else:
            self.image = Image.open(source_path).convert("RGBA")

    def _resize_image(self, size: int) -> Image.Image:
        """Resize image to target size"""
        if self.is_svg:
            import io
            png_data = cairosvg.svg2png(
                url=str(self.source_path),
                output_width=size,
                output_height=size,
            )
            return Image.open(io.BytesIO(png_data)).convert("RGBA")
        else:
            return self.image.resize((size, size), Image.Resampling.LANCZOS)

    def _save_png(self, filename: str, size: int) -> bool:
        """Save PNG file"""
        try:
            resized = self._resize_image(size)
            output_path = self.output_dir / filename
            output_path.parent.mkdir(parents=True, exist_ok=True)
            resized.save(output_path, "PNG")
            print(f"  ✓ {filename}")
            return True
        except Exception as e:
            print(f"  ✗ {filename}: {e}")
            return False

    def _create_ico(self, ico_name: str, sizes: list) -> bool:
        """Create multi-resolution ICO file"""
        try:
            ico_images = [self._resize_image(s) for s in sorted(sizes, reverse=True)]
            output_path = self.output_dir / ico_name
            
            if len(ico_images) > 1:
                ico_images[0].save(
                    output_path,
                    format="ICO",
                    append_images=ico_images[1:],
                    sizes=[(img.size[0], img.size[1]) for img in ico_images],
                )
            else:
                ico_images[0].save(output_path, format="ICO")
            
            print(f"  ✓ {ico_name}")
            return True
        except Exception as e:
            print(f"  ✗ {ico_name}: {e}")
            return False

    def generate_all(self) -> int:
        """Generate all icon files"""
        count = 0

        # Windows default icons
        print("\n[1/7] Windows default icons")
        for filename, size in self.WINDOWS_DEFAULT:
            if self._save_png(filename, size):
                count += 1

        # Windows tiles
        print("\n[2/7] Windows tiles")
        for filename, size in self.WINDOWS_VISUALELEMENTS:
            if self._save_png(filename, size):
                count += 1

        # Private browsing tiles
        print("\n[3/7] Private browsing tiles")
        for filename, size in self.PRIVATEMODE_VISUALELEMENTS:
            if self._save_png(filename, size):
                count += 1

        # About page logos
        print("\n[4/7] About page logos")
        for filename, size in self.ABOUT_LOGOS:
            if self._save_png(filename, size):
                count += 1

        # ICO files
        print("\n[5/7] ICO files")
        if self._create_ico("firefox.ico", [16, 24, 32, 48, 64, 128, 256]):
            count += 1
        if self._create_ico("firefox64.ico", [16, 24, 32, 48, 64]):
            count += 1
        if self._create_ico("document.ico", [16, 24, 32, 48, 64]):
            count += 1
        if self._create_ico("newtab.ico", [16, 24, 32]):
            count += 1
        if self._create_ico("newwindow.ico", [16, 24, 32]):
            count += 1
        if self._create_ico("pbmode.ico", [16, 24, 32]):
            count += 1

        # MSIX assets
        print("\n[6/7] MSIX assets")
        for filename, size in self.MSIX_ASSETS:
            if self._save_png(filename, size):
                count += 1

        # SVG copy
        print("\n[7/7] SVG files")
        if self.is_svg:
            import shutil
            svg_dest = self.output_dir / "content" / "about-logo.svg"
            svg_dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(self.source_path, svg_dest)
            print(f"  ✓ content/about-logo.svg")
            count += 1
        else:
            print("  (skipped: source is not SVG)")

        return count


def print_header():
    """Print header banner"""
    print("\n" + "="*60)
    print("        Moefox Icon Generator - Interactive Menu")
    print("="*60)


def detect_source_files():
    """Detect available source files"""
    script_dir = Path(__file__).parent
    source_dir = script_dir / "source"
    
    svg_file = source_dir / "icon.svg"
    png_file = source_dir / "icon.png"
    
    available = []
    if svg_file.exists():
        if SVG_SUPPORT:
            available.append(("SVG (recommended)", svg_file, "Vector, lossless scaling"))
        else:
            available.append(("SVG (needs cairosvg)", svg_file, "Requires: conda install -c conda-forge cairosvg"))
    
    if png_file.exists():
        try:
            img = Image.open(png_file)
            size_info = f"{img.size[0]}x{img.size[1]}"
            available.append(("PNG", png_file, f"Bitmap, resolution: {size_info}"))
        except:
            pass
    
    return available


def show_menu():
    """Show main menu"""
    print_header()
    
    # Detect source files
    sources = detect_source_files()
    
    if not sources:
        print("\nError: No source files found")
        print("\nPlace a source file in one of these locations:")
        print("  - source/icon.svg (recommended)")
        print("  - source/icon.png (at least 1024x1024)\n")
        return None
    
    print("\nDetected source files:\n")
    for i, (name, path, info) in enumerate(sources, 1):
        print(f"  {i}. {name}")
        print(f"     {info}")
        print(f"     Path: {path}")
        print()
    
    # Target location
    script_dir = Path(__file__).parent
    target_dir = script_dir.parent.parent.parent / "browser" / "branding" / "moefox"
    
    print(f"Target: {target_dir}")
    
    if not target_dir.exists():
        print(f"\nWarning: target directory does not exist")
        print(f"   Will create: {target_dir}\n")
    
    print("\n" + "-"*60)
    print("\nSelect action:\n")
    
    for i, (name, _, _) in enumerate(sources, 1):
        print(f"  {i}. Generate all icons using {name}")
    
    print(f"  0. Exit")
    print()
    
    return sources, target_dir


def main():
    """Main entry point"""
    while True:
        result = show_menu()
        
        if result is None:
            return 1
        
        sources, target_dir = result
        
        try:
            choice = input("Enter choice [0-{}]: ".format(len(sources))).strip()
            
            if choice == '0':
                print("\nExited.\n")
                return 0
            
            choice_num = int(choice)
            if 1 <= choice_num <= len(sources):
                name, source_path, _ = sources[choice_num - 1]
                
                print(f"\n{'='*60}")
                print(f"Generating icons using {name}")
                print(f"{'='*60}")
                print(f"\nSource: {source_path}")
                print(f"Target: {target_dir}\n")
                
                # Confirmation
                confirm = input("Continue? (y/n): ").strip().lower()
                if confirm != 'y':
                    print("\nCancelled.\n")
                    continue
                
                # Generate icons
                target_dir.mkdir(parents=True, exist_ok=True)
                generator = IconGenerator(source_path, target_dir)
                
                count = generator.generate_all()
                
                print("\n" + "="*60)
                print(f"Done! Generated {count} files")
                print(f"   Location: {target_dir}")
                print("="*60)
                
                # Ask to continue
                again = input("\nGenerate again? (y/n): ").strip().lower()
                if again != 'y':
                    print("\nExited.\n")
                    return 0
            else:
                print(f"\nInvalid option: {choice}\n")
                input("Press Enter to continue...")
        
        except ValueError:
            print(f"\nInvalid input, please enter a number\n")
            input("Press Enter to continue...")
        except KeyboardInterrupt:
            print("\n\nExited.\n")
            return 0
        except Exception as e:
            print(f"\nError: {e}\n")
            input("Press Enter to continue...")


if __name__ == "__main__":
    sys.exit(main())
