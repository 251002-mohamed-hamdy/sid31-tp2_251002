#!/usr/bin/env bash
# Task 2.4 - league tables -> results/tables/<season>.csv, season_summary.csv, result_distribution.csv
set -euo pipefail
cd "$(dirname "$0")/.."
export LC_ALL=C
in=data/clean/matches_clean.csv
mkdir -p results/tables
rm -f results/tables/*.csv

# one line per (season, team): season,team,played,gf,ga,diff,points
tail -n +2 "$in" | awk -F, -v OFS=, '
  { h = $1 SUBSEP $4; a = $1 SUBSEP $5
    pl[h]++; pl[a]++
    gf[h] += $6; ga[h] += $7; gf[a] += $7; ga[a] += $6
    if ($8 == "home_win") pt[h] += 3; else if ($8 == "away_win") pt[a] += 3; else { pt[h]++; pt[a]++ } }
  END { for (k in pl) { split(k, p, SUBSEP)
          print p[1], p[2], pl[k], gf[k], ga[k], gf[k] - ga[k], pt[k] + 0 } }' > results/.teams.tmp

cut -d, -f1 results/.teams.tmp | sort -u | while IFS= read -r season; do
  file="results/tables/$(printf '%s' "$season" | tr ' /' '__').csv"
  { echo "team,played,goals_for,goals_against,diff,points"
    awk -F, -v s="$season" -v OFS=, '$1 == s { print $2, $3, $4, $5, $6, $7 }' results/.teams.tmp \
      | sort -t, -k6,6nr -k5,5nr -k3,3nr -k1,1
  } > "$file"
done

{ echo "season,teams,matches,expected_matches,complete"
  tail -n +2 "$in" | awk -F, '
    { m[$1]++; t[$1 SUBSEP $4] = 1; t[$1 SUBSEP $5] = 1 }
    END { for (k in t) { split(k, p, SUBSEP); nt[p[1]]++ }
          for (s in m) { e = nt[s] * (nt[s] - 1)
                         printf "%s,%d,%d,%d,%s\n", s, nt[s], m[s], e, (m[s] == e) ? "yes" : "no" } }' | sort -t, -k1,1
} > results/season_summary.csv

{ echo "result,matches"
  tail -n +2 "$in" | cut -d, -f8 | sort | uniq -c | sort -k1,1nr -k2,2 | awk '{ print $2 "," $1 }'
} > results/result_distribution.csv
rm -f results/.teams.tmp

echo "tables: $(ls results/tables | wc -l) files"
cat results/season_summary.csv
cat results/result_distribution.csv
