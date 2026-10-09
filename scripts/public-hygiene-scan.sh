#!/usr/bin/env bash
# Public hygiene scan for atlas-tasks.
#
# Usage:
#   scripts/public-hygiene-scan.sh [--range <git-range>|--all]
#
#   --range A..B  scan commits / added lines in A..B (pull_request or push)
#   --all         scan every commit reachable from HEAD (default)
#
# Checks:
#   1. Tree scan: every git-tracked file against the deny-list.
#   2. Commit metadata: author/committer emails must be GitHub noreply
#      addresses; names and full messages must not match the deny-list.
#   3. Added lines: `+` lines of the diff for the range against the deny-list.
#   4. gitleaks over the checkout (skipped locally when the binary is absent,
#      unless HYGIENE_REQUIRE_GITLEAKS=1).
#
# Every deny-list pattern uses a bracket character class so this file never
# contains the literal strings it forbids (no self-exclusion needed).
set -euo pipefail

usage() {
  echo "usage: scripts/public-hygiene-scan.sh [--range <git-range>|--all]" >&2
  exit 2
}

MODE="all"
RANGE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --all) MODE="all"; RANGE=""; shift ;;
    --range)
      [[ -n "${2:-}" ]] || usage
      MODE="range"; RANGE="$2"; shift 2 ;;
    -h|--help) usage ;;
    *) echo "unknown arg: $1" >&2; usage ;;
  esac
done

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

# Case-insensitive deny-list.
DENY_CI=(
  'sesispl[a]'
  '/home/bo[x]'
  '/work[s]pace\b'
  'op:/[/][A-Za-z]'
  'git@[A-Za-z0-9.-]+:'
  'ssh:/[/]'
  'sergio-atla[s]-'
)
# Case-sensitive deny-list (private bot role names).
DENY_CS=(
  '\bHan[d]\b'
  'Grand Maeste[r]'
  'Master of [A-Z][a-z]+'
  '\bMo[P]\b'
  '\bMo[N]\b'
  'King.s Guar[d]'
  'Warde[n]'
  'Small Counci[l]'
  'Grok Bo[t]'
  'grok-bo[t]'
  'APM PR Bo[t]'
  'apm-code-bo[t]'
)

join_alt() { local IFS='|'; echo "$*"; }
DENY_RE="(?i:$(join_alt "${DENY_CI[@]}"))|(?:$(join_alt "${DENY_CS[@]}"))"

FAILED=0
fail_section() { echo "FAIL: $*" >&2; FAILED=1; }

# Reads text on stdin; prints matching lines; returns 0 when anything matched.
deny_match() { grep -P -- "$DENY_RE"; }

HAS_HEAD=1
git rev-parse --verify -q HEAD >/dev/null || HAS_HEAD=0

# Resolve the commit range. A range whose endpoints are not present locally
# (e.g. a force-push "before" sha) falls back to scanning all of HEAD.
if [[ "$MODE" == "range" ]]; then
  if [[ "$RANGE" != *..* ]]; then
    echo "--range expects <a>..<b>" >&2; exit 2
  fi
  range_from="${RANGE%%..*}"
  range_to="${RANGE##*..}"
  if [[ -z "$range_from" || "$range_from" =~ ^0+$ ]] \
    || ! git rev-parse --verify -q "${range_from}^{commit}" >/dev/null \
    || ! git rev-parse --verify -q "${range_to:-HEAD}^{commit}" >/dev/null; then
    echo "note: range '$RANGE' not resolvable locally; scanning all commits reachable from HEAD"
    MODE="all"; RANGE=""
  fi
fi
if [[ "$MODE" == "all" ]]; then
  SCOPE="all commits reachable from HEAD"
else
  SCOPE="$RANGE"
fi
echo "public-hygiene-scan: scope = $SCOPE"

# ---------------------------------------------------------------------------
# 1. Tree scan (git-tracked files)
# ---------------------------------------------------------------------------
files=()
while IFS= read -r -d '' f; do
  [[ -f "$f" && ! -L "$f" ]] && files+=("$f")
done < <(git ls-files -z)

