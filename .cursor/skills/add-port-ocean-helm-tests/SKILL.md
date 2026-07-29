---
name: add-port-ocean-helm-tests
description: Adds or updates focused tests for behavior-changing Port Ocean Helm chart work. Use automatically when changing charts/port-ocean templates, resources, rendering conditions, values, dependencies, or resource naming; skip documentation, version-only, and formatting-only changes.
---

# Add Port Ocean Helm Tests

## When tests are needed

Add or update tests when a `charts/port-ocean` change affects rendered Kubernetes manifests:

- A chart, template, resource, value, dependency, or conditional is added or changed.
- A feature supports distinct deployment modes or resource combinations.
- Naming, truncation, labels, selectors, secrets, or configuration references change.

Skip new tests for documentation-only, version-only, or formatting-only changes.

## Pattern

Use the repository's `helm-unittest` convention. Do not add a long Bash assertion script or a second test framework.

1. Add a focused values fixture in `charts/port-ocean/tests/values/` for each architecture or behavior.
2. Add or update a `charts/port-ocean/tests/*_test.yaml` suite. Test one template or resource family per suite.
3. Assert both rendered and intentionally absent resources for each relevant mode.
4. Prefer exact assertions for resource names and critical fields. Do not use snapshots unless the full manifest is the contract.
5. Add `tests/` to the chart's `.helmignore` if it is not already excluded.

Example:

```yaml
suite: Resync CronJob
templates:
  - templates/cron-job/cron.yaml
tests:
  - it: renders for hybrid architecture
    values:
      - values/hybrid-cron.yaml
    asserts:
      - hasDocuments:
          count: 1
      - equal:
          path: metadata.name
          value: ocean-github-test-id-cron-job
```

## Validation

Run:

```bash
helm unittest charts/port-ocean --strict
helm lint charts/port-ocean
for values_file in charts/port-ocean/tests/values/*.yaml; do
  helm template test charts/port-ocean --values "$values_file" |
    kubectl apply --dry-run=client -f -
done
```

Keep CI running `helm unittest ... --strict` and Kubernetes client dry-run validation for every values fixture.
