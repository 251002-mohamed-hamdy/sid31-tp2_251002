#!/usr/bin/env bash
# Usage: S=<your student number> bash scripts/run_all.sh
set -euo pipefail
cd "$(dirname "$0")/.."
export LC_ALL=C                      # the same sort order on every machine
: "${S:?export S=<your student number> first}"
mkdir -p logs data/clean results/tables
LOG=logs/run.log
log()   { printf '%s %s\n' "$(date -u +%FT%TZ)" "$*" | tee -a "$LOG" >&2; }
stage() { log "START $1"; bash "scripts/$1"; log "DONE $1"; }

stage 00_fetch.sh            # download if missing, then stop if a checksum differs
stage 01_inventory.sh        # Task 1.1
stage 02_web_clean.sh        # Task 1.2
stage 03_matches_clean.sh    # Task 1.3
stage 04_corpus_clean.sh     # Task 1.4
stage 05_web_profile.sh      # Task 2.1
stage 06_web_join.sh         # Task 2.2
stage 07_web_daily_isp.sh    # Task 2.3
stage 08_league.sh           # Task 2.4
stage 09_corpus_profile.sh   # Task 2.5 (a)
stage 10_backlog.sh          # Task 2.5 (b)
log "ALL DONE"
