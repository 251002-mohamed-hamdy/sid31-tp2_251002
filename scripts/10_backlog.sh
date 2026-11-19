#!/usr/bin/env bash
# Task 2.5 (b) - translation backlog -> data/clean/hass_backlog.tsv, results/backlog_status.csv
set -euo pipefail
cd "$(dirname "$0")/.."
export LC_ALL=C
out=data/clean/hass_backlog.tsv

# Each contribution file is read on its own (no plain cat: d2..d5 have no final
# newline, so cat would glue the next header to the last row).
for x in 2 3 4 5; do
  tr -d '\r' < "data/raw/dah_d$x.csv" | awk '
    function csvsplit(s, f,    n, i, c, q, fld) {
      n = 0; q = 0; fld = ""
      for (i = 1; i <= length(s); i++) {
        c = substr(s, i, 1)
        if (q) { if (c == "\"") { if (substr(s, i + 1, 1) == "\"") { fld = fld "\""; i++ } else q = 0 } else fld = fld c }
        else if (c == "\"") q = 1
        else if (c == ",") { f[++n] = fld; fld = "" }
        else fld = fld c }
      f[++n] = fld; return n }
    NR > 1 { n = csvsplit($0, f)
      if (n != 3) { printf "d%s line %d: %d fields\n", x, NR, n > "/dev/stderr"; exit 1 }
      for (i = 1; i <= 3; i++) { gsub(/^[ \t]+|[ \t]+$/, "", f[i]); if (f[i] ~ /\t/) exit 1 }
      print f[1] "\t" f[2] "\t" f[3] }' x="$x"
done > results/.contrib.tmp

{ printf 'english\thassaniya_ar\thassaniya_en\tstatus\n'
  awk -F'\t' -v OFS='\t' '
    FILENAME == ARGV[1] { if (FNR > 1) base[$1] = 1; next }
    FILENAME == ARGV[2] { if (FNR > 1 && !($1 in done)) { done[$1] = 1; ar[$1] = $2; en[$1] = $3 }; next }
    { if ($1 in base)                 print $1, $2, $3, "in_base"
      else if ($1 in done)            print $1, ar[$1], en[$1], "filled"
      else if ($2 != "" && $3 != "")  print $1, $2, $3, "prefilled"
      else                            print $1, $2, $3, "todo" }
  ' data/clean/hass_base.tsv data/clean/hass_completed.tsv results/.contrib.tmp
} > "$out"
rm -f results/.contrib.tmp

{ echo "status,rows"
  tail -n +2 "$out" | cut -f4 | sort | uniq -c | awk '{ print $2 "," $1 }' | sort -t, -k1,1
} > results/backlog_status.csv
cat results/backlog_status.csv
echo "backlog rows: $(( $(wc -l < "$out") - 1 ))"
