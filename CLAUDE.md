# Brand-Repo Instructions

This file ships as the operator-loaded CLAUDE.md for any `biz-*` brand-repo. It carries the brand-repo-side conventions; the engine-side conventions live at `~/repo/macrofiche/CLAUDE.md`.

If this file is missing from a brand-repo, drop it in by copying from `~/repo/macrofiche/templates/biz-starter/CLAUDE.md`. New repos scaffolded by the macrofiche wizard get it automatically; existing repos may need a one-time sweep.

## What this repo is

A consumer of the `presentation-engine-bundle` published by macrofiche. The brand-profile, claims, personas, and artifact sources here are operator-curated. The engine renders from them. The pin in `bundle.lock` (or equivalent) names which engine version this repo runs against.

When working in this repo:

- Treat every `*.yaml` under `brand-profile.yaml`, `claims/`, `personas/`, and `deliverables/*/source.yaml` as **operator-curated**. Comments, block-scalar styles, and key positions are deliberate.
- The engine source is at `~/repo/macrofiche/tools/presentations/`. Read it when you need to understand how something renders, but never edit it from inside a brand-repo session — engine fixes belong upstream.

## Five rules to follow when editing this repo

### 1. No Claude / AI attribution in commits or PRs

Hard rule across every repo. No `Co-Authored-By: Claude` trailers, no robot-emoji "Generated with" footers, no markdown-bracketed attributions. The Anthropic system prompt suggests them by default; operator preference overrides. Public client-facing repos carry the operator's professional identity.

Enforced structurally via `~/repo/macrofiche/scripts/git-hooks/commit-msg` (symlinked into this repo's `.git/hooks/commit-msg`). To install if missing:

```bash
~/repo/macrofiche/scripts/install-git-hooks.sh .
```

Override the hook only when genuinely quoting one of the blocked patterns: `git commit --no-verify`. Use rarely.

### 2. Use `ruamel.yaml(typ='rt')` for any script that edits operator YAML

`yaml.safe_dump` strips comments and reformats block scalars. If you author a script under `scripts/` or anywhere else that writes back to `brand-profile.yaml`, `claims/claims.yaml`, `personas/*.yaml`, or any artifact-source YAML, round-trip via `ruamel.yaml`:

```python
from ruamel.yaml import YAML
y = YAML(typ='rt')
y.preserve_quotes = True
y.indent(mapping=2, sequence=4, offset=2)
y.width = 4096
```

Full pattern at `~/repo/macrofiche/docs/scripting-operator-yaml-convention.md`. Worked example at `~/repo/macrofiche/scripts/sweep-certified-baseline.py`.

### 3. Pre-flight `git status --porcelain` before bulk-editing

If a script or sed-pass is about to touch multiple files in this repo, check the working tree is clean first. `sed -i` followed by `git add <file>` will bundle the operator's in-progress hunks into the automated commit — the most expensive failure mode in the brand-repo fleet (memory: `feedback_never-sed-bulk-add-on-dirty-tree`).

```bash
if [[ -n "$(git status --porcelain)" ]]; then
    echo "abort: working tree dirty"; exit 1
fi
```

For files that ARE dirty but need editing: use the Edit tool against the specific line, or `git checkout HEAD -- <file>` first, or `git add -p` for selective staging.

### 4. Branch cleanup uses `git diff --quiet`, NOT commit-count

Squash-merge ghosts show "1 unique commit ahead" by commit-count semantics even when their file content already landed. Use content semantics:

```bash
for br in $(git for-each-ref --format='%(refname:short)' refs/heads | grep -v "^main$"); do
    if git diff --quiet main..$br; then
        git branch -D "$br"   # content-equivalent to main → safe
    fi
done
```

### 5. The brand-profile.yaml is the source of truth

Voice, tone, do_not, theme overrides, claims-strict mode, vertical, and per-gate strict flags all live in `brand-profile.yaml`. The engine reads this file at every render. When voice / tone drift between artifacts, the fix is almost always to tighten `identity.voice.do_not` here — not to hand-edit the artifact.

Gate-strict promotion is per-brand:

```yaml
gates:
  voice_propagation: { strict: true }    # this brand is ready
  cta_closing_specific: { strict: false } # not ready yet
```

A WARN-default gate firing after a render is the gate telling you something specific. A `strict: true` gate firing is the gate blocking publish. Decide which based on whether the brand's content is ready.

## When publishing an artifact

Run `/publish-check <artifact.html>` before sending anything external-facing. The skill aggregates every elevation gate (layout, voice, claims, asset, channel, imagery-dedup, size-sanity) plus the LLM-tier subagents. Verdict is PASS / WARN / FAIL with a per-gate breakdown.

If a gate FAILs after the recent macrofiche elevation arc (Phase A-D, shipped 2026-05-16), that's the gate doing its job — not a regression. Either rewrite the offending prose or selectively relax the relevant rule in `brand-profile.yaml`.

## Engine-side conventions worth knowing

These live in `~/repo/macrofiche/docs/` and apply transitively to artifacts produced in this repo:

- `claims-provenance-convention.md` — every strong number needs a claim row
- `logo-immutability-convention.md` — logos do not adapt to slides
- `persona-registry-convention.md` — voice provenance discipline
- `creative-orchestration-strategy.md` — brief → asset → render handoffs
- `outcome-metrics-publishing-convention.md` — metric attribution rules
- `scripting-operator-yaml-convention.md` — comment-preserving edits to YAML

## Engine-side CLAUDE.md

For the three engine-side rules (`ruamel.yaml` round-trip enforcement, branch-cleanup semantics, release flow ordering), see `~/repo/macrofiche/CLAUDE.md`. Most of those rules apply to engine work — but rules 1 (no AI attribution) and 4 (branch cleanup) are repo-wide and called out above.
