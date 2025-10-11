#!/bin/bash
set -euo pipefail
DIR="${1:-.}"
CHECKSUM_FILE="${2:-xx-z-sums.txt}"
SKIP_SCRIPTS="${3:-xx-update.sh xx-verify.sh}"
cd "$DIR"
if [ ! -f "$CHECKSUM_FILE" ]; then
  echo "Checksum file not found: $CHECKSUM_FILE" >&2
  exit 2
fi
TMP_SORTED="$(mktemp)"
echo "Verifying files against $CHECKSUM_FILE"
cleanup(){ rm -f "$TMP_SORTED"; }
trap cleanup EXIT
cp "$CHECKSUM_FILE" "$TMP_SORTED"
OK_COUNT=0
MISMATCH_COUNT=0
MISSING_COUNT=0
while IFS= read -r line; do
  if [[ ! $line =~ ^[a-f0-9]{64}\ \ (.*)$ ]]; then
    continue
  fi
  hash="${line:0:64}"
  path="${line:66}"
  skip_it=0
  for s in $SKIP_SCRIPTS; do
    [ "$path" = "$s" ] && { skip_it=1; break; }
  done
  [ "$skip_it" -eq 1 ] && continue
  if [ ! -e "$path" ]; then
    MISSING_COUNT=$((MISSING_COUNT+1))
    echo "MISSING: $path"
    continue
  fi
  actual="$(sha256sum -- "$path" | awk '{print $1}')"
  if [ "$actual" != "$hash" ]; then
    MISMATCH_COUNT=$((MISMATCH_COUNT+1))
    echo "BAD: $path"
    echo "  expected: $hash"
    echo "  actual:   $actual"
  else
    OK_COUNT=$((OK_COUNT+1))
    echo "OK: $path"
  fi
done < "$TMP_SORTED"
echo "========== FINISHED =========="
echo "OK files: $OK_COUNT"
echo "BAD files: $MISMATCH_COUNT"
echo "MISSING files: $MISSING_COUNT"
