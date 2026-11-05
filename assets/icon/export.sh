#!/usr/bin/env bash
set -euo pipefail

icon_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v magick >/dev/null 2>&1; then
  echo 'ImageMagick 7 is required: magick was not found.' >&2
  exit 1
fi

# Render the vector at 4x resolution before downsampling for clean small edges.
for size in 1024 512 256; do
  output="${icon_dir}/mihomote-${size}.png"
  if [[ "${size}" == 1024 ]]; then
    output="${icon_dir}/mihomote.png"
  fi
  magick -background none -density 384 "${icon_dir}/mihomote.svg" \
    -filter Lanczos -resize "${size}x${size}" \
    -colorspace sRGB -depth 8 -strip "PNG32:${output}"
done

# System-masked launcher icons need an opaque, full-bleed background.
sed 's/rx="224"/rx="0"/' "${icon_dir}/mihomote.svg" |
  magick -background none -density 384 svg:- \
    -filter Lanczos -resize 1024x1024 \
    -colorspace sRGB -depth 8 -strip "PNG24:${icon_dir}/mihomote-square.png"
