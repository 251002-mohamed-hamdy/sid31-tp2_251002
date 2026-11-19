# TP2 — Open data pack (SID31 DataOps)

- **Student:** Mohamed Hamdy
- **Student number:** 251002
- **Focus ISP:** MAURITEL (last digit 2)
- **Focus season:** Ligue 1 2018/2019 (second-to-last digit 0)

## Sources

| Raw file | Repository | Pinned commit | Licence as published |
|---|---|---|---|
| `web_2025-10.csv`, `matches.csv` | github.com/binorassocies/rimdata | `e8666952ed3c52bbdff47411f7110b7fdc0dc297` | GNU GPL v3 (`LICENSE` file of the repository) |
| `dah_d1.csv` … `dah_d5.csv`, `dah_completed.csv` | github.com/Hassan-IA/DAH | `fc3e9a318fce778244056d2cb393448991e4f5d0` | CC-BY-4.0 (stated in the repository `README.md`) |

Licences read on 2026-11-19, at the pinned commits. The eight files are checked against `data/SHA256SUMS` by `scripts/00_fetch.sh`.
The column `hash_src_ip` of the web sample is dropped in the first cleaning stage and appears in no committed file.

## How to rebuild

```bash
export S=251002
bash scripts/00_fetch.sh          # downloads the 8 raw files (if missing) and checks them
chmod a-w data/raw/*
rm -rf data/clean results logs && S=$S bash scripts/run_all.sh
```

`run_all.sh` runs the stages `00` to `10` in order, writes a START/DONE line with a UTC time for each stage in `logs/run.log`,
and stops with a non-zero exit code if a checksum or a stage fails. Two runs give byte-identical files in `results/` (`LC_ALL=C`, every output is sorted).

Tools: bash, coreutils (cut, sort, uniq, tr, wc, tail), grep, sed, awk, sha256sum, curl, git.
The awk programs use only POSIX awk (no FPAT, no asort), so they run the same with gawk and mawk. The quoted CSV of the corpus is read by a small character-by-character reader (`csvsplit` in `04_corpus_clean.sh`).

Token rule for hassaniya-en (`09_corpus_profile.sh`): a token is a maximal run of `a-z` and `0-9` after lowercase.
Digits are kept because the Latin transcription writes Arabic sounds with digits (3 = ع, 7 = ح, 2 = ء, 4 = ذ …): `3le` or `4e` are words, not numbers.
Accented letters (é, ṣ: 8 characters in the whole file) are not allowed and cut a token; apostrophes and hyphens also cut a token.

## Findings

1. Format problems of the raw files and their repair
   - **Claim:** 7 of the 8 raw files need a repair before use: `matches.csv` has a carriage return on all 2745 lines, `dah_completed.csv` on 100 of its 101 lines, five corpus files (d2–d5 and completed) have no final newline, and 5 corpus files have lines whose plain comma count differs from the header (from 8 lines in d5 to 323 in d1) because of quoted fields with commas.
   - **Evidence:** `results/inventory.tsv` (`scripts/01_inventory.sh`); repairs in `02`–`04` (`tr -d '\r'`, quote-aware reader, trim). After repair every line of `hass_base.tsv` has 3 fields (3003 lines).
   - **Limit:** the inventory counts lines and fields; it does not show wrong values inside a field (typos, a translation in the wrong column), and `lines_other_fields` mixes real errors with legal quoted commas. The 4th column of `dah_completed.csv`, described as empty, holds `x` on 4 of 100 rows; we dropped it without knowing what it means.

2. Year rule for match dates without a year
   - **Claim:** 154 of 2744 matches (all in Ligue 1 2024/2025) have a date without a year and get an inferred year; tested on the 2326 matches with a full date in two-year seasons, the rule gives a wrong year for 57 (2.45%).
   - **Evidence:** `data/clean/matches_clean.csv` (`date_status`), test printed by `scripts/03_matches_clean.sh` in the log: 52 in Ligue 1 2019/2020 (September–October 2020) and 5 in Championnat D1 2007/2008 (August 2008).
   - **Limit:** the rule fails when a season is delayed (the 2019/2020 season ended in late 2020); the test does not prove the inferred 2024/2025 dates are right, only that this season looks like a normal one.

