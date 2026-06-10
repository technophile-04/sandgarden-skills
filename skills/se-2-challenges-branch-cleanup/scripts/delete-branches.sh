#!/usr/bin/env bash
#
# Delete the named branches from origin, AFTER recording each tip SHA to a recovery file so
# any deletion is a one-command restore. Pass the approved branch list as arguments.
#
# Usage:
#   delete-branches.sh <branch1> <branch2> ...
#   delete-branches.sh --recovery-file /path/to/file.txt <branch1> ...
#
# Only run this on a list a human has explicitly approved (see SKILL.md Step 2).

set -euo pipefail

RECOVERY=""
BRANCHES=()
while [ $# -gt 0 ]; do
  case "$1" in
    --recovery-file) RECOVERY="$2"; shift 2 ;;
    *) BRANCHES+=("$1"); shift ;;
  esac
done

if [ "${#BRANCHES[@]}" -eq 0 ]; then
  echo "error: pass at least one branch name to delete" >&2
  exit 1
fi
if ! git remote -v 2>/dev/null | grep -q "se-2-challenges"; then
  echo "error: run this from inside a clone of scaffold-eth/se-2-challenges" >&2
  exit 1
fi

# Date comes from git, not the shell, so the filename is stable/reproducible.
if [ -z "$RECOVERY" ]; then
  today=$(git log -1 --format=%cd --date=short 2>/dev/null || echo undated)
  RECOVERY="$HOME/se-2-challenges-deleted-branches-$today.txt"
fi

git fetch origin --quiet

{
  echo "# se-2-challenges branches deleted (restore: git push origin <sha>:refs/heads/<branch>)"
} >> "$RECOVERY"

for b in "${BRANCHES[@]}"; do
  if ! git rev-parse --verify "origin/$b" >/dev/null 2>&1; then
    echo "!! skipping $b — no origin/$b"; continue
  fi
  sha=$(git rev-parse "origin/$b")
  printf "%s  %s\n" "$sha" "$b" >> "$RECOVERY"
done

echo "Recorded tip SHAs to: $RECOVERY"
echo ""
echo "=== deleting ==="
for b in "${BRANCHES[@]}"; do
  git rev-parse --verify "origin/$b" >/dev/null 2>&1 || continue
  git push origin --delete "$b" 2>&1 | sed 's/^/  /'
done

git fetch origin --prune --quiet
echo ""
echo "Done. Restore any branch with: git push origin <sha>:refs/heads/<branch> (SHAs in $RECOVERY)"
