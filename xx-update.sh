#!/bin/bash
set -euo pipefail
ROOT_DIR="${1:-.}"
CHECKSUM_FILE="${2:-xx-z-sums.txt}"
SKIP_SCRIPTS="${3:-xx-update.sh xx-verify.sh}"
cd "$ROOT_DIR"
ROOT_DIR="$(pwd)"
TMP_FILES="$(mktemp)"
TMP_EXIST="$(mktemp)"
TMP_OUT="$(mktemp)"
echo "Updating $CHECKSUM_FILE"
cleanup(){ rm -f "$TMP_FILES" "$TMP_EXIST" "$TMP_OUT"; }
trap cleanup EXIT
find . -type f -print0 \
  | while IFS= read -r -d '' f; do
      f="${f#./}"
      [ "$f" = "$CHECKSUM_FILE" ] && continue
      for s in $SKIP_SCRIPTS; do
        [ "$f" = "$s" ] && continue 2
      done
      [[ "$f" == *\\* ]] && continue
      printf '%s\n' "$f"
    done | sort > "$TMP_FILES"
if [ -f "$CHECKSUM_FILE" ]; then
  sort -k2 "$CHECKSUM_FILE" > "$TMP_EXIST"
else
  : > "$TMP_EXIST"
fi
declare -A EXIST
while IFS= read -r line; do
  if [[ $line =~ ^[a-f0-9]{64}\ \ (.*)$ ]]; then
    hash="${line:0:64}"
    path="${line:66}"
    EXIST["$path"]="$hash"
  fi
done < "$TMP_EXIST"
ADDED=0
REUSED=0
exec 3<"$TMP_FILES"
while IFS= read -r path <&3; do
  if [ -n "${EXIST[$path]:-}" ] && [ -f "$path" ]; then
    printf '%s  %s\n' "${EXIST[$path]}" "$path" >> "$TMP_OUT"
    REUSED=$((REUSED+1))
  else
    sha256sum -- "$path" >> "$TMP_OUT"
    ADDED=$((ADDED+1))
  fi
done
exec 3<&-
sort -k2 "$TMP_OUT" -o "$TMP_OUT"
MISSING_REMOVED=0
while IFS= read -r line; do
  path="${line:66}"
  printf '%s\n' "$path"
done < "$TMP_EXIST" | sort > "${TMP_EXIST}.paths"
cp "$TMP_FILES" "${TMP_FILES}.paths"
MISSING_REMOVED="$(comm -23 "${TMP_EXIST}.paths" "${TMP_FILES}.paths" | wc -l | tr -d '[:space:]')"
rm -f "${TMP_EXIST}.paths" "${TMP_FILES}.paths"
mv "$TMP_OUT" "$CHECKSUM_FILE"
echo "========== FINISHED =========="
echo "Added: $ADDED"
echo "Reused (skipped recalculation): $REUSED"
echo "Removed entries for missing files: $MISSING_REMOVED"
