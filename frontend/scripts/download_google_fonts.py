#!/usr/bin/env python3
"""Download static Latin TTFs for google_fonts asset bundling."""

from __future__ import annotations

import pathlib
import urllib.request

OUT = pathlib.Path(__file__).resolve().parents[1] / "assets" / "google_fonts"

FILES = {
    "Baloo2-Regular.ttf": "https://cdn.jsdelivr.net/fontsource/fonts/baloo-2@5.2.5/latin-400-normal.ttf",
    "Baloo2-SemiBold.ttf": "https://cdn.jsdelivr.net/fontsource/fonts/baloo-2@5.2.5/latin-600-normal.ttf",
    "Baloo2-Bold.ttf": "https://cdn.jsdelivr.net/fontsource/fonts/baloo-2@5.2.5/latin-700-normal.ttf",
    "Baloo2-ExtraBold.ttf": "https://cdn.jsdelivr.net/fontsource/fonts/baloo-2@5.2.5/latin-800-normal.ttf",
    "Nunito-Regular.ttf": "https://cdn.jsdelivr.net/fontsource/fonts/nunito@5.2.5/latin-400-normal.ttf",
    "Nunito-Medium.ttf": "https://cdn.jsdelivr.net/fontsource/fonts/nunito@5.2.5/latin-500-normal.ttf",
    "Nunito-SemiBold.ttf": "https://cdn.jsdelivr.net/fontsource/fonts/nunito@5.2.5/latin-600-normal.ttf",
    "Nunito-Bold.ttf": "https://cdn.jsdelivr.net/fontsource/fonts/nunito@5.2.5/latin-700-normal.ttf",
    "Nunito-ExtraBold.ttf": "https://cdn.jsdelivr.net/fontsource/fonts/nunito@5.2.5/latin-800-normal.ttf",
    "Inter-Regular.ttf": "https://cdn.jsdelivr.net/fontsource/fonts/inter@5.2.5/latin-400-normal.ttf",
    "Inter-Medium.ttf": "https://cdn.jsdelivr.net/fontsource/fonts/inter@5.2.5/latin-500-normal.ttf",
    "Inter-SemiBold.ttf": "https://cdn.jsdelivr.net/fontsource/fonts/inter@5.2.5/latin-600-normal.ttf",
}


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for name, url in FILES.items():
        req = urllib.request.Request(url, headers={"User-Agent": "JacalorIA"})
        data = urllib.request.urlopen(req, timeout=60).read()
        (OUT / name).write_bytes(data)
        print(f"OK {name} ({len(data)} bytes)")


if __name__ == "__main__":
    main()
