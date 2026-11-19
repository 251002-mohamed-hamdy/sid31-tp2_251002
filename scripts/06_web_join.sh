#!/usr/bin/env bash
# Task 2.2 - join the client class -> data/clean/web_enriched.csv, results/isp_client_class.csv
set -euo pipefail
cd "$(dirname "$0")/.."
export LC_ALL=C
# 1st file (NR==FNR): the lookup, kept in memory. 2nd file: the records, in order.
awk -F, -v OFS=, '
  NR == FNR { if (FNR > 1) cls[$1] = $2; next }
  FNR == 1  { print $0, "client_class"; next }
  { print $0, (($5 in cls) ? cls[$5] : "unmapped") }
' data/ref/client_class.csv data/clean/web_clean.csv > data/clean/web_enriched.csv

{ echo "isp,client_class,records"
  tail -n +2 data/clean/web_enriched.csv | awk -F, '{ c[$3 "," $6]++ } END { for (k in c) print k "," c[k] }' \
    | sort -t, -k1,1 -k2,2
} > results/isp_client_class.csv

echo "== rows: web_clean $(wc -l < data/clean/web_clean.csv), web_enriched $(wc -l < data/clean/web_enriched.csv)"
echo "== records per class"
tail -n +2 data/clean/web_enriched.csv | cut -d, -f6 | sort | uniq -c
echo "== unmapped clients (count client)"
tail -n +2 data/clean/web_enriched.csv | awk -F, '$6 == "unmapped" { print $5 }' | sort | uniq -c | sort -k1,1nr -k2
