#!/usr/bin/env bash
# Task 1.1 - inventory of the raw files -> results/inventory.tsv
set -euo pipefail
cd "$(dirname "$0")/.."
export LC_ALL=C
mkdir -p results
out=results/inventory.tsv
printf 'file\trecords\tfields_header\tlines_other_fields\tcrlf_lines\tfinal_newline\n' > "$out"
for f in data/raw/*.csv; do
  name=$(basename "$f")
  # awk counts the last line even without a final newline: NR-1 = data rows
  records=$(awk 'END{print NR-1}' "$f")
  fields_header=$(awk -F, 'NR==1{print NF; exit}' "$f")
  lines_other=$(awk -F, 'NR==1{h=NF} NF!=h{c++} END{print c+0}' "$f")
  # CR counted on raw bytes with tr: gawk on Windows (MSYS) reads in text mode
  # and silently drops \r, so awk '/\r/' would find none there.
  crlf=$(tr -dc '\r\n' < "$f" | tr '\r' 'R' | awk '/R/{c++} END{print c+0}')
  # $(...) strips a trailing newline: empty result = the last byte was \n
  if [ -z "$(tail -c 1 "$f")" ]; then nl=yes; else nl=no; fi
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$name" "$records" "$fields_header" "$lines_other" "$crlf" "$nl" >> "$out"
done
cat "$out"
