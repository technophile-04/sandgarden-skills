#!/usr/bin/env bash
#
# Read-only classifier for se-2-challenges branches. Prints one row per remote branch with
# last-commit date, author, open-PR status, PR history, and a coarse bucket. Deletes nothing.
#
# Classification is driven by PR STATE (from the gh API), not git ancestry — squash merges
# make ancestry useless here, and challenge branches are themselves PR heads, so "head of a
# merged PR" is not a safe delete signal. See SKILL.md for the full reasoning.
#
# Usage:
#   classify-branches.sh --keep "main base-challenge-template challenge-tokenization ..."
#
# --keep lists the canonical branches to mark KEEP (current speedrunethereum challenges +
# main + base-challenge-template). Everything not in --keep and not protected by an open PR
# is surfaced as a candidate for the human to judge.

set -euo pipefail

KEEP=""
while [ $# -gt 0 ]; do
  case "$1" in
    --keep) KEEP="$2"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done

if ! git remote -v 2>/dev/null | grep -q "se-2-challenges"; then
  echo "error: run this from inside a clone of scaffold-eth/se-2-challenges" >&2
  exit 1
fi
REPO_SLUG=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')

git fetch origin --prune --quiet

# Branches protected by an OPEN PR (head or base)
OPEN_PR=$(gh pr list --repo "$REPO_SLUG" --state open --limit 300 \
  --json headRefName,baseRefName --jq '.[] | .headRefName, .baseRefName' | sort -u)
# Heads of OPEN PRs (for accurate PR-history labelling)
OPEN_HEADS=$(gh pr list --repo "$REPO_SLUG" --state open --limit 300 \
  --json headRefName --jq '.[].headRefName' | sort -u)
# Branches that were ever the HEAD of a MERGED PR
MERGED_HEADS=$(gh pr list --repo "$REPO_SLUG" --state merged --limit 600 \
  --json headRefName --jq '.[].headRefName' | sort -u)
# Branches that were ever the HEAD of ANY PR
ANY_HEADS=$(gh pr list --repo "$REPO_SLUG" --state all --limit 800 \
  --json headRefName --jq '.[].headRefName' | sort -u)

in_set() { printf '%s\n' "$2" | grep -qx "$1"; }

printf "%-46s %-12s %-16s %-8s %-12s %s\n" "BRANCH" "LAST-COMMIT" "AUTHOR" "OPEN-PR" "PR-HISTORY" "BUCKET"
printf "%-46s %-12s %-16s %-8s %-12s %s\n" "------" "-----------" "------" "-------" "----------" "------"

git for-each-ref --sort=committerdate \
  --format='%(refname:short)|%(committerdate:short)|%(authorname)' refs/remotes/origin |
while IFS='|' read -r ref date author; do
  b="${ref#origin/}"
  [ "$b" = "HEAD" ] && continue

  openpr="no"; in_set "$b" "$OPEN_PR" && openpr="YES"

  prhist="none"
  if in_set "$b" "$MERGED_HEADS"; then prhist="has-merged"
  elif in_set "$b" "$OPEN_HEADS"; then prhist="open"
  elif in_set "$b" "$ANY_HEADS"; then prhist="closed-only"; fi

  case " $KEEP " in *" $b "*) bucket="KEEP (canonical)";; *) bucket="";; esac
  if [ -z "$bucket" ]; then
    if [ "$openpr" = "YES" ]; then bucket="PROTECTED (open PR)"
    elif [ "$prhist" = "closed-only" ]; then bucket="candidate: closed-PR work"
    elif [ "$prhist" = "none" ]; then bucket="candidate: no-PR / scratch"
    else bucket="review: had-merged PR (verify before delete)"; fi
  fi

  printf "%-46s %-12s %-16s %-8s %-12s %s\n" "$b" "$date" "${author:0:15}" "$openpr" "$prhist" "$bucket"
done
