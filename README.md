# git-sweep

Delete local git branches that are already merged into your remote's target
branch — and for the ones left behind, show their live PR status (open / draft /
closed, conflicts, review decision, approval & comment counts) so you can see at
a glance what still needs attention.

A branch counts as **merged** when either:

- its tip is an ancestor of `origin/<target>` (normal / fast-forward merges), **or**
- its GitHub PR state is `MERGED` (squash / rebase merges — which leave no shared commit).

## Usage

```bash
git sweep                      # dry-run against main: list what WOULD be deleted + status of the rest
git sweep -y                   # actually delete the merged branches
git sweep --merged-to develop  # sweep against a target branch other than main
git sweep --keep dev,release   # keep these branches even if merged
git sweep --no-fetch           # skip the opening `git fetch --prune`
git sweep -h                   # help
```

## Protecting branches

Some merged branches you want to keep anyway (a long-lived `dev`, a `release`
line). Two ways:

```bash
git sweep -y --keep dev            # one-off: keep dev for this run (comma-separated, repeatable)
git config --add sweep.protect dev # permanent, per repo: kept on every run from now on
```

Protected branches are listed under **kept** in the output and never deleted.
The target branch and the branch you're currently on are always kept
automatically.

Example output:

```
target: origin/main   current: my-feature

2 branch(es) NOT merged — status:
  fix/price-race                           #1021 open · approved · ✔2 💬3
  feat/new-panel                           #1044 draft · conflict · ✗1
  chore/tidy                               no PR

3 merged branch(es) — would delete (dry-run, pass -y to apply):
  · feat/old-thing
  · fix/shipped-bug
  · chore/done

run git sweep -y to delete them.
```

The dry-run is the default; nothing is deleted until you pass `-y`.

## Requirements

- [`git`](https://git-scm.com)
- [`gh`](https://cli.github.com) — GitHub CLI, authenticated (`gh auth login`)
- [`jq`](https://jqlang.github.io/jq/) — `brew install jq`

## Install

`git` treats any executable named `git-sweep` on your `PATH` as the `git sweep`
subcommand, so installing just means putting this repo on your `PATH` — no
symlink, no copy. `git sweep` then runs the script right here in the clone, and
a later `git pull` updates it in place.

```bash
git clone https://github.com/june-in-exile/git-sweep ~/Developer/git-sweep
~/Developer/git-sweep/install.sh
```

If the repo isn't on your `PATH` yet, `install.sh` offers to add it to your
shell config (`~/.zshrc`, `~/.bashrc`, …) — press Enter to accept. Then run
`source <that file>` and `git sweep` is ready. Pass `--yes` to skip the prompt.
It's idempotent, so re-running never duplicates the line.

Manual install instead:

```bash
# add the clone to PATH — append to ~/.zshrc:
#   export PATH="$HOME/Developer/git-sweep:$PATH"
```

## License

MIT
