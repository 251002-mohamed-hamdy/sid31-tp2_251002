#!/usr/bin/env bash
# Task 2.1 - profile of the web sample -> results/web_profile.txt, results/daily_os_counts.csv
set -euo pipefail
cd "$(dirname "$0")/.."
export LC_ALL=C
in=data/clean/web_clean.csv
out=results/web_profile.txt
mkdir -p results

awk -F, '
  NR == 1 { next }
  { n++
    os[$4]++                                  # the empty string is a key too
    if ($2 == "") nocity++
    if ($4 != "") known++
    if ($4 == "iOS") ios++
    if ($4 == "Android") andr++ }
  END {
    nos = 0; for (k in os) nos++
    printf "records: %d\n", n
    printf "distinct_os_name (empty counts as a value): %d\n", nos
    printf "no_city_name: %d (%.2f%% of %d records)\n", nocity, 100 * nocity / n, n
    printf "ios_pct_all: %.2f%% (%d / %d records)\n", 100 * ios / n, ios, n
    printf "android_pct_all: %.2f%% (%d / %d records)\n", 100 * andr / n, andr, n
    printf "mobile_pct_all: %.2f%% (%d / %d records)\n", 100 * (ios + andr) / n, ios + andr, n
    printf "ios_pct_known_os: %.2f%% (%d / %d records with a known os_name)\n", 100 * ios / known, ios, known
    printf "android_pct_known_os: %.2f%% (%d / %d records with a known os_name)\n", 100 * andr / known, andr, known
    printf "mobile_pct_known_os: %.2f%% (%d / %d records with a known os_name)\n", 100 * (ios + andr) / known, ios + andr, known
  }' "$in" > "$out"

echo "top5_web_client (count client):" >> "$out"
# counts from the largest, ties broken by the client name (A to Z, byte order)
tail -n +2 "$in" | cut -d, -f5 | sort | uniq -c | sort -k1,1nr -k2 | awk 'NR <= 5' \
  | awk '{ c = $1; sub(/^ *[0-9]+ /, ""); printf "  %d %s\n", c, $0 }' >> "$out"
cat "$out"

{ echo "date,os_name,count"
  tail -n +2 "$in" | awk -F, '{ c[$1 "," $4]++ } END { for (k in c) print k "," c[k] }' \
    | sort -t, -k3,3nr -k1,1 -k2,2
} > results/daily_os_counts.csv
echo "daily_os_counts.csv: $(( $(wc -l < results/daily_os_counts.csv) - 1 )) rows"
