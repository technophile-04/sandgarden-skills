#!/usr/bin/env bash
#
# Pin scaffold-ui versions across SpeedRunEthereum challenge branches and open one PR each.
#
# Run from inside a clone of scaffold-eth/se-2-challenges. For each challenge <slug> it:
#   - creates branch scaffold-ui-version-fix-<slug> off origin/challenge-<slug>
#   - inserts the pinned scaffold-ui deps at the top of extension/packages/nextjs/package.json
#     (creating the file if the challenge doesn't have one), preserving existing deps + indent
#   - commits "pin scaffold-ui versions", pushes, and opens a PR titled
#     "challenge-<slug>: pin scaffold-ui versions" (base challenge-<slug>)
#
# Usage:
#   pin-and-pr.sh [--dry-run] \
#     --components <ver> --debug-contracts <ver> --hooks <ver> \
#     --challenges "crowdfunding token-vendor dice-game ..."
#
# --dry-run builds the branches locally and prints every diff, but does not push or open PRs.

set -euo pipefail

REPO_SLUG="scaffold-eth/se-2-challenges"
PKGPATH="extension/packages/nextjs/package.json"
DRY_RUN=0
COMPONENTS="" DEBUG_CONTRACTS="" HOOKS="" CHALLENGES=""

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run)         DRY_RUN=1; shift ;;
    --components)      COMPONENTS="$2"; shift 2 ;;
    --debug-contracts) DEBUG_CONTRACTS="$2"; shift 2 ;;
    --hooks)           HOOKS="$2"; shift 2 ;;
    --challenges)      CHALLENGES="$2"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done

if [ -z "$COMPONENTS" ] || [ -z "$DEBUG_CONTRACTS" ] || [ -z "$HOOKS" ] || [ -z "$CHALLENGES" ]; then
  echo "error: --components, --debug-contracts, --hooks and --challenges are all required" >&2
  exit 1
fi

# Sanity: are we in the right repo?
if ! git remote -v 2>/dev/null | grep -q "se-2-challenges"; then
  echo "error: run this from inside a clone of $REPO_SLUG" >&2
  exit 1
fi

git fetch origin --quiet

# Detect the indentation of an existing dependencies block (the leading spaces on the
# "dependencies" line) so inserted lines line up. Defaults to 2-space if not found.
dep_key_indent() {
  local file="$1" base
  base=$(grep -m1 '"dependencies"' "$file" | sed -E 's/[^ ].*//')   # leading spaces of the dependencies line
  printf '%s%s' "$base" "${base:-  }"                               # nest one more level (key indent)
}

write_created_file() {
  cat > "$1" <<EOF
{
  "dependencies": {
    "@scaffold-ui/components": "$COMPONENTS",
    "@scaffold-ui/debug-contracts": "$DEBUG_CONTRACTS",
    "@scaffold-ui/hooks": "$HOOKS"
  }
}
EOF
}

insert_pins() {
  local file="$1" ind; ind="$(dep_key_indent "$file")"
  awk -v ind="$ind" -v c="$COMPONENTS" -v d="$DEBUG_CONTRACTS" -v h="$HOOKS" '
    { print }
    /"dependencies": *\{/ && !done {
      printf "%s\"@scaffold-ui/components\": \"%s\",\n", ind, c
      printf "%s\"@scaffold-ui/debug-contracts\": \"%s\",\n", ind, d
      printf "%s\"@scaffold-ui/hooks\": \"%s\",\n", ind, h
      done=1
    }
  ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
}

PRS=()
for slug in $CHALLENGES; do
  base="challenge-$slug"
  head="scaffold-ui-version-fix-$slug"

  if ! git rev-parse --verify "origin/$base" >/dev/null 2>&1; then
    echo "!! skipping $slug — origin/$base not found"; continue
  fi

  git checkout -B "$head" "origin/$base" --quiet

  if [ -f "$PKGPATH" ]; then insert_pins "$PKGPATH"; else mkdir -p "$(dirname "$PKGPATH")"; write_created_file "$PKGPATH"; fi

  # Fail loudly if we produced invalid JSON
  if ! python3 -c "import json,sys; json.load(open('$PKGPATH'))" 2>/dev/null; then
    echo "!! invalid JSON for $slug — aborting"; exit 1
  fi

  git add "$PKGPATH"
  git commit -m "pin scaffold-ui versions" --quiet

  echo "===== $head  (base: $base) ====="
  git diff "origin/$base" -- "$PKGPATH"
  echo ""

  if [ "$DRY_RUN" -eq 0 ]; then
    git push -u origin "$head" --quiet
    url=$(gh pr create --repo "$REPO_SLUG" --base "$base" --head "$head" \
            --title "$base: pin scaffold-ui versions" --body "")
    PRS+=("$url")
  fi
done

if [ "$DRY_RUN" -eq 1 ]; then
  echo "### dry run — nothing pushed. Re-run without --dry-run to push and open PRs."
else
  echo "### opened ${#PRS[@]} PRs:"
  printf '  %s\n' "${PRS[@]}"
fi
