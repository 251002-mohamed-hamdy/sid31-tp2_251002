#!/usr/bin/env bash
# Task 1.3 - clean the match results -> data/clean/matches_clean.csv
set -euo pipefail
cd "$(dirname "$0")/.."
export LC_ALL=C
mkdir -p data/clean
tr -d '\r' < data/raw/matches.csv | awk -F, -v OFS=, '
  NR == 1 { print "season,date,date_status,home_team,away_team,home_goals,away_goals,result"; next }
  NF != 6 { printf "matches: line %d has %d fields\n", NR, NF > "/dev/stderr"; exit 1 }
  {
    split($2, d, ".")                       # 30.05.2025 -> d[1]=30 d[2]=05 d[3]=2025
    if ($2 ~ /^[0-9][0-9]\.[0-9][0-9]\.[0-9][0-9][0-9][0-9]$/) {
      year = d[3]; status = "full"
    } else if ($2 ~ /^[0-9][0-9]\.[0-9][0-9]\.$/) {
      n = split($1, w, " "); lab = w[n]    # last word of the label: 2024/2025
      if (lab !~ /^[0-9][0-9][0-9][0-9]\/[0-9][0-9][0-9][0-9]$/) {
        printf "matches: line %d: no year and one-year season %s\n", NR, $1 > "/dev/stderr"; exit 1 }
      year = (d[2] + 0 >= 8) ? substr(lab, 1, 4) : substr(lab, 6, 4)
      status = "inferred"
    } else { printf "matches: line %d: unknown date %s\n", NR, $2 > "/dev/stderr"; exit 1 }
    if ($5 + 0 > $6 + 0) r = "home_win"; else if ($5 + 0 < $6 + 0) r = "away_win"; else r = "draw"
    print $1, year "-" d[2] "-" d[1], status, $3, $4, $5, $6, r
  }' > data/clean/matches_clean.csv
echo "matches_clean.csv: $(( $(wc -l < data/clean/matches_clean.csv) - 1 )) matches"

# Test of the working rule on the rows that HAVE a full date in two-year seasons.
# The file is not changed: we only count where the rule would give another year.
echo "== test of the year rule (full dates, two-year seasons)"
tr -d '\r' < data/raw/matches.csv | awk -F, '
  NR > 1 && $2 ~ /^[0-9][0-9]\.[0-9][0-9]\.[0-9][0-9][0-9][0-9]$/ {
    n = split($1, w, " "); lab = w[n]
    if (lab !~ /^[0-9][0-9][0-9][0-9]\/[0-9][0-9][0-9][0-9]$/) next
    split($2, d, ".")
    guess = (d[2] + 0 >= 8) ? substr(lab, 1, 4) : substr(lab, 6, 4)
    tested++
    if (guess != d[3]) { bad++; per[$1 " month " d[2] " (source " d[3] ", rule " guess ")"]++ }
  }
  END { printf "tested=%d wrong_year=%d\n", tested, bad + 0
        for (k in per) printf "  %d x %s\n", per[k], k }' | sort
