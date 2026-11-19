#!/usr/bin/env bash
# Task 1.4 - clean the Hassaniya corpus -> data/clean/hass_base.tsv, hass_completed.tsv
set -euo pipefail
cd "$(dirname "$0")/.."
export LC_ALL=C
mkdir -p data/clean

# csv2tsv WANTED_FIELDS KEEP_FIELDS FILE
# A small CSV reader in plain awk (works with gawk and mawk): it walks each line
# character by character, so a comma inside quotes stays in its field and a
# doubled "" inside quotes becomes one ".
csv2tsv() {
  tr -d '\r' < "$3" | awk -v want="$1" -v keep="$2" -v src="$3" '
    function csvsplit(s, f,    n, i, c, q, fld) {
      n = 0; q = 0; fld = ""
      for (i = 1; i <= length(s); i++) {
        c = substr(s, i, 1)
        if (q) {
          if (c == "\"") { if (substr(s, i + 1, 1) == "\"") { fld = fld "\""; i++ } else q = 0 }
          else fld = fld c
        } else if (c == "\"") q = 1
        else if (c == ",") { f[++n] = fld; fld = "" }
        else fld = fld c
      }
      f[++n] = fld
      return n
    }
    {
      n = csvsplit($0, f)
      if (n != want) { printf "%s: line %d has %d fields, expected %d\n", src, NR, n, want > "/dev/stderr"; exit 1 }
      out = ""
      for (i = 1; i <= keep; i++) {
        x = f[i]; gsub(/^[ \t]+|[ \t]+$/, "", x)          # trim both ends
        if (x ~ /\t/) { printf "%s: line %d: tab inside a field\n", src, NR > "/dev/stderr"; exit 1 }
        out = out (i > 1 ? "\t" : "") x
      }
      print out
    }'
}

csv2tsv 3 3 data/raw/dah_d1.csv        > data/clean/hass_base.tsv
csv2tsv 4 3 data/raw/dah_completed.csv > data/clean/hass_completed.tsv

# The sheet calls the 4th column of the completed file "empty". We drop it, but we
# report what it really holds (a plain split is enough: it is the last field).
echo "== dah_completed.csv, values of the dropped 4th column (count value)"
tr -d '\r' < data/raw/dah_completed.csv | awk -F, 'NR > 1 { v = $NF; print (v == "" ? "(empty)" : v) }' | sort | uniq -c

echo "== fields per line with the quote-aware reader"
for f in data/clean/hass_base.tsv data/clean/hass_completed.tsv; do
  echo "$f: $(awk -F'\t' '{print NF}' "$f" | sort | uniq -c | tr -s ' ' | tr '\n' ';')"
done
echo "dah_d3.csv: $(csv2tsv 3 3 data/raw/dah_d3.csv | awk -F'\t' '{print NF}' | sort | uniq -c | tr -s ' ' | tr '\n' ';')"