tree_hits=""
if [[ ${#files[@]} -gt 0 ]]; then
  tree_hits="$(printf '%s\0' "${files[@]}" \
    | xargs -0 grep -nHoIP -s -- "$DENY_RE" || true)"
fi
if [[ -n "$tree_hits" ]]; then
  echo "$tree_hits" >&2
  fail_section "tree scan: deny-list hits in tracked files"
else
  echo "ok: tree scan (${#files[@]} tracked files)"
fi

# ---------------------------------------------------------------------------
# 2. Commit metadata scan
# ---------------------------------------------------------------------------
commits=()
if [[ "$HAS_HEAD" -eq 1 ]]; then
  if [[ "$MODE" == "all" ]]; then
    mapfile -t commits < <(git rev-list HEAD)
  else
    mapfile -t commits < <(git rev-list "$RANGE")
  fi
fi

email_ok() {
  local e="$1"
  [[ "$e" == *@users.noreply.github.com || "$e" == "noreply@github.com" ]]
}

meta_bad=0
for c in "${commits[@]}"; do
  IFS=$'\x1f' read -r an ae cn ce < <(git show -s --format='%an%x1f%ae%x1f%cn%x1f%ce' "$c")
  short="${c:0:12}"
  if ! email_ok "$ae"; then
    echo "$short:author-email:$ae" >&2; meta_bad=1
  fi
  if ! email_ok "$ce"; then
    echo "$short:committer-email:$ce" >&2; meta_bad=1
  fi
  if printf '%s\n%s\n' "$an" "$cn" | deny_match >/dev/null; then
    echo "$short:name:$(printf '%s\n%s\n' "$an" "$cn" | deny_match | head -1)" >&2; meta_bad=1
  fi
  msg_hits="$(git show -s --format=%B "$c" | grep -noP -- "$DENY_RE" || true)"
  if [[ -n "$msg_hits" ]]; then
    while IFS= read -r h; do echo "$short:message:$h" >&2; done <<<"$msg_hits"
    meta_bad=1
  fi
done
if [[ "$meta_bad" -ne 0 ]]; then
  fail_section "commit metadata scan"
else
  echo "ok: commit metadata (${#commits[@]} commits)"
fi

# ---------------------------------------------------------------------------
# 3. Added-lines scan
# ---------------------------------------------------------------------------
added_lines() {
  # Emits "<path>:<new-line-number>:<content>" for every added line.
  awk '
    /^\+\+\+ / { path = substr($0, 5); sub(/^b\//, "", path); next }
    /^@@ / {
      if (match($0, /\+[0-9]+/)) { ln = substr($0, RSTART + 1, RLENGTH - 1) + 0 }
      next
    }
    /^\+/ { print path ":" ln ":" substr($0, 2); ln++; next }
    /^ / { ln++ }
  '
}

diff_hits=""
if [[ "$HAS_HEAD" -eq 1 ]]; then
  if [[ "$MODE" == "all" ]]; then
    diff_hits="$(git log -p -U0 --no-color --no-ext-diff --format= HEAD | added_lines | deny_match || true)"
  else
    diff_hits="$(git diff -U0 --no-color --no-ext-diff "$RANGE" | added_lines | deny_match || true)"
  fi
fi
if [[ -n "$diff_hits" ]]; then
  echo "$diff_hits" >&2
  fail_section "added-lines scan: deny-list hits in added lines"
else
  echo "ok: added-lines scan"
fi

# ---------------------------------------------------------------------------
# 4. gitleaks
# ---------------------------------------------------------------------------
if command -v gitleaks >/dev/null 2>&1; then
  if [[ "$HAS_HEAD" -eq 0 ]]; then
    if gitleaks detect --source . --no-git --redact --no-banner; then
      echo "ok: gitleaks (no commits; working tree)"
    else
      fail_section "gitleaks reported findings"
    fi
  else
    if [[ "$MODE" == "all" ]]; then log_opts="--all"; else log_opts="$RANGE"; fi
    if gitleaks detect --source . --log-opts="$log_opts" --redact --no-banner; then
      echo "ok: gitleaks"
    else
      fail_section "gitleaks reported findings"
    fi
  fi
elif [[ "${HYGIENE_REQUIRE_GITLEAKS:-0}" == "1" ]]; then
  fail_section "gitleaks not found on PATH and HYGIENE_REQUIRE_GITLEAKS=1"
else
  echo "skip: gitleaks not installed (set HYGIENE_REQUIRE_GITLEAKS=1 to require it)"
fi

if [[ "$FAILED" -ne 0 ]]; then
  echo "FAIL: public hygiene scan ($SCOPE)" >&2
  exit 1
fi
echo "PASS: public hygiene scan ($SCOPE)"
