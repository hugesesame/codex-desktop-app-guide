#!/usr/bin/env bash
#
# README 用のスクリーンショット（PC版・スマホ版）を再生成する。
#
#   ./tools/screenshot.sh
#
# 出力先: assets/screenshot.png / assets/screenshot-mobile.png
# Chrome の場所が違う場合は環境変数で指定する:
#   CHROME="/path/to/chrome" ./tools/screenshot.sh
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INDEX="$ROOT/index.html"
OUT="$ROOT/assets"

CHROME="${CHROME:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
if [[ ! -x "$CHROME" ]]; then
  echo "Chrome が見つかりません: $CHROME" >&2
  echo "CHROME 環境変数で実行ファイルを指定してください。" >&2
  exit 1
fi
[[ -f "$INDEX" ]] || { echo "index.html が見つかりません: $INDEX" >&2; exit 1; }

mkdir -p "$OUT"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

shoot() { # shoot <url> <width> <height> <出力先>
  "$CHROME" --headless --disable-gpu --hide-scrollbars \
    --allow-file-access-from-files --force-device-scale-factor=2 \
    --virtual-time-budget=3000 --window-size="$2,$3" \
    --screenshot="$4" "$1" >/dev/null 2>&1
}

# --- PC版 (1280x800 @2x) ---
shoot "file://$INDEX" 1280 800 "$OUT/screenshot.png"

# --- スマホ版 (390x844 @2x) ---
# ヘッドレス Chrome にはウィンドウ最小幅があり、--window-size=390 を指定しても
# 実際にはより広い幅でレイアウトされ、目次ボタンが画面外へ押し出される。
# iframe で 390px の表示領域を厳密に作ってから撮影する。
cat > "$TMP/frame.html" <<HTML
<!doctype html><meta charset="utf-8">
<style>html,body{margin:0;padding:0;background:#000}
iframe{width:390px;height:844px;border:0;display:block}</style>
<iframe src="file://$INDEX" scrolling="no"></iframe>
HTML
shoot "file://$TMP/frame.html" 390 844 "$OUT/screenshot-mobile.png"

for f in "$OUT/screenshot.png" "$OUT/screenshot-mobile.png"; do
  [[ -s "$f" ]] || { echo "生成に失敗しました: $f" >&2; exit 1; }
  printf '%s  %s\n' "$(du -h "$f" | cut -f1)" "${f#"$ROOT"/}"
done
echo "完了しました。"
