#!/usr/bin/env bash
# Task 2.3 - daily file for the four national operators -> results/web_daily_isp_<S>.csv
set -euo pipefail
cd "$(dirname "$0")/.."
export LC_ALL=C
: "${S:?export S=<your student number> first}"
out=results/web_daily_isp_$S.csv
awk -F, '
  { if (NR > 1) { k = $3 "," $1; rec[k]++
                if ($4 == "iOS" || $4 == "Android") mob[k]++
                if ($6 == "bot") bot[k]++ }
              next }
  END {
    print "isp,date,records,mobile,bot,busy_flag"
    split("CHINGUITEL MATTEL MAURITEL RIMATEL", isps, " ")
    for (i = 1; i <= 4; i++) {
      isp = isps[i]
      # the 31 daily counts of this operator (0 when there is no record)
      for (d = 1; d <= 31; d++) { day[d] = sprintf("2025-10-%02d", d); v[d] = rec[isp "," day[d]] + 0 }
      # sort a copy in ascending order (insertion sort: plain awk has no sort function)
      for (a = 1; a <= 31; a++) s[a] = v[a]
      for (a = 2; a <= 31; a++) { x = s[a]; b = a - 1; while (b >= 1 && s[b] > x) { s[b + 1] = s[b]; b-- } s[b + 1] = x }
      # nearest rank: ceil(0.9 n), computed with integers to avoid 0.9*n rounding errors
      n = 31; r = int((9 * n + 9) / 10); thr = s[r]
      printf "threshold %s: rank %d of %d, p90 = %d records\n", isp, r, n, thr > "/dev/stderr"
      for (d = 1; d <= 31; d++) {
        k = isp "," day[d]
        printf "%s,%s,%d,%d,%d,%d\n", isp, day[d], v[d], mob[k] + 0, bot[k] + 0, (v[d] >= thr) ? 1 : 0
      }
    }
  }' data/clean/web_enriched.csv > "$out"
echo "$out: $(( $(wc -l < "$out") - 1 )) data rows"
echo "== busy days of each operator"
awk -F, 'NR > 1 && $6 == 1 { print $1, $2, $3 }' "$out"
