# Ocean Gateway

Ocean Gateway is a stateless live-event webhook ingress for on-premises Port Ocean
deployments. It accepts provider webhooks and writes them synchronously to Redis
Streams, which Ocean integrations consume via `XREADGROUP`.

## Introduction

This chart installs Ocean Gateway via a `Deployment` resource. Optionally deploy a
bundled Redis instance (Bitnami subchart) or connect to an existing Redis cluster.

## Usage

[Helm](https://helm.sh) must be installed to use the charts. Please refer to
Helm's [documentation](https://helm.sh/docs) to get started.

Once Helm has been set up correctly, add the repo as follows:

    helm repo add port-labs https://port-labs.github.io/helm-charts

If you had already added this repo earlier, run `helm repo update` to retrieve
the latest versions of the packages. You can then run `helm search repo
port-labs` to see the charts.

### With bundled Redis

For clusters without an existing Redis instance:

```bash
helm upgrade --install ocean-gateway port-labs/ocean-gateway \
  --create-namespace --namespace ocean-gateway \
  --set redis.enabled=true \
  --set redis.auth.password=<strong-password> \
  --set ingress.enabled=true \
  --set ingress.className=nginx \
  --set ingress.host=gateway.example.com
```

### With external Redis

```bash
helm upgrade --install ocean-gateway port-labs/ocean-gateway \
  --create-namespace --namespace ocean-gateway \
  --set redis.url=redis.example.svc.cluster.local:6379 \
  --set redis.password=<password> \
  --set ingress.enabled=true \
  --set ingress.className=nginx \
  --set ingress.host=gateway.example.com
```

Configure webhook providers to POST to:

```
https://gateway.example.com/live-events/<liveEventsUUID>/integration/<webhookSuffix>
```

Ocean integrations must use the **same Redis** instance. See the
[port-ocean chart](../port-ocean/README.md) for live-events consumer configuration.

To uninstall the chart:

    helm uninstall ocean-gateway --namespace ocean-gateway

## Configuration

The following table lists the main configuration parameters and default values.

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of gateway replicas (ignored when autoscaling is enabled) | `1` |
| `image.repository` | Gateway image repository | `ghcr.io/port-labs/ocean-gateway` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `image.tag` | Image tag (defaults to chart `appVersion` when empty) | `""` |
| `imagePullSecrets` | Image pull secrets | `[]` |
| `redis.enabled` | Deploy bundled Bitnami Redis | `false` |
| `redis.url` | External Redis address (`host:port`). Required when `redis.enabled=false` and `redis.existingSecret` is unset | `""` |
| `redis.username` | External Redis username (stored in a Secret when set) | `""` |
| `redis.password` | External Redis password (stored in a Secret when set) | `""` |
| `redis.existingSecret` | Pre-existing Secret with `REDIS_OCEAN_GATEWAY_URL` / `_USERNAME` / `_PASSWORD` | `""` |
| `redis.auth.password` | Bundled Redis password (also used by the gateway when `redis.enabled=true`) | `"changeme"` |
| `redis.master.persistence.enabled` | Enable persistence for bundled Redis | `true` |
| `redis.master.persistence.size` | PVC size for bundled Redis | `8Gi` |
| `stream.eventTTL` | Trim stream entries older than this via `XADD MINID` | `"1h"` |
| `stream.streamTTL` | Idle stream key expiry, refreshed on each write | `"1h"` |
| `stream.maxLen` | Approx `MAXLEN` per stream (ignored when `eventTTL` > 0) | `0` |
| `write.maxRetries` | Per-request `XADD` retries before returning 503 | `2` |
| `write.backoffBase` | Initial retry backoff | `"50ms"` |
| `service.type` | Kubernetes Service type | `ClusterIP` |
| `service.port` | Service and container HTTP port | `8080` |
| `ingress.enabled` | Enable Ingress for external webhook providers | `false` |
| `ingress.className` | Ingress class name | `""` |
| `ingress.annotations` | Ingress annotations | `{}` |
| `ingress.host` | Ingress hostname (required when ingress is enabled) | `null` |
| `ingress.path` | Ingress path | `/` |
| `ingress.pathType` | Ingress path type | `Prefix` |
| `ingress.tls` | Ingress TLS configuration | `[]` |
| `autoscaling.enabled` | Enable Horizontal Pod Autoscaler | `false` |
| `autoscaling.minReplicas` | HPA minimum replicas | `1` |
| `autoscaling.maxReplicas` | HPA maximum replicas | `10` |
| `autoscaling.targetCPUUtilizationPercentage` | HPA CPU target | `80` |
| `resources` | Container resource requests and limits | see `values.yaml` |
| `livenessProbe.enabled` | Enable liveness probe (`/healthz`) | `true` |
| `readinessProbe.enabled` | Enable readiness probe (`/healthz`) | `true` |

## Producer contract

| Status | Meaning |
|--------|---------|
| `202 Accepted` | Event is durably stored in the Redis stream |
| `503` | Redis temporarily unavailable — producer must retry |

## Source

Application source code: https://github.com/port-labs/ocean-gateway
