"""
App Icon Generator for PublicOS Desktop
Generates all required icon sizes for Windows (.ico), macOS, and Linux.

Design: Phigital logo — large rounded square with smaller rounded square above it.
Matches the PhigitalLoadingWidget static pose (small element at 12 o'clock).

Colors match the Civic Modernism palette:
  Background: slateDarkest (#1e2328)
  Foreground: light gray (#cccccc)
"""

from PIL import Image, ImageDraw
import os
import struct

# Colors
FG_COLOR = (204, 204, 204)       # Light gray shapes
BG_COLOR = (30, 35, 40)          # slateDarkest
SHADOW_COLOR = (20, 24, 28)      # Darker shadow

# Proportions from PhigitalLoadingWidget
# Main square: size x size, borderRadius = size * 0.42
# Orbiting square: size * 0.375, borderRadius = orbitingSize * 0.44
# Orbit offset: size * 0.875 (distance from center)
# Static position: top (-π/2), so offset is (0, -orbitOffset)


def draw_rounded_rect(draw, x, y, w, h, radius, fill):
    """Draw a rounded rectangle using ellipses and rectangles."""
    r = min(radius, w // 2, h // 2)
    # Four corner circles
    draw.ellipse([x, y, x + 2*r, y + 2*r], fill=fill)
    draw.ellipse([x + w - 2*r, y, x + w, y + 2*r], fill=fill)
    draw.ellipse([x, y + h - 2*r, x + 2*r, y + h], fill=fill)
    draw.ellipse([x + w - 2*r, y + h - 2*r, x + w, y + h], fill=fill)
    # Two overlapping rectangles
    draw.rectangle([x + r, y, x + w - r, y + h], fill=fill)
    draw.rectangle([x, y + r, x + w, y + h - r], fill=fill)


def draw_phigital_icon(canvas_size, padding_ratio=0.15):
    """
    Draw the phigital icon at the specified canvas size.
    Returns an RGBA image.
    """
    img = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # The "size" parameter from the widget — scale to fill canvas with padding
    # Container in widget is size * 2.9, so size = canvas / 2.9
    # But we want padding, so shrink further
    effective_canvas = canvas_size * (1 - 2 * padding_ratio)
    size = effective_canvas / 2.9
    center = canvas_size / 2

    # Main square dimensions
    main_w = size
    main_h = size
    main_radius = size * 0.42

    # Orbiting square dimensions
    orbit_size = size * 0.375
    orbit_radius = orbit_size * 0.44
    orbit_offset = size * 0.875  # distance from center to orbiting center

    # Centering rule: frame_center = (moon_top + main_bottom) / 2
    # Shift = (orbit_offset + orbit_size/2 - main_h/2) / 2
    centering_shift = (orbit_offset + orbit_size / 2 - main_h / 2) / 2

    # Main square position (shifted down by centering rule)
    main_x = center - main_w / 2
    main_y = center - main_h / 2 + centering_shift

    # Shadow for main square (offset down 3px equivalent, scaled)
    shadow_offset = max(1, int(size * 0.0625))
    draw_rounded_rect(draw,
                       int(main_x), int(main_y + shadow_offset),
                       int(main_w), int(main_h),
                       int(main_radius), SHADOW_COLOR)

    # Main square
    draw_rounded_rect(draw,
                       int(main_x), int(main_y),
                       int(main_w), int(main_h),
                       int(main_radius), FG_COLOR)

    # Orbiting square position (top, -π/2 means straight up, shifted by centering rule)
    orbit_center_x = center
    orbit_center_y = center - orbit_offset + centering_shift
    orbit_x = orbit_center_x - orbit_size / 2
    orbit_y = orbit_center_y - orbit_size / 2

    # Shadow for orbiting square
    orbit_shadow_offset = max(1, int(orbit_size * 0.0625))
    draw_rounded_rect(draw,
                       int(orbit_x), int(orbit_y + orbit_shadow_offset),
                       int(orbit_size), int(orbit_size),
                       int(orbit_radius), SHADOW_COLOR)

    # Orbiting square
    draw_rounded_rect(draw,
                       int(orbit_x), int(orbit_y),
                       int(orbit_size), int(orbit_size),
                       int(orbit_radius), FG_COLOR)

    return img


def draw_icon_with_bg(canvas_size, padding_ratio=0.15):
    """Draw the icon composited onto the dark background."""
    bg = Image.new("RGB", (canvas_size, canvas_size), BG_COLOR)
    fg = draw_phigital_icon(canvas_size, padding_ratio)
    bg.paste(fg, (0, 0), fg)
    return bg


def create_ico(images_dict, output_path):
    """
    Create a .ico file from a dict of {size: PIL.Image}.
    Uses PIL's built-in ICO save.
    """
    # Get the largest image as the base
    sizes = sorted(images_dict.keys(), reverse=True)
    base_img = images_dict[sizes[0]]

    # PIL can save ICO with multiple sizes
    ico_sizes = [(s, s) for s in sizes]
    base_img.save(output_path, format='ICO', sizes=ico_sizes)


def generate_windows_icon(base_path):
    """Generate Windows .ico file with multiple sizes."""
    print("\n=== Generating Windows Icon ===")

    icon_sizes = [16, 32, 48, 64, 128, 256]
    images = {}

    for size in icon_sizes:
        img = draw_icon_with_bg(size, padding_ratio=0.12)
        images[size] = img
        print(f"  {size}x{size} rendered")

    # Save as ICO
    ico_path = os.path.join(base_path, "windows", "runner", "resources", "app_icon.ico")
    os.makedirs(os.path.dirname(ico_path), exist_ok=True)

    # Use the 256px image as base and include all sizes
    largest = images[256]
    largest.save(ico_path, format='ICO',
                 sizes=[(s, s) for s in icon_sizes])
    print(f"\n  -> {ico_path}")


def generate_macos_icons(base_path):
    """Generate macOS app icon PNGs."""
    print("\n=== Generating macOS Icons ===")

    macos_sizes = [16, 32, 64, 128, 256, 512, 1024]
    assets_path = os.path.join(base_path, "macos", "Runner", "Assets.xcassets",
                               "AppIcon.appiconset")
    os.makedirs(assets_path, exist_ok=True)

    for size in macos_sizes:
        img = draw_icon_with_bg(size, padding_ratio=0.1)
        filename = f"app_icon_{size}.png"
        filepath = os.path.join(assets_path, filename)
        img.save(filepath, "PNG")
        print(f"  {size}x{size} -> {filename}")

    # Generate Contents.json
    contents = generate_macos_contents_json()
    contents_path = os.path.join(assets_path, "Contents.json")
    with open(contents_path, "w") as f:
        f.write(contents)
    print(f"\n  Contents.json -> {contents_path}")


def generate_macos_contents_json():
    """Generate Contents.json for macOS asset catalog."""
    import json

    specs = [
        {"size": "16x16", "scale": "1x", "filename": "app_icon_16.png"},
        {"size": "16x16", "scale": "2x", "filename": "app_icon_32.png"},
        {"size": "32x32", "scale": "1x", "filename": "app_icon_32.png"},
        {"size": "32x32", "scale": "2x", "filename": "app_icon_64.png"},
        {"size": "128x128", "scale": "1x", "filename": "app_icon_128.png"},
        {"size": "128x128", "scale": "2x", "filename": "app_icon_256.png"},
        {"size": "256x256", "scale": "1x", "filename": "app_icon_256.png"},
        {"size": "256x256", "scale": "2x", "filename": "app_icon_512.png"},
        {"size": "512x512", "scale": "1x", "filename": "app_icon_512.png"},
        {"size": "512x512", "scale": "2x", "filename": "app_icon_1024.png"},
    ]

    images = []
    for spec in specs:
        images.append({
            "size": spec["size"],
            "idiom": "mac",
            "filename": spec["filename"],
            "scale": spec["scale"],
        })

    contents = {
        "images": images,
        "info": {
            "version": 1,
            "author": "generate_icons.py"
        }
    }

    return json.dumps(contents, indent=2)


def generate_linux_icon(base_path):
    """Generate Linux icon PNG."""
    print("\n=== Generating Linux Icon ===")

    # Standard sizes for Linux desktop
    for size in [64, 128, 256, 512]:
        img = draw_icon_with_bg(size, padding_ratio=0.1)
        filepath = os.path.join(base_path, "linux", f"app_icon_{size}.png")
        img.save(filepath, "PNG")
        print(f"  {size}x{size} -> linux/app_icon_{size}.png")


def generate_web_icons(base_path):
    """Generate web favicons (for PWA / hosted desktop)."""
    print("\n=== Generating Web Icons ===")

    web_path = os.path.join(base_path, "web")
    os.makedirs(web_path, exist_ok=True)

    web_sizes = {
        16: "favicon-16x16.png",
        32: "favicon-32x32.png",
        192: "icons/Icon-192.png",
        512: "icons/Icon-512.png",
    }

    for size, filename in web_sizes.items():
        filepath = os.path.join(web_path, filename)
        os.makedirs(os.path.dirname(filepath), exist_ok=True)
        img = draw_icon_with_bg(size, padding_ratio=0.1)
        img.save(filepath, "PNG")
        print(f"  {size}x{size} -> web/{filename}")


def generate_test_icon(base_path):
    """Generate a single large test icon for preview."""
    print("\n=== Generating Test Icon ===")

    size = 512
    img = draw_icon_with_bg(size, padding_ratio=0.1)
    filepath = os.path.join(base_path, "test_icon.png")
    img.save(filepath, "PNG")
    print(f"  {size}x{size} -> test_icon.png")


def main():
    import sys

    base_path = os.path.dirname(os.path.abspath(__file__))

    if len(sys.argv) > 1 and sys.argv[1] == "test":
        print("PublicOS Desktop Icon Generator - TEST MODE")
        print("=" * 50)
        generate_test_icon(base_path)
        print("\nTest icon generated! Check test_icon.png")
        return

    print("PublicOS Desktop Icon Generator")
    print("=" * 50)
    print(f"Design: Phigital logo (rounded square + orbiting square)")
    print(f"Background: {BG_COLOR}")
    print(f"Foreground: {FG_COLOR}")

    generate_windows_icon(base_path)
    generate_macos_icons(base_path)
    generate_linux_icon(base_path)
    generate_web_icons(base_path)

    print("\n" + "=" * 50)
    print("Icon generation complete!")


if __name__ == "__main__":
    main()
