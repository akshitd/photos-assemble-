#!/bin/bash
# photos_assemble.sh
# Gathers ALL photos from the current directory (or a given folder),
# including photos sitting directly in that folder AND in any nested
# subfolders, and moves them all into a new "Photos Assemble" folder.
# Handles filename conflicts by appending a counter suffix.
#
# Usage:
#   ./photos_assemble.sh               # uses current directory
#   ./photos_assemble.sh <folder>      # uses given folder

set -euo pipefail

# ── Config ────────────────────────────────────────────────────────────────────
DEST_NAME="Photos Assemble"
PHOTO_EXTENSIONS=("jpg" "jpeg" "png" "gif" "bmp" "tiff" "tif" "webp" "heic" "heif" "raw" "cr2" "cr3" "nef" "arw" "dng" "orf" "rw2" "pef")

# ── Source folder: argument or current directory ──────────────────────────────
SOURCE="${1:-$(pwd)}"

if [[ ! -d "$SOURCE" ]]; then
  echo "Error: '$SOURCE' is not a directory."
  exit 1
fi

ROOT="$SOURCE/$DEST_NAME"
mkdir -p "$ROOT"

echo "Searching in:  $SOURCE"
echo "Destination:   $ROOT"
echo ""

# ── Build find expression for all photo extensions ────────────────────────────
FIND_ARGS=()
first=true
for ext in "${PHOTO_EXTENSIONS[@]}"; do
  if $first; then
    FIND_ARGS+=(-iname "*.${ext}")
    first=false
  else
    FIND_ARGS+=(-o -iname "*.${ext}")
  fi
done

# ── Move photos ───────────────────────────────────────────────────────────────
moved=0

while IFS= read -r -d '' file; do
  # Skip files already inside the destination folder
  dir="$(dirname "$file")"
  if [[ "$dir" == "$ROOT" ]]; then
    continue
  fi

  filename="$(basename "$file")"
  dest="$ROOT/$filename"

  # Resolve conflicts by appending _1, _2, … before the extension
  if [[ -e "$dest" ]]; then
    name="${filename%.*}"
    ext_part="${filename##*.}"
    counter=1
    while [[ -e "$ROOT/${name}_${counter}.${ext_part}" ]]; do
      ((counter++))
    done
    dest="$ROOT/${name}_${counter}.${ext_part}"
    echo "Conflict: '$filename' → '$(basename "$dest")'"
  fi

  cp "$file" "$dest"
  echo "Moved: $file → $dest"
  ((moved++))

# -mindepth 1 includes files in SOURCE itself, not just subfolders
done < <(find "$SOURCE" -mindepth 1 \( "${FIND_ARGS[@]}" \) -print0)

echo ""
echo "Done. Moved: $moved file(s) → '$DEST_NAME'"
