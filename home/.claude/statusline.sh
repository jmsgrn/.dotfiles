#!/usr/bin/env bash
# Clean, minimal Claude Code status line.
#   line 1:  model  │  ⎇ branch  │  📁 dir  │  ▓ bar  ~N% of <window> tokens
#   line 2:  ❯ your most recent prompt
#
# Reads the session JSON Claude Code pipes on stdin. Self-contained: no plugin,
# no hook. Portable — bash 3.2+, BSD or GNU tools, and jq OR python3.
# Drop this file anywhere and point settings.json "statusLine" at it.

input="$(cat)"

if command -v jq >/dev/null 2>&1; then HAVE_JQ=1; else HAVE_JQ=; fi

# --- fields from stdin (joined with \037 so empty fields don't collapse) ---
extract() {
  if [ -n "$HAVE_JQ" ]; then
    printf '%s' "$input" | jq -r '[
      (.model.display_name // "Claude"),
      (.workspace.current_dir // .cwd // ""),
      (.context_window.used_percentage // 0),
      (.context_window.context_window_size // 200000),
      (.transcript_path // "")
    ] | map(tostring) | join("")'
  else
    printf '%s' "$input" | python3 -c '
import sys, json
try: d = json.load(sys.stdin)
except Exception: d = {}
def g(o,k,dv=None): return (o or {}).get(k,dv)
cw = g(d,"context_window") or {}
ws = g(d,"workspace") or {}
print("\x1f".join(str(x) for x in [
    g(g(d,"model") or {}, "display_name", "Claude"),
    ws.get("current_dir") or d.get("cwd") or "",
    cw.get("used_percentage", 0) or 0,
    cw.get("context_window_size", 200000) or 200000,
    d.get("transcript_path") or "",
]))'
  fi
}
IFS=$'\037' read -r MODEL DIR PCT WIN TRANSCRIPT < <(extract) || true
MODEL="${MODEL:-Claude}"; DIR="${DIR:-$PWD}"

# --- most recent prompt, straight from the transcript ---
PROMPT=""
if [ -n "${TRANSCRIPT:-}" ] && [ -r "$TRANSCRIPT" ]; then
  line="$(grep '"type":"last-prompt"' "$TRANSCRIPT" 2>/dev/null | tail -1)"
  if [ -n "$line" ]; then
    if [ -n "$HAVE_JQ" ]; then
      PROMPT="$(printf '%s' "$line" | jq -r '.lastPrompt // ""')"
    else
      PROMPT="$(printf '%s' "$line" | python3 -c 'import sys,json;print(json.load(sys.stdin).get("lastPrompt","") or "")')"
    fi
  fi
fi
# strip @"attachments" and <command tags>, collapse whitespace, truncate
PROMPT="$(printf '%s' "$PROMPT" \
  | sed -E 's/@"[^"]*"//g; s/<[^>]*>//g' \
  | tr '\n\t' '  ' \
  | sed -E 's/^ +//; s/ +$//; s/  +/ /g' \
  | awk '{ if (length>96) print substr($0,1,95) "…"; else print }')"

# --- git branch (quiet; empty outside a repo) ---
BRANCH="$(git -C "$DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
[ "$BRANCH" = "HEAD" ] && BRANCH="$(git -C "$DIR" rev-parse --short HEAD 2>/dev/null || echo detached)"

# --- context: bar + percent + window size ---
PCT_INT="${PCT%.*}"; case "$PCT_INT" in ''|*[!0-9]*) PCT_INT=0;; esac
WI="${WIN%.*}"; case "$WI" in ''|*[!0-9]*) WI=200000;; esac
if   [ "$WI" -ge 1000000 ]; then WLBL="$((WI/1000000))M"
elif [ "$WI" -ge 1000 ];    then WLBL="$((WI/1000))k"
else WLBL="$WI"; fi

# --- colours (truecolor) ---
MODELC=$'\033[1;38;2;86;196;176m'   # teal, bold
DIM=$'\033[38;2;118;118;132m'
BRANCHC=$'\033[38;2;152;190;140m'   # soft green
TEXT=$'\033[38;2;208;208;216m'
BARC=$'\033[38;2;86;196;176m'
R=$'\033[0m'
SEP="  ${DIM}│${R}  "

W=10; filled=$(( (PCT_INT*W + 50)/100 ))
[ "$filled" -gt "$W" ] && filled=$W; [ "$filled" -lt 0 ] && filled=0
bar=""; i=0
while [ "$i" -lt "$W" ]; do
  if [ "$i" -lt "$filled" ]; then bar="${bar}${BARC}▓${R}"; else bar="${bar}${DIM}░${R}"; fi
  i=$((i+1))
done

BASE="${DIR##*/}"; [ -z "$BASE" ] && BASE="$DIR"

# --- render ---
line1="${MODELC}${MODEL}${R}"
[ -n "${BRANCH:-}" ] && line1="${line1}${SEP}${DIM}⎇${R} ${BRANCHC}${BRANCH}${R}"
line1="${line1}${SEP}📁 ${TEXT}${BASE}${R}"
line1="${line1}${SEP}${bar} ${DIM}~${PCT_INT}% of ${WLBL} tokens${R}"

if [ -n "$PROMPT" ]; then
  line2="${BARC}❯${R} ${TEXT}${PROMPT}${R}"
else
  line2="${DIM}❯${R}"
fi

printf '%s\n%s\n' "$line1" "$line2"
