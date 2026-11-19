#!/usr/bin/env bash
# Task 1.2 - clean the web sample -> data/clean/web_clean.csv
# Every field of the source is quoted and no field contains a comma
# (checked: every line has exactly 6 comma-separated fields), so a plain
# split on commas is safe. The script stops if that ever changes.
set -euo pipefail
cd "$(dirname "$0")/.."
export LC_ALL=C
mkdir -p data/clean
awk -F, '
  NF != 6 { printf "web: line %d has %d fields, expected 6\n", NR, NF > "/dev/stderr"; exit 1 }
  { gsub(/"/, "", $1); gsub(/"/, "", $2); gsub(/"/, "", $3); gsub(/"/, "", $4); gsub(/"/, "", $5)
    print $1 "," $2 "," $3 "," $4 "," $5 }        # column 6 (hash_src_ip) is never printed
' data/raw/web_2025-10.csv > data/clean/web_clean.csv
echo "web_clean.csv: $(wc -l < data/clean/web_clean.csv) lines"
head -n 1 data/clean/web_clean.csv
