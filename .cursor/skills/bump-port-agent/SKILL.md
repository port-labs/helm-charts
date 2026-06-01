---
name: bump-port-agent
description: Bump port-agent Helm chart appVersion and image tag to match port-labs/port-agent GitHub releases. Lists releases, diffs against Chart.yaml appVersion, checks values.yaml and README for env/doc drift, flags breaking changes, asks approval before edit. Use when user says bump port-agent, update port-agent version, sync helm chart with port-agent release, or upgrade appVersion.
---

# Bump port-agent (helm + image)

Caveman talk to user during this workflow. Code/commits/PR text stay normal.

## Files

| File | What |
|------|------|
| `charts/port-agent/Chart.yaml` | `version` (chart), `appVersion` (app image tag) |
| `charts/port-agent/values.yaml` | `env.normal`, `env.secret` defaults |
| `charts/port-agent/README.md` | install examples + config table |

Image: `ghcr.io/port-labs/port-agent` — tag from `appVersion` when `image.tag` empty.

## Workflow

Copy checklist, track progress:

```
- [ ] 1. Read current versions
- [ ] 2. List GH releases + pick target
- [ ] 3. Diff releases + scan breaking
- [ ] 4. Check env + docs drift
- [ ] 5. Report + ask approval
- [ ] 6. Apply bump (only after yes)
```

### 1. Current versions

```bash
grep -E '^(version|appVersion):' charts/port-agent/Chart.yaml
```

Normalize tags: `v0.8.9` and `0.8.9` same thing. Compare with `v` prefix on GH tags.

### 2. List releases

```bash
gh release list --repo port-labs/port-agent --limit 15
```

- Target = user-named tag, else **Latest**
- Already on target? Tell user. Stop unless they want chart-only bump.

### 3. Diff app releases

```bash
# CURRENT from Chart.yaml appVersion, TARGET from step 2
gh release view "$TARGET" --repo port-labs/port-agent
gh api "repos/port-labs/port-agent/compare/${CURRENT}...${TARGET}" \
  --jq '.commits[].commit.message'
gh api "repos/port-labs/port-agent/compare/${CURRENT}...${TARGET}" \
  --jq '.files[] | "\(.status)\t\(.filename)"'
```

Read full release body too (`gh release view`).

**Breaking signals** — stop at step 5, no edits until user OK:

| Signal | Action |
|--------|--------|
| Major semver jump (`v1.x` → `v2.x`) | Warn |
| "breaking", "BREAKING", "removed", "deprecated" in release/commits | Warn |
| Env var **removed** or **renamed** in port-agent | Warn + list |
| New **required** env (no default in app) | Warn + list |
| Default behavior change in app config | Warn |

Not breaking: patch/minor, new optional env, logging, internal refactors.

### 4. Env + docs drift

**Helm env keys** (source of truth for chart):

```bash
grep -E '^\s+[A-Z][A-Z0-9_]*:' charts/port-agent/values.yaml | head -40
```

**Upstream** — for each changed file from compare (priority paths):

- `app/**` (settings, config, `main.py`, streamers)
- `README.md`, `CONTRIBUTING.md`, `Dockerfile`
- anything with `environ`, `getenv`, settings models

```bash
gh api "repos/port-labs/port-agent/contents/app?ref=${TARGET}" --jq '.[].name'
# read diffs or file at TARGET vs CURRENT for env-related changes
```

Checklist:

- [ ] New env in port-agent → add to `values.yaml` `env.normal` or `env.secret` + README table row
- [ ] Renamed env → update values + README + any template refs (`templates/_helpers.tpl`, `secret.yaml`)
- [ ] Removed env → remove from values + README; **breaking** warn
- [ ] README install/`--set` examples still match required vars
- [ ] Streamer docs (`KAFKA` / `POLLING`) still accurate if streamer code touched

Do **not** bump `values.yaml` for unrelated chart-only tweaks.

### 5. Report + approval (required)

Show user (caveman OK):

1. `CURRENT` → `TARGET`
2. Short release summary (from `gh release view`)
3. Breaking table (or "none seen")
4. Proposed file edits:
   - `Chart.yaml`: `appVersion: "<TARGET>"`, `version:` patch bump (e.g. `0.8.14` → `0.8.15`)
   - `values.yaml` / `README.md` only if drift found
5. Commits not made unless user asked

**Ask:** "Proceed with bump?" — wait for explicit yes.

### 6. Apply (after yes only)

```yaml
# Chart.yaml example
version: 0.8.15        # chart semver: patch +1 typical
appVersion: "v0.8.10"  # match GH release tag exactly
```

Commit message style (repo norm):

```
chore(port-agent): bump chart version to X.Y.Z and update app version to vA.B.C
```

Optional body: README/env changes one line.

Verify:

```bash
grep -E '^(version|appVersion):' charts/port-agent/Chart.yaml
helm template test charts/port-agent --set env.normal.PORT_ORG_ID=test 2>&1 | head -5
```

## Quick commands

```bash
# all-in-one discovery
APP=$(grep '^appVersion:' charts/port-agent/Chart.yaml | awk '{print $2}' | tr -d '"')
gh release list --repo port-labs/port-agent --limit 5
echo "chart appVersion: $APP"
```

## Boundaries

- No commit/push/PR unless user ask
- No skip approval on breaking signals
- `gh` need auth; fail → tell user login (`gh auth status`)
- Chart `version` ≠ app `appVersion`; both update on app bump
