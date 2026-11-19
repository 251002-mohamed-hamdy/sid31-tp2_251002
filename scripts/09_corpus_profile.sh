#!/usr/bin/env bash
# Task 2.5 (a) - corpus profile -> results/hass_profile.txt
# English word   = maximal run of a-z after lowercase.
# hassaniya-en token = maximal run of a-z and 0-9 after lowercase: the Latin
#   transcription (Arabizi) writes Arabic sounds with digits (3 = ain, 7 = ha,
#   2 = hamza, 5 = kha, 9 = qaf ...), so a digit is part of the word.
set -euo pipefail
cd "$(dirname "$0")/.."
export LC_ALL=C
in=data/clean/hass_base.tsv
out=results/hass_profile.txt
STOP="a an the to of is i you he she it and in my"

tail -n +2 "$in" | awk -F'\t' '
  { n++; c[$1]++
    s = tolower($1); gsub(/[^a-z]+/, " ", s); words += split(s, w, " ") }
  END {
    for (k in c) { d++; if (c[k] > 1) { rep++; extra += c[k] - 1 } }
    printf "sentence_pairs: %d\n", n
    printf "distinct_english_sentences: %d\n", d
    printf "sentences_appearing_more_than_once: %d\n", rep
    printf "extra_rows (beyond the first of each repeated sentence): %d\n", extra
    printf "avg_words_per_english_sentence: %.2f (%d words / %d sentence pairs)\n", words / n, words, n
  }' > "$out"

echo "top10_english_words (count word), stoplist removed:" >> "$out"
tail -n +2 "$in" | cut -f1 | tr 'A-Z' 'a-z' | tr -cs 'a-z' '\n' | grep -v '^$' \
  | grep -vxF -f <(printf '%s\n' $STOP) | sort | uniq -c | sort -k1,1nr -k2,2 | awk 'NR <= 10' \
  | awk '{ printf "  %d %s\n", $1, $2 }' >> "$out"

tail -n +2 "$in" | cut -f3 | tr 'A-Z' 'a-z' | tr -cs 'a-z0-9' '\n' | grep -v '^$' > results/.tok.tmp
printf 'hassaniya_en_tokens: %d\n' "$(wc -l < results/.tok.tmp)" >> "$out"
printf 'hassaniya_en_tokens_with_a_digit: %d (distinct: %d)\n' \
  "$(grep -c '[0-9]' results/.tok.tmp)" "$(grep '[0-9]' results/.tok.tmp | sort -u | wc -l)" >> "$out"
echo "top10_hassaniya_en_tokens (count token):" >> "$out"
sort results/.tok.tmp | uniq -c | sort -k1,1nr -k2,2 | awk 'NR <= 10' | awk '{ printf "  %d %s\n", $1, $2 }' >> "$out"
rm -f results/.tok.tmp
cat "$out"
