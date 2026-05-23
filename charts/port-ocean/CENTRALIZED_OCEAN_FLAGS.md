# Centralized Ocean Flag Configuration Guide

## Overview

This guide documents the configuration flags introduced in port-ocean 0.17.0 that control processing mode selection and lakehouse integration.

## Configuration Flags

### `processingMode`
- **Environment Variable**: `OCEAN__PROCESSING_MODE`
- **Helm Value**: `processingMode`
- **Type**: String (enum)
- **Valid Values**: 
  - `dsp` — Centralized Ocean (Data Source Processor mode)
  - `ocean-core` — Legacy processing (default for backwards compatibility)
- **Default**: `dsp` (as of port-ocean 0.17.0)

### `lakehouseEnabled`
- **Environment Variable**: `OCEAN__LAKEHOUSE_ENABLED`
- **Helm Value**: `lakehouseEnabled`
- **Type**: Boolean
- **Default**: `true` (as of port-ocean 0.17.0)

## Valid Configuration Combinations

| processingMode | lakehouseEnabled | Status | Notes |
|---|---|---|---|
| `dsp` | `true` | ✅ **Valid** | Centralized Ocean with lakehouse storage |
| `dsp` | `false` | ❌ **Invalid** | Will silently degrade to ocean-core |
| `ocean-core` | `true` | ⚠️ Allowed | Legacy mode with unused lakehouse flag |
| `ocean-core` | `false` | ✅ **Valid** | Legacy processing mode |

## Important: Silent Degradation Risk

⚠️ **CRITICAL**: If you set `processingMode: dsp` without `lakehouseEnabled: true`, Ocean will:
1. Log a warning message
2. **Silently disable DSP mode**
3. Fall back to legacy ocean-core processing
4. **Operator may not notice** — only a warning is logged

### Example of Silent Degradation
```yaml
# ❌ This configuration will silently degrade to ocean-core mode
processingMode: dsp
lakehouseEnabled: false

# Ocean will:
# - Log: WARNING - DSP mode requested but lakehouse_enabled is false
# - Disable DSP mode
# - Use legacy ocean-core processing
# - Operator thinks DSP is enabled, but it's NOT
```

## Correct Configurations

### Enable Centralized Ocean (Recommended as of 0.17.0)
```yaml
processingMode: dsp
lakehouseEnabled: true
```

### Use Legacy Processing
```yaml
processingMode: ocean-core
lakehouseEnabled: false
```

## Deployment Location

These flags are set in three ConfigMaps (automatically generated from `values.yaml`):

1. **Main Ocean Deployment ConfigMap** (`configmap.yaml`)
   - `OCEAN__PROCESSING_MODE`
   - `OCEAN__LAKEHOUSE_ENABLED`

2. **Live Events ConfigMap** (`configmap-live-events.yaml`)
   - `OCEAN__PROCESSING_MODE`
   - `OCEAN__LAKEHOUSE_ENABLED`

3. **Actions Processor ConfigMap** (`actions-processor/configmap.yaml`)
   - `OCEAN__PROCESSING_MODE`
   - `OCEAN__LAKEHOUSE_ENABLED`

## When to Use Each Mode

### Centralized Ocean (`dsp` + `lakehouseEnabled: true`)
- **Best for**: Modern deployments where you want to use Port's managed processing infrastructure
- **Requirements**: 
  - Port organization must have Centralized Ocean enabled
  - Reliable network connectivity to `ingest.getport.io`
  - Lakehouse feature access in your Port account

### Legacy Mode (`ocean-core` + `lakehouseEnabled: false`)
- **Use when**: 
  - Your Port org doesn't support Centralized Ocean yet
  - You need isolated, on-prem processing for compliance
  - You're gradually migrating integrations

## Related Configuration

### Lifecycle URL
- **Note**: As of Ocean PR #3247, Ocean uses only `OCEAN__PORT__INGEST_URL` for lifecycle callbacks
- **No longer used**: `OCEAN__PORT__LIFECYCLE_URL` has been deprecated
- **Default ingest URL**: `https://ingest.getport.io`

## Troubleshooting

### Symptoms: DSP mode not working as expected

**Check 1: Verify both flags are set correctly**
```bash
kubectl get configmap -n port-ocean ocean-configmap -o jsonpath='{.data.OCEAN__PROCESSING_MODE}'
kubectl get configmap -n port-ocean ocean-configmap -o jsonpath='{.data.OCEAN__LAKEHOUSE_ENABLED}'
```

Expected output:
```
dsp        # processingMode
true       # lakehouseEnabled
```

**Check 2: Look for warning logs**
```bash
kubectl logs -n port-ocean deployment/ocean -f | grep -i "dsp mode"
```

If you see `WARNING - DSP mode requested but lakehouse_enabled is false`, your configuration is invalid.

## Known Issues

- **Issue #13129 (Port repo)**: Ocean silently downgrades `dsp` mode to `ocean-core` when `lakehouseEnabled` is not `true`. No exception is raised — only a warning is logged.
  - **Status**: Awaiting fix in Ocean repository
  - **Workaround**: Ensure both flags are set consistently when enabling Centralized Ocean

## References

- **helm-charts PR #284**: Introduced processingMode and lakehouseEnabled defaults
- **infra-apps PR #2256**: Updated wrapper charts to port-ocean 0.17.0
- **Ocean PR #3247**: Changed lifecycle client to use ingest_url only
- **GitHub Issue #13129**: Validation gap for invalid flag combinations
