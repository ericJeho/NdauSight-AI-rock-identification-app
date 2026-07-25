#!/usr/bin/env python3
"""
Generate NdauSight AI brand assets (launcher icon + splash logo).

Produces original artwork — a faceted quartz-point crystal in the app's
gold-on-slate palette, framed by a subtle "scan" reticle to evoke AI
detection. Outputs the PNGs consumed by flutter_launcher_icons and
flutter_native_splash.

Run:  python3 tool/generate_brand_assets.py
Deps: cairosvg  (pip install cairosvg)
"""
import os
import cairosvg

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
ICON_DIR = os.path.join(ROOT, "assets", "icon")
SPLASH_DIR = os.path.join(ROOT, "assets", "splash")
os.makedirs(ICON_DIR, exist_ok=True)
os.makedirs(SPLASH_DIR, exist_ok=True)

# --- Palette -----------------------------------------------------------------
SLATE_TOP = "#28353F"
SLATE_BOT = "#161C24"
GOLD_LIGHT = "#F0D26B"
GOLD = "#C9A227"
GOLD_MID = "#D4AF37"
GOLD_DARK = "#A8801A"
GOLD_DARKER = "#886611"
EDGE = "#6E540E"
RETICLE = "#E6C866"


def crystal_group() -> str:
    """The faceted crystal + reticle, drawn in a 1024x1024 coordinate space,
    centred on x=512. Returned as a <g> so it can be scaled/placed by callers."""
    # Vertical facet edges of the hexagonal prism (front-on view)
    xOL, xIL, xIR, xOR = 432, 478, 546, 592  # outer-left, inner-left, inner-right, outer-right
    yTerm = 424          # where termination meets the body
    yApex = 300          # crystal tip
    ySide = 706          # bottom of the outer faces
    yCtr = 742           # bottom point of the centre face

    return f"""
  <g>
    <!-- soft ground shadow -->
    <ellipse cx="512" cy="762" rx="150" ry="26" fill="#000000" opacity="0.28"/>

    <!-- termination (three triangular facets meeting at the apex) -->
    <polygon points="{xOL},{yTerm} {xIL},{yTerm} 512,{yApex}" fill="{GOLD_DARK}"/>
    <polygon points="{xIL},{yTerm} {xIR},{yTerm} 512,{yApex}" fill="url(#gGold)"/>
    <polygon points="{xIR},{yTerm} {xOR},{yTerm} 512,{yApex}" fill="{GOLD_MID}"/>

    <!-- body: three vertical faces -->
    <polygon points="{xOL},{yTerm} {xIL},{yTerm} {xIL},{ySide} {xOL},{ySide}" fill="{GOLD_DARK}"/>
    <polygon points="{xIL},{yTerm} {xIR},{yTerm} {xIR},{ySide} 512,{yCtr} {xIL},{ySide}" fill="url(#gGoldV)"/>
    <polygon points="{xIR},{yTerm} {xOR},{yTerm} {xOR},{ySide} {xIR},{ySide}" fill="{GOLD}"/>

    <!-- specular highlight on the centre facet -->
    <polygon points="{xIL+10},{yTerm+14} {xIL+34},{yTerm+14} 512,{ySide-40} 512,{yCtr-30}"
             fill="#FFFFFF" opacity="0.16"/>

    <!-- crisp facet edges -->
    <g stroke="{EDGE}" stroke-width="5" stroke-linejoin="round" fill="none" opacity="0.55">
      <polygon points="{xOL},{yTerm} {xOR},{yTerm} {xOR},{ySide} {xIR},{ySide} 512,{yCtr} {xIL},{ySide} {xOL},{ySide}"/>
      <polyline points="{xOL},{yTerm} 512,{yApex} {xOR},{yTerm}"/>
      <line x1="{xIL}" y1="{yTerm}" x2="512" y2="{yApex}"/>
      <line x1="{xIR}" y1="{yTerm}" x2="512" y2="{yApex}"/>
      <line x1="{xIL}" y1="{yTerm}" x2="{xIL}" y2="{ySide}"/>
      <line x1="{xIR}" y1="{yTerm}" x2="{xIR}" y2="{ySide}"/>
    </g>

    <!-- AI scan reticle: four corner brackets framing the crystal -->
    <g stroke="{RETICLE}" stroke-width="16" stroke-linecap="round" fill="none" opacity="0.9">
      <path d="M320 372 L320 320 L372 320"/>
      <path d="M704 320 L756 320 L756 372"/>
      <path d="M320 700 L320 752 L372 752"/>
      <path d="M704 752 L756 752 L756 700"/>
    </g>
  </g>"""


DEFS = f"""
  <defs>
    <linearGradient id="gBg" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="{SLATE_TOP}"/>
      <stop offset="1" stop-color="{SLATE_BOT}"/>
    </linearGradient>
    <linearGradient id="gGold" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="{GOLD_LIGHT}"/>
      <stop offset="1" stop-color="{GOLD}"/>
    </linearGradient>
    <linearGradient id="gGoldV" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="{GOLD_LIGHT}"/>
      <stop offset="1" stop-color="{GOLD_DARK}"/>
    </linearGradient>
    <radialGradient id="gGlow" cx="0.5" cy="0.42" r="0.6">
      <stop offset="0" stop-color="{GOLD}" stop-opacity="0.22"/>
      <stop offset="1" stop-color="{GOLD}" stop-opacity="0"/>
    </radialGradient>
  </defs>
"""


def full_icon_svg() -> str:
    """Full-bleed launcher icon (used for iOS + legacy Android)."""
    return f"""<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">
  {DEFS}
  <rect width="1024" height="1024" fill="url(#gBg)"/>
  <circle cx="512" cy="512" r="380" fill="url(#gGlow)"/>
  {crystal_group()}
</svg>"""


def foreground_svg() -> str:
    """Adaptive-icon foreground: crystal only, transparent, padded into the
    launcher safe zone (~66% of the canvas)."""
    return f"""<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">
  {DEFS}
  <g transform="translate(512,512) scale(0.66) translate(-512,-512)">
    {crystal_group()}
  </g>
</svg>"""


def splash_svg() -> str:
    """Splash logo: crystal on transparent, sized for centre placement."""
    return f"""<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">
  {DEFS}
  <g transform="translate(512,512) scale(0.82) translate(-512,-512)">
    {crystal_group()}
  </g>
</svg>"""


def render(svg: str, out_png: str, size: int):
    cairosvg.svg2png(
        bytestring=svg.encode("utf-8"),
        write_to=out_png,
        output_width=size,
        output_height=size,
    )
    print(f"  wrote {os.path.relpath(out_png, ROOT)} ({size}x{size})")


def main():
    # Save source SVGs for future editing
    with open(os.path.join(ICON_DIR, "icon.svg"), "w") as f:
        f.write(full_icon_svg())
    with open(os.path.join(ICON_DIR, "icon_foreground.svg"), "w") as f:
        f.write(foreground_svg())
    with open(os.path.join(SPLASH_DIR, "splash.svg"), "w") as f:
        f.write(splash_svg())

    print("Rendering brand assets...")
    render(full_icon_svg(), os.path.join(ICON_DIR, "icon.png"), 1024)
    render(foreground_svg(), os.path.join(ICON_DIR, "icon_foreground.png"), 1024)
    render(splash_svg(), os.path.join(SPLASH_DIR, "splash.png"), 1152)
    # A compact preview strip is handy for design review
    print("Done.")


if __name__ == "__main__":
    main()
