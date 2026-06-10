---
name: se-2-challenges-branch-cleanup
description: "Audit and clean up stale branches in the scaffold-eth/se-2-challenges repo (a branch-per-challenge repo with no shared main). Use this skill when the branch list has gotten cluttered, when merged or abandoned feature branches are piling up, when someone says they want to clean up / prune / delete old branches in se-2-challenges, or periodically as housekeeping. Classifies every branch by PR state and last activity, proposes a delete list for human approval, and deletes safely with an SHA recovery file — it never deletes unattended."
---

# se-2-challenges branch cleanup

Prune stale branches from `scaffold-eth/se-2-challenges` without nuking live work. The repo accumulates cruft because it has no shared `main` to merge into — each challenge is its own long-lived branch, so the usual "delete the branch when the PR merges" hygiene never kicks in.

**Run this from inside a clone of `scaffold-eth/se-2-challenges`** (often at `externalExtensions/se-2-challenges` inside a `create-eth` checkout). Requires the `gh` CLI.

## Why you can't automate the delete decision

This is the load-bearing insight. Every cheap "is this branch merged and therefore deletable?" heuristic is **wrong** in this repo, for two compounding reasons:

- **Squash merges defeat git ancestry.** The repo squash-merges PRs, so a merged feature branch's tip is never an ancestor of its target. `git branch --merged` and `git merge-base --is-ancestor` report *zero* deletable branches even when plenty have merged. Ancestry is useless here.
- **Challenge branches are themselves PR heads.** The long-lived `challenge-*` branches occasionally get PR'd into `main` or each other. So "was the head of a merged PR" — the signal GitHub's auto-delete uses — would flag `challenge-dex` itself as deletable. Catastrophic if trusted blindly.

The only reliable classifier is **PR state from the GitHub API plus a human reading the table.** This skill gathers the facts and proposes; a person decides. Do not turn it into a cron that deletes on its own.

For the same reason, **do not enable the repo-wide "Automatically delete head branches" setting** here — since challenge branches act as PR heads, that toggle could delete a live challenge on merge. Instead, just tick "delete branch" by hand when an *ephemeral* fix PR merges.

## The keep policy

Branches that must survive a cleanup:

- `main` and `base-challenge-template` (the master challenge template)
- The challenge branches live on [speedrunethereum.com](https://speedrunethereum.com) — each is `challenge-<slug>`. Pull the current list from the site; it changes.
- **Retired challenges** — older `challenge-*` branches no longer on the site (e.g. multisig, svg-nft, state-channels). These are real content that old `create-eth` versions or archived SRE may still pull. Keep them unless the owner explicitly says otherwise; if they must go, archive (tag then delete) rather than just delete.
- Any branch that is the head **or** base of an **open** PR — these are active work (e.g. someone's in-flight `-hhv3` or fix branches). Protected.

Everything else is a deletion candidate: scratch/test branches with no PR, and branches whose only PRs were **closed unmerged** (abandoned experiments).

## Step 1: Classify every branch

```bash
scripts/classify-branches.sh --keep "main base-challenge-template challenge-tokenization challenge-crowdfunding challenge-token-vendor challenge-dice-game challenge-dex challenge-oracles challenge-over-collateralized-lending challenge-stablecoins challenge-prediction-markets challenge-zk-voting"
```

This prints a read-only table — one row per branch — with last-commit date, author, whether it has an open PR, its PR history (none / closed-only / has-merged), and a coarse bucket. Pass the current speedrunethereum challenge slugs (plus `main` and `base-challenge-template`) as `--keep` so they're marked canonical. Retired-challenge branches will show up as `no-PR` candidates — that's expected; the human keeps them per the policy above.

## Step 2: Decide the delete list with the human

Walk the table with the user and sort candidates into:

- **Scratch / no-PR** — test branches, accidental branches, abandoned spikes with no PR. Usually safe to delete.
- **Closed-PR-only** — someone opened a PR, it was closed without merging. The work lives only on the branch. Deletable, but if it belongs to **another maintainer**, give them a heads-up before deleting — you'd be erasing their unmerged experiment (recoverable, but still). Don't unilaterally nuke a colleague's closed-PR branches.
- **Retired challenges** — keep (see policy).

Present the candidates and get explicit approval on the final list. This is the human gate; don't skip it.

## Step 3: Record SHAs, then delete

Always snapshot the tips before deleting so any branch is a one-command restore:

```bash
scripts/delete-branches.sh <branch1> <branch2> ...
```

The script writes every branch's tip SHA to a dated recovery file (printed at the end) before running `git push origin --delete`, and prints the exact restore command. GitHub also retains deleted refs for ~90 days, but the recovery file makes restoration trivial regardless:

```bash
git push origin <sha>:refs/heads/<branch>
```

## Step 4: Verify

```bash
git fetch origin --prune
git for-each-ref --format='%(refname:short)' refs/remotes/origin | grep -v origin/HEAD | wc -l
```

Confirm the remaining set matches the keep policy and nothing protected was touched.

## Notes

- **Run the scripts under bash, not zsh.** They word-split the space-separated branch lists; zsh doesn't split unquoted variables and the loops silently run once. The shebangs handle it, but don't paste loop bodies into a zsh prompt.
- Cadence: run on demand — after a batch of PRs merge, or monthly. There's no value in a tighter schedule, and deletion on a shared public repo always wants a human in the loop.
