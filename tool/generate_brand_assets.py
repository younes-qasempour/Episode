"""Generate Episode runtime branding from the approved logo masters.

Run from the repository root with:

    python tool/generate_brand_assets.py

The script keeps platform assets deterministic and derives every small icon
from the high-resolution masters instead of resizing an already-small output.
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "tool" / "brand_sources"
MARK_SOURCE = SOURCE_DIR / "episode_mark_master.png"
ICON_SOURCE = SOURCE_DIR / "episode_icon_master.png"

BRAND_NAVY = (5, 8, 23, 255)
RESAMPLING = Image.Resampling.LANCZOS

ANDROID_DENSITIES = {
    "mdpi": 1.0,
    "hdpi": 1.5,
    "xhdpi": 2.0,
    "xxhdpi": 3.0,
    "xxxhdpi": 4.0,
}


def _save_png(image: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, format="PNG", optimize=True)


def _clean_mark() -> Image.Image:
    """Crop by strong alpha while retaining the source antialiasing."""

    image = Image.open(MARK_SOURCE).convert("RGBA")
    alpha = image.getchannel("A")
    strong_alpha = alpha.point(lambda value: 255 if value >= 96 else 0)
    bbox = strong_alpha.getbbox()
    if bbox is None:
        raise RuntimeError(f"No visible logo pixels found in {MARK_SOURCE}")

    padding = max(8, round(max(image.size) * 0.01))
    left = max(0, bbox[0] - padding)
    top = max(0, bbox[1] - padding)
    right = min(image.width, bbox[2] + padding)
    bottom = min(image.height, bbox[3] + padding)
    cropped = image.crop((left, top, right, bottom))

    # Remove only effectively invisible generation noise. The original edge
    # antialiasing remains intact for smooth downsampling.
    cleaned_alpha = cropped.getchannel("A").point(
        lambda value: 0 if value < 8 else value,
    )
    cropped.putalpha(cleaned_alpha)
    return cropped


def _fit_mark(mark: Image.Image, canvas_size: int, visible_fraction: float) -> Image.Image:
    target = round(canvas_size * visible_fraction)
    scale = min(target / mark.width, target / mark.height)
    size = (
        max(1, round(mark.width * scale)),
        max(1, round(mark.height * scale)),
    )
    return mark.resize(size, RESAMPLING)


def _mark_canvas(
    mark: Image.Image,
    size: int,
    visible_fraction: float,
    background: tuple[int, int, int, int] = (0, 0, 0, 0),
) -> Image.Image:
    canvas = Image.new("RGBA", (size, size), background)
    fitted = _fit_mark(mark, size, visible_fraction)
    canvas.alpha_composite(
        fitted,
        ((size - fitted.width) // 2, (size - fitted.height) // 2),
    )
    return canvas


def _regular_icon_master() -> Image.Image:
    image = Image.open(ICON_SOURCE).convert("RGBA")
    mask = Image.new("L", image.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, image.width - 1, image.height - 1),
        radius=round(image.width * 0.20),
        fill=255,
    )
    image.putalpha(mask)
    return image


def _round_icon(mark: Image.Image, size: int) -> Image.Image:
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    ImageDraw.Draw(canvas).ellipse((0, 0, size - 1, size - 1), fill=BRAND_NAVY)
    fitted = _fit_mark(mark, size, 0.60)
    canvas.alpha_composite(
        fitted,
        ((size - fitted.width) // 2, (size - fitted.height) // 2),
    )
    return canvas


def generate() -> list[Path]:
    mark = _clean_mark()
    regular_master = _regular_icon_master()
    generated: list[Path] = []

    in_app_mark = _mark_canvas(mark, 512, 0.90)
    in_app_path = ROOT / "assets" / "branding" / "episode_mark.png"
    _save_png(in_app_mark, in_app_path)
    generated.append(in_app_path)

    android_res = ROOT / "android" / "app" / "src" / "main" / "res"
    for density, scale in ANDROID_DENSITIES.items():
        launcher_size = round(48 * scale)
        mipmap = android_res / f"mipmap-{density}"

        launcher_path = mipmap / "ic_launcher.png"
        _save_png(regular_master.resize((launcher_size, launcher_size), RESAMPLING), launcher_path)
        generated.append(launcher_path)

        round_path = mipmap / "ic_launcher_round.png"
        _save_png(_round_icon(mark, launcher_size), round_path)
        generated.append(round_path)

        adaptive_size = round(108 * scale)
        foreground_path = android_res / f"drawable-{density}" / "ic_launcher_foreground.png"
        _save_png(_mark_canvas(mark, adaptive_size, 0.58), foreground_path)
        generated.append(foreground_path)

        splash_size = round(192 * scale)
        splash_path = android_res / f"drawable-{density}" / "launch_image.png"
        _save_png(_mark_canvas(mark, splash_size, 0.49), splash_path)
        generated.append(splash_path)

    web = ROOT / "web"
    regular_outputs = {
        web / "favicon.png": 32,
        web / "apple-touch-icon.png": 180,
        web / "icons" / "Icon-192.png": 192,
        web / "icons" / "Icon-512.png": 512,
    }
    for path, size in regular_outputs.items():
        _save_png(regular_master.resize((size, size), RESAMPLING), path)
        generated.append(path)

    for size in (192, 512):
        path = web / "icons" / f"Icon-maskable-{size}.png"
        _save_png(_mark_canvas(mark, size, 0.58, BRAND_NAVY), path)
        generated.append(path)

    web_mark_path = web / "icons" / "episode-mark.png"
    _save_png(_mark_canvas(mark, 256, 0.90), web_mark_path)
    generated.append(web_mark_path)

    windows_icon = regular_master.resize((1024, 1024), RESAMPLING)
    windows_path = ROOT / "windows" / "runner" / "resources" / "app_icon.ico"
    windows_path.parent.mkdir(parents=True, exist_ok=True)
    windows_icon.save(
        windows_path,
        format="ICO",
        sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)],
    )
    generated.append(windows_path)

    return generated


if __name__ == "__main__":
    outputs = generate()
    print(f"Generated {len(outputs)} Episode brand assets.")
    for output in outputs:
        print(output.relative_to(ROOT))
