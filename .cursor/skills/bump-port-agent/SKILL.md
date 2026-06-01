---
name: bump-port-agent
description: Bump port-agent Helm chart appVersion and image tag to match port-labs/port-agent GitHub releases. Lists releases, diffs against Chart.yaml appVersion, compares app/core/config.py Settings to values.yaml, detects stale helm env keys, classifies breaking vs notable changes, asks approval before edit. Use when user says bump port-agent, update port-agent version, sync helm chart with port-agent release, dry run port-agent bump, or upgrade appVersion.
---

# Bump port-agent (helm + image)

## Files

| File                            | What                                            |
| ------------------------------- | ----------------------------------------------- |
| `charts/port-agent/Chart.yaml`  | `version` (chart), `appVersion` (app image tag) |
| `charts/port-agent/values.yaml` | `env.normal`, `env.secret` defaults             |
| `charts/port-agent/README.md`   | install examples + config table                 |

Image: `ghcr.io/port-labs/port-agent` — tag from `appVersion` when `image.tag` empty.

## Workflow

Copy checklist, track progress:

```
- [ ] 1. Read current versions
- [ ] 2. List GH releases + pick target
- [ ] 3. Diff releases + classify breaking / notable
- [ ] 4. Diff config.py + env/docs drift + stale helm keys
- [ ] 5. Report (dry run stops here)
- [ ] 6. Apply bump (after explicit yes)
```

### 1. Current versions

```bash
grep -E '^(version|appVersion):' charts/port-agent/Chart.yaml
```

Normalize tags for compare: ensure `v` prefix (`0.8.9` → `v0.8.9`). `CURRENT` / `TARGET` must match GH release tags.

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

If chart more than one release behind TARGET, skim intermediate release notes too.

Classify findings into three tiers (report all three in step 5):

| Tier         | Examples                                                                                                                             | Blocks bump?                      |
| ------------ | ------------------------------------------------------------------------------------------------------------------------------------ | --------------------------------- |
| **Breaking** | Major semver; BREAKING/removed/deprecated in notes; `Settings` field removed/renamed; new **required** field (no default)            | Yes — need explicit yes           |
| **Notable**  | Logging/sanitization/output changes; default behavior shift with same env keys; new **optional** `Settings` field operators may want | No — inform user; README optional |
| **Internal** | Tests, CI, refactors, Dockerfile-only                                                                                                | No — skip unless user cares       |

**Breaking signals:**

| Signal                                                             | Action          |
| ------------------------------------------------------------------ | --------------- |
| Major semver (`v1.x` → `v2.x`)                                     | Breaking        |
| "breaking", "BREAKING", "removed", "deprecated" in release/commits | Breaking        |
| `Settings` field removed or renamed (`config.py` diff)             | Breaking + list |
| New required `Settings` field (no default in pydantic model)       | Breaking + list |
| Helm env key maps to removed/renamed upstream field                | Breaking + list |

**Notable signals** (do not block; mention in report):

| Signal                                                                        | Action                                                        |
| ----------------------------------------------------------------------------- | ------------------------------------------------------------- |
| Log format, redaction, verbosity (`DETAILED_LOGGING`, new `logging.py`, etc.) | Notable                                                       |
| Webhook/invoker/streamer behavior change, same env contract                   | Notable                                                       |
| New optional `Settings` field not yet in chart (`LOG_LEVEL`, `POLLING_*`, …)  | Notable — add to helm only if Port docs say operators need it |

### 4. Env + docs drift

#### 4a. Mandatory — `app/core/config.py`

Always fetch and diff. Do **not** skip when compare file list omits `config.py`.

```bash
CONFIG_PATH="app/core/config.py"
gh api "repos/port-labs/port-agent/contents/${CONFIG_PATH}?ref=${CURRENT}" --jq '.content' | base64 -d > /tmp/port-agent-config-current.py
gh api "repos/port-labs/port-agent/contents/${CONFIG_PATH}?ref=${TARGET}" --jq '.content' | base64 -d > /tmp/port-agent-config-target.py
diff -u /tmp/port-agent-config-current.py /tmp/port-agent-config-target.py
```

Parse `class Settings(BaseSettings)` fields at CURRENT and TARGET. This is upstream env schema.

Also scan compare changed files under `app/**`, `README.md`, streamers — for logic tied to existing env keys.

#### 4b. Helm env keys

```bash
grep -E '^\s+[A-Z][A-Z0-9_]*:' charts/port-agent/values.yaml
```

Build two sets:

- `helm_env` — keys under `env.normal` + `env.secret`
- `settings_fields` — field names from `Settings` in config.py at TARGET

#### 4c. Stale helm env detection

| Check              | Condition                                                | Action                                                                                                                                                 |
| ------------------ | -------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Stale helm key** | In `helm_env` but **not** in `settings_fields` at TARGET | Warn: likely dead config (e.g. legacy `GITLAB_URL`). Propose remove from `values.yaml` + README **only** with user approval — not auto on routine bump |
| **App-only field** | In `settings_fields` but not in `helm_env`               | Info only. Flag if **new in this release** or Port docs require operator config; else skip (many internal defaults exist)                              |
| **Release delta**  | Field added/removed/renamed in `config.py` diff          | Drive breaking/notable tier + helm/README updates                                                                                                      |

```bash
# optional: confirm stale key unused upstream
gh api "search/code?q=${KEY}+repo:port-labs/port-agent" --jq '.total_count'
```

#### 4d. Docs checklist

- [ ] New `Settings` field operators need → `values.yaml` + README table row
- [ ] Renamed field → values + README + templates (`_helpers.tpl`, `secret.yaml`)
- [ ] Removed field → values + README; **breaking**
- [ ] README install/`--set` examples match required vars
- [ ] Streamer docs (`KAFKA` / `POLLING`) if streamer code touched

Do **not** bump `values.yaml` for unrelated chart-only tweaks or to expose every `Settings` field.

### 5. Report + approval

Show user:

1. `CURRENT` → `TARGET`
2. Release summary (`gh release view`)
3. **Breaking** (or none)
4. **Notable** (or none)
5. **Stale helm keys** (or none)
6. Proposed edits:
   - `Chart.yaml`: `appVersion: "<TARGET>"`, `version:` patch +1
   - `values.yaml` / `README.md` only if drift or approved stale-key cleanup
7. Commits not made unless user asked

If there are any breaking changes -- **Ask:** "Proceed with bump?" — required before step 6. On breaking items, call them out explicitly.

### 6. Apply (after yes only)

```yaml
# Chart.yaml example
version: 0.8.15 # chart semver: patch +1 typical
appVersion: "v0.8.10" # match GH release tag exactly
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

- Stale key removal = separate decision — never silent delete on routine bump
- `gh` need auth; fail → tell user login (`gh auth status`)
- Chart `version` ≠ app `appVersion`; both update on app bump
