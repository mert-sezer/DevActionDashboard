#!/usr/bin/env bash
set -euo pipefail

# Photographs a live Dev Action Dashboard window for README media.
# Requires Screen Capture permission for the calling terminal (screencapture -R).
#
# Usage:
#   ./Scripts/capture-readme-media.sh

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

APP="${APP:-$ROOT/build/DerivedData/Build/Products/Release/DevActionDashboard.app}"
SYNC="/tmp/dad-readme-capture"
RAW="$ROOT/docs/images/raw"
OUT="$ROOT/docs/images"

if [[ ! -d "$APP" ]]; then
  echo "Building Release app…"
  xcodebuild \
    -project DevActionDashboard.xcodeproj \
    -scheme DevActionDashboard \
    -configuration Release \
    -destination 'platform=macOS' \
    -derivedDataPath "$ROOT/build/DerivedData" \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_ALLOWED=YES \
    build >/dev/null
fi

mkdir -p "$RAW" "$OUT"
rm -rf "$SYNC"
mkdir -p "$SYNC"

killall DevActionDashboard >/dev/null 2>&1 || true
sleep 0.6

window_rect() {
  swift -e '
import CoreGraphics
import Foundation
let info = CGWindowListCopyWindowInfo([.excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] ?? []
let matches = info.filter { w in
  let owner = (w[kCGWindowOwnerName as String] as? String ?? "").lowercased()
  let layer = (w[kCGWindowLayer as String] as? NSNumber)?.intValue ?? 0
  return layer == 0 && (owner.contains("devaction") || owner.contains("dev action"))
}
guard let w = matches.max(by: { a, b in
  let ab = a[kCGWindowBounds as String] as? [String: Any] ?? [:]
  let bb = b[kCGWindowBounds as String] as? [String: Any] ?? [:]
  let aw = (ab["Width"] as? NSNumber)?.doubleValue ?? 0
  let ah = (ab["Height"] as? NSNumber)?.doubleValue ?? 0
  let bw = (bb["Width"] as? NSNumber)?.doubleValue ?? 0
  let bh = (bb["Height"] as? NSNumber)?.doubleValue ?? 0
  return (aw * ah) < (bw * bh)
}), let bounds = w[kCGWindowBounds as String] as? [String: Any] else {
  exit(1)
}
let x = Int((bounds["X"] as? NSNumber)?.doubleValue.rounded() ?? -1)
let y = Int((bounds["Y"] as? NSNumber)?.doubleValue.rounded() ?? -1)
let width = Int((bounds["Width"] as? NSNumber)?.doubleValue.rounded() ?? 0)
let height = Int((bounds["Height"] as? NSNumber)?.doubleValue.rounded() ?? 0)
if width < 400 || height < 300 { exit(1) }
print("\(x),\(y),\(width),\(height)")
'
}

wait_ready() {
  local name="$1"
  local deadline=$((SECONDS + 25))
  while [[ ! -f "$SYNC/ready-$name" ]]; do
    if (( SECONDS >= deadline )); then
      echo "Timed out waiting for $name" >&2
      return 1
    fi
    sleep 0.15
  done
}

capture() {
  local name="$1"
  local rect
  rect="$(window_rect)"
  echo "Capturing $name @ $rect"
  screencapture -R"$rect" -x "$RAW/$name.png"
}

echo "Launching capture tour…"
DAD_CAPTURE_README=1 DAD_CAPTURE_DIR="$SYNC" \
  "$APP/Contents/MacOS/DevActionDashboard" >"$SYNC/app.log" 2>&1 &
APP_PID=$!
sleep 1.8
if [[ ! -f "$SYNC/boot" ]]; then
  echo "Capture tour did not start in $SYNC"
  echo "pid=$APP_PID"
  ls -la "$SYNC" || true
  cat "$SYNC/app.log" || true
  exit 1
fi
echo "Tour started (pid $APP_PID)"

for name in welcome dashboard system processes network ports docker environment utilities actions palette; do
  wait_ready "$name"
  sleep 0.25
  capture "$name"
done

wait_ready "done" || true

kill "$APP_PID" >/dev/null 2>&1 || true
killall DevActionDashboard >/dev/null 2>&1 || true

echo "Encoding GIF…"
python3 <<'PY'
from pathlib import Path
from PIL import Image

root = Path("/Users/mertsezer/DevActionDashboard/docs/images")
raw = root / "raw"
out = root

order = ["dashboard", "processes", "network", "ports", "utilities", "palette"]
frames = []
for name in order:
    path = raw / f"{name}.png"
    if not path.exists():
        continue
    image = Image.open(path).convert("RGB")
    image.thumbnail((1100, 760), Image.Resampling.LANCZOS)
    frames.append(image)

if not frames:
    raise SystemExit("no frames")

# Adaptive palette keeps the teal UI from banding too hard.
quantized = [frame.quantize(colors=128, method=Image.Quantize.MEDIANCUT) for frame in frames]
quantized[0].save(
    out / "hero.gif",
    save_all=True,
    append_images=quantized[1:],
    duration=1600,
    loop=0,
    optimize=True,
    disposal=2,
)

for name in ["welcome", "dashboard", "processes", "ports", "utilities", "network", "palette", "docker", "environment"]:
    src = raw / f"{name}.png"
    if src.exists():
        img = Image.open(src)
        img.thumbnail((1400, 960), Image.Resampling.LANCZOS)
        img.save(out / f"{name}.png", optimize=True)
PY

if command -v ffmpeg >/dev/null; then
  list="$RAW/gif.txt"
  : > "$list"
  for name in dashboard processes network ports utilities palette dashboard; do
    [[ -f "$RAW/$name.png" ]] || continue
    printf "file '%s'\nduration 1.6\n" "$RAW/$name.png" >> "$list"
  done
  ffmpeg -y -hide_banner -loglevel error -f concat -safe 0 -i "$list" \
    -vf "fps=8,scale=1100:-1:flags=lanczos,split[s0][s1];[s0]palettegen=max_colors=160:stats_mode=diff[p];[s1][p]paletteuse=dither=bayer:bayer_scale=3" \
    "$OUT/hero.gif"
fi

ls -lh "$OUT"/*.{png,gif} 2>/dev/null
echo "Done."
