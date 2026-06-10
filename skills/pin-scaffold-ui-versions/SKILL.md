---
name: pin-scaffold-ui-versions
description: "Pin scaffold-ui (or any create-eth base-template dependency) to known-good versions across every SpeedRunEthereum challenge branch, opening one PR per challenge. Use this skill when a new scaffold-ui release breaks the challenge UIs, when challenges suddenly look different after `npx create-eth`, when someone says the challenges need their scaffold-ui versions pinned/locked, or when an upstream dependency bump needs to be held back across all the se-2-challenges branches. This is a recurring break-fix that happens whenever scaffold-ui ships a UI change the challenges weren't ready for."
---

# Pin scaffold-ui versions across challenges

Hold scaffold-ui (or any other create-eth base-template dependency) at a known-good version on every SpeedRunEthereum challenge, so `npx create-eth` stops pulling a newer release that breaks the challenge UI.

**Run this from inside a clone of `scaffold-eth/se-2-challenges`** (typically at `externalExtensions/se-2-challenges` inside a `create-eth` checkout, but a standalone clone works too).

## Why this works — the create-eth merge

This is the load-bearing fact behind the whole fix. When `create-eth` instantiates a challenge, it merges the challenge's `extension/packages/nextjs/package.json` into the base template's `package.json` using the `merge-packages` library. For every dependency the extension declares, the merge resolves to:

```
semverIntersect(extensionVersion, baseVersion) || extensionVersion
```

So a hard-pinned `"0.1.11"` in the extension wins over the base template's `"^0.1.10"` — either as the intersection (the exact version sits inside the caret range) or, if the base has since moved past the pin (e.g. base is now `^0.1.12`), via the `|| extensionVersion` fallback. **The extension's pin always wins for any dependency it lists.** That's why we add the pins to each challenge's extension rather than touching npm or the base template.

The breakage happens because challenges *don't* normally list scaffold-ui at all — they inherit the base template's caret range, which silently resolves to the latest published version. One bad release and every challenge picks it up.

## Step 1: Identify the breaking release and the last-good versions

Find which versions to pin to. The target is the **last published set before the breaking release**.

```bash
# Publish timeline for each package — the newest entries are the suspects
npm view @scaffold-ui/components time --json | tail -15
npm view @scaffold-ui/debug-contracts time --json | tail -15
npm view @scaffold-ui/hooks time --json | tail -15
```

Cross-check against the create-eth base template to see what the *new* (broken) set is — the base template will usually have already bumped to it:

```bash
grep scaffold-ui <create-eth>/templates/base/packages/nextjs/package.json
```

Pin to the version *just below* the breaking one. A package whose latest version is already the last-good one (e.g. `hooks` often hasn't changed) is a harmless no-op to pin — keep it for explicitness, but know the real fix is usually `components` + `debug-contracts`. Confirm the exact versions with the user before sweeping.

## Step 2: Confirm the challenge set

The branches to fix are exactly the challenges live on [speedrunethereum.com](https://speedrunethereum.com) — each maps to a `challenge-<slug>` branch. Pull the current list from the site rather than assuming; challenges get added and renamed. The older numbered branches (`challenge-0-simple-nft`, etc.) and variant branches (`-agents-md`, `-concepts`, `-foundry`, `-hhv3`, `-ai`) are **not** served on the site — leave them alone unless the user asks.

## Step 3: Do one challenge by hand first

Don't sweep blind. Pick one challenge, make the change, and actually instantiate it to confirm the UI renders correctly before touching the rest. The merge produces the right *string* in package.json, but only a real `npx create-eth` + install proves the UI is back to normal.

The edit per branch has two shapes:

- **Challenge already has `extension/packages/nextjs/package.json`** → insert the pins at the top of `dependencies`, preserving the file's existing deps and its indentation (some challenges use 4-space, most use 2-space).
- **Challenge has no such file** → create a minimal one. These challenges were silently inheriting the broken version too, so they need the fix just as much.

A created file looks like:

```json
{
  "dependencies": {
    "@scaffold-ui/components": "0.1.11",
    "@scaffold-ui/debug-contracts": "0.1.10",
    "@scaffold-ui/hooks": "0.1.8"
  }
}
```

## Step 4: Sweep the rest with the script

Once the hand-checked challenge is confirmed, use the bundled script to apply the identical change across the remaining challenges. It handles add-vs-create and indentation per branch, validates the JSON, and (in `--dry-run`) prints every diff before anything is pushed.

```bash
# Preview every branch's diff without pushing
scripts/pin-and-pr.sh --dry-run \
  --components 0.1.11 --debug-contracts 0.1.10 --hooks 0.1.8 \
  --challenges "crowdfunding token-vendor dice-game dex oracles over-collateralized-lending stablecoins prediction-markets zk-voting"

# Looks right? Drop --dry-run to push branches and open PRs
scripts/pin-and-pr.sh \
  --components 0.1.11 --debug-contracts 0.1.10 --hooks 0.1.8 \
  --challenges "crowdfunding token-vendor dice-game dex oracles over-collateralized-lending stablecoins prediction-markets zk-voting"
```

For each challenge the script creates a `scaffold-ui-version-fix-<slug>` branch off `origin/challenge-<slug>`, commits `pin scaffold-ui versions`, pushes, and opens a PR.

## Step 5: PR conventions

Keep these consistent so the batch is scannable on the PR list:

- **Title:** `challenge-<slug>: pin scaffold-ui versions`
- **Base:** `challenge-<slug>` · **Head:** `scaffold-ui-version-fix-<slug>`
- **Commit:** `pin scaffold-ui versions`
- **Body:** none — the title says it all

After the script runs, verify the batch landed with the right base/title:

```bash
for n in <pr-numbers>; do
  gh pr view "$n" --repo scaffold-eth/se-2-challenges \
    --json number,baseRefName,title --jq '"#\(.number) -> \(.baseRefName): \(.title)"'
done
```

## Notes

- **Run the script under bash, not zsh.** It relies on word-splitting the space-separated `--challenges` list; zsh doesn't split unquoted variables and the loops silently run once. The shebang handles this, but don't paste the loop bodies into a zsh prompt.
- This is a per-branch repo with no shared `main` for the challenges, so each challenge genuinely needs its own PR — there's no single place to make the change once.
- When the underlying scaffold-ui issue is properly resolved upstream (square-UI components adopted, base template settled), these pins can be lifted in a follow-up sweep using the same script targeting the newer versions.
