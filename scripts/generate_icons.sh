#!/bin/bash
# Generate PNG icons from SVG at multiple sizes
# Usage: generate_icons.sh <input.svg> <output_dir>
set -e

INPUT="$1"
OUTDIR="$2"

for sz in 16 32 48 64 128 256 512 1024; do
    convert "$INPUT" -resize "${sz}x${sz}" "$OUTDIR/calctron-${sz}.png"
done