3. Mobile share and unmapped clients of the web sample
   - **Claim:** 85.51% of the 45260 records come from iOS or Android (86.67% of the 44655 records with a known OS), and 2430 records (5.37% of 45260) have a client that is not in the lookup, mostly `Other` (2361).
   - **Evidence:** `results/web_profile.txt` (`scripts/05_web_profile.sh`); `scripts/06_web_join.sh` prints the unmapped clients; `data/clean/web_enriched.csv` keeps all 45260 rows with class `unmapped`.
   - **Limit:** the file is a sample of web logs, not all the traffic of October 2025; `Other` hides real clients that we cannot classify, and 7.38% of the records (3339) have no city, so no claim by city is safe.

4. Bot share of the focus ISP (MAURITEL)
   - **Claim:** 3232 of the 29856 MAURITEL records (10.83%) have the client class `bot`, against 4888 of 45260 (10.80%) for all operators.
   - **Evidence:** `results/isp_client_class.csv` (rows `MAURITEL,*`) and `results/web_daily_isp_251002.csv` (sum of column `bot` for MAURITEL), `scripts/06_web_join.sh` and `scripts/07_web_daily_isp.sh`.
   - **Limit:** `bot` is a working class made only from the client name (all of it is `FacebookBot`); it is not a measurement of automation: a script can show a browser name, and the 1603 unmapped MAURITEL records are not counted.

5. Busy days of the focus ISP (MAURITEL)
   - **Claim:** with the nearest-rank 90th percentile of its 31 daily counts (rank 28, threshold 1511 records), MAURITEL has 4 busy days: 1, 2, 3 and 6 October 2025 (3154, 1954, 1696 and 1511 records).
   - **Evidence:** `results/web_daily_isp_251002.csv`, column `busy_flag` (`scripts/07_web_daily_isp.sh`, which prints the threshold of each operator).
   - **Limit:** the four operators all peak on 1–3 October, which may come from how the sample was drawn rather than real traffic; with ties at the threshold the number of busy days can be above 10%, and the flag says nothing about hours.

6. Top three of the focus season (Ligue 1 2018/2019) and completeness test
   - **Claim:** in Ligue 1 2018/2019 (14 teams, 182 of 182 expected matches) the top three are Nouadhibou (59 points), ASAC Concorde (47) and Kedia (44); 2 of the 18 seasons fail the completeness test: Championnat D1 2007/2008 (130 of 132) and Ligue 1 2020/2021 (32 of 56).
   - **Evidence:** `results/tables/Ligue_1_2018_2019.csv` and `results/season_summary.csv` (`scripts/08_league.sh`).
   - **Limit:** the table is rebuilt from the match file with 3/1/0 points; it ignores penalties, forfeits or a second phase (2020/2021 and 2013/2014 look like short formats), and `complete = yes` only compares a count with t(t−1), it does not check that every pair met twice.

7. Results across all seasons
   - **Claim:** of the 2744 matches, 1086 (39.58%) are home wins, 901 (32.84%) away wins and 757 (27.59%) draws.
   - **Evidence:** `results/result_distribution.csv` (`scripts/08_league.sh`).
   - **Limit:** seasons with more matches weigh more; it does not show if the home advantage changed over time or if some "home" matches were played on a neutral ground.

8. Corpus profile
   - **Claim:** the base corpus has 3002 sentence pairs and 2985 distinct English sentences; 16 sentences are repeated, giving 17 extra rows, and 5062 of the 12329 hassaniya-en tokens (41.06%) contain a digit.
   - **Evidence:** `results/hass_profile.txt` (`scripts/09_corpus_profile.sh`).
   - **Limit:** duplicates are counted on the exact English text, so near-duplicates (case, punctuation) are missed; the English top words include `t` and `s` from contractions (don't, it's) because a word is a run of a–z only.

9. Translation backlog by status
   - **Claim:** of the 400 contribution rows of d2–d5, 295 (73.75%) are still `todo`, 99 are `filled` from the completed file, 3 are `prefilled` and 3 are already `in_base`.
   - **Evidence:** `results/backlog_status.csv` and `data/clean/hass_backlog.tsv` (`scripts/10_backlog.sh`).
   - **Limit:** the match is on the exact English sentence, so a sentence written slightly differently counts as `todo`; `filled` and `prefilled` translations were not checked by a speaker.

## Declared help

- Claude (Anthropic AI assistant): used to read the TP sheet, propose the stage scripts, debug two problems (the 3-space separator of `SHA256SUMS`, a SIGPIPE exit 141 of `head` under `pipefail`) and draft this README. I re-ran every script, checked every number against `results/`, and I can explain every command.
