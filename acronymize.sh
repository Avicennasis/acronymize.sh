#!/usr/bin/env bash
#
# acronymize.sh
#
# Create an "acronym expansion" from input text by mapping each letter (in order)
# to a randomly selected dictionary word that starts with that letter.
#
# Behavior:
# - Output is multiple lines: one line per input word (whitespace-separated token).
# - Each letter occurrence is randomized independently (Option B).
# - Non-alphabetic characters are removed from each input token before processing.
# - Output words are Title Cased (first letter capitalized).
#
# Notes:
# - Uses a wordlist (default: /usr/share/dict/words).
# - Strips a trailing apostrophe+s from dictionary words (e.g., "dog's" -> "dog").
#
# Usage:
#   ./acronymize.sh [-w /path/to/wordlist] [text...]
#
# Examples:
#   ./acronymize.sh "NASA"
#   ./acronymize.sh Make Acronyms Great Again
#   WORDLIST=./words.txt ./acronymize.sh "hello world"
#

set -euo pipefail

WORDLIST="${WORDLIST:-/usr/share/dict/words}"

usage() {
  cat <<EOF
Usage: $(basename "$0") [-w WORDLIST] [text...]

Options:
  -w PATH   Use a custom wordlist (default: /usr/share/dict/words)
  -h        Show this help

Environment:
  WORDLIST  Alternative way to set the wordlist path (overridden by -w)

Notes:
  - Non-alphabetic characters are ignored.
  - Output is one line per input word.
EOF
}

while getopts ":w:h" opt; do
  case "$opt" in
    w) WORDLIST="$OPTARG" ;;
    h) usage; exit 0 ;;
    \?)
      echo "Unknown option: -$OPTARG" >&2
      usage
      exit 2
      ;;
  esac
done
shift $((OPTIND - 1))

# Accept all remaining args as input text (quotes optional).
INPUT="$*"

if [[ -z "${INPUT// }" ]]; then
  usage
  exit 2
fi

if [[ ! -r "$WORDLIST" ]]; then
  echo "Wordlist not readable: $WORDLIST" >&2
  exit 1
fi

# Use awk to:
# 1) Parse INPUT into whitespace-separated tokens (input words).
# 2) For each token, strip non-letters and lowercase it to get the letter stream.
# 3) Scan the wordlist once, collecting candidate words for only the needed letters.
# 4) For each letter occurrence, emit a randomized word (per-occurrence randomization).
# 5) Print one output line per input token.
#
# To reduce repeats for the same letter within a single run:
# - Shuffle candidates for each letter (Fisher-Yates),
# - Consume sequentially,
# - Reshuffle when exhausted.
awk -v text="$INPUT" '
BEGIN {
  srand()

  # Split on whitespace to preserve word boundaries.
  ntok = split(text, tok, /[[:space:]]+/)

  # Build per-token sanitized letter streams and compute which starting letters we need.
  total_letters = 0
  for (t = 1; t <= ntok; t++) {
    # Keep letters only, lowercase.
    s = tok[t]
    gsub(/[^[:alpha:]]/, "", s)
    s = tolower(s)

    token_letters[t] = s
    token_len[t] = length(s)
    total_letters += token_len[t]

    for (i = 1; i <= token_len[t]; i++) {
      c = substr(s, i, 1)
      needed[c] = 1
    }
  }

  if (total_letters == 0) {
    print "No alphabetic characters found in input." > "/dev/stderr"
    exit 2
  }
}

{
  w = $0

  # Strip trailing apostrophe+s from the dictionary word.
  # (Written using hex for apostrophe to avoid shell quoting issues.)
  sub(/\x27s$/, "", w)

  first = tolower(substr(w, 1, 1))
  if (!(first in needed)) next

  count[first]++
  words[first SUBSEP count[first]] = w
}

function shuffle_letter(c, j, k, tmp) {
  for (j = 1; j <= count[c]; j++) perm[c SUBSEP j] = j
  for (j = count[c]; j > 1; j--) {
    k = int(rand() * j) + 1
    tmp = perm[c SUBSEP j]
    perm[c SUBSEP j] = perm[c SUBSEP k]
    perm[c SUBSEP k] = tmp
  }
  pos[c] = 1
  inited[c] = 1
}

function title_case(s) {
  if (length(s) == 0) return s
  return toupper(substr(s, 1, 1)) substr(s, 2)
}

END {
  for (t = 1; t <= ntok; t++) {
    s = token_letters[t]
    if (length(s) == 0) continue

    line = ""
    for (i = 1; i <= length(s); i++) {
      c = substr(s, i, 1)

      if (count[c] == 0) {
        word = "(no-match:" c ")"
      } else {
        if (!(c in inited)) shuffle_letter(c)
        idx = perm[c SUBSEP pos[c]]
        word = words[c SUBSEP idx]
        pos[c]++
        if (pos[c] > count[c]) shuffle_letter(c)
      }

      word = title_case(word)
      line = line (i == 1 ? "" : " ") word
    }

    print line
  }
}
' "$WORDLIST"
