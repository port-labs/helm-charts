# Port Ocean Architecture Guide for Support Teams

## Overview

This document provides an in-depth technical explanation of the Port Ocean Helm chart architecture, specifically focusing on the CronJob-based resync pattern combined with live events and actions processing deployments.

## Recommended Production Architecture

The recommended architecture for production deployments consists of three independent Kubernetes workloads:

```
┌─────────────────────────────────────────────────────────────────┐
│                   Port Ocean Integration Stack                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────────┐   ┌──────────────────┐   ┌──────────────┐ │
│  │   CronJob        │   │ Live Events      │   │   Actions    │ │
│  │   Resync         │   │ Worker Dep't     │   │   Processor  │ │
│  │                  │   │                  │   │   Dep't      │ │
│  │ (Scheduled)      │   │ (Always Running) │   │   (Running)  │ │
│  └──────────────────┘   └──────────────────┘   └──────────────┘ │
│          ▲                      ▲                      ▲          │
│          │                      │                      │          │
│    Runs on cron            Accepts webhooks       Processes      │
│    (e.g., hourly)          from integrations      Port actions   │
│    Periodic sync           Real-time events       (bi-directional)
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
                  ┌───────────────────────┐
                  │   Port API / Ingest   │
                  │   (port.getport.io)   │
                  └───────────────────────┘
```

## Component Deep Dive

### 1. CronJob - Scheduled Resync

**Purpose**: Periodic polling of data from third-party systems at defined intervals

#### Configuration
```yaml
workload:
  kind: "CronJob"
  cron:
    resyncTimeoutMinutes: 60
    resyncOnInstall: true
    resyncOnUpgrade: true
    suspend: false
    failedJobsHistoryLimit: 1
    successfulJobsHistoryLimit: 1

scheduledResyncInterval: "0 */1 * * *"  # Every hour (cron format)
```

#### How It Works

1. **Scheduling**: Kubernetes CronJob controller triggers a new Job at the specified cron schedule
   - Cron format: `minute hour day month day-of-week`
   - Example: `"0 */6 * * *"` = Every 6 hours at minute 0
   - Example: `"0 0 * * *"` = Daily at midnight

2. **Job Execution**:
   - A new Pod is created with the Ocean integration container
   - The container reads from the integration configuration and secrets
   - It polls the third-party system API for data
   - Data is transformed via JQ mappings
   - Results are sent to Port API via ingest endpoint

3. **Job Lifecycle**:
   - Pod runs until completion (typically 5-30 minutes depending on data volume)
   - `resyncTimeoutMinutes` (e.g., 60 min) acts as an upper timeout - if reached, job is terminated
   - Upon completion, pod terminates (no lingering processes)
   - CronJob controller cleans up old completed/failed Jobs based on `successfulJobsHistoryLimit` and `failedJobsHistoryLimit`

4. **Resource Efficiency**:
   - **Pros**: Only consumes resources during execution window, no idle pods
   - **Cons**: Cold starts, potential latency between scheduled runs

#### CronJob Init Container for Service Account Management

The CronJob includes a special init container that automatically:
- Creates a service account for kubectl operations if needed
- Uses the init container service account to interact with Kubernetes API
- Cleans up resources as needed

```yaml
workload:
  cron:
    initContainer:
      serviceAccount:
        name: ""  # Auto-generated if empty: {integration.type}-{integration.identifier}-sa
    kubectlImage: bitnamisecure/kubectl:latest
```

#### Troubleshooting CronJob

- **Job never runs**: Check `suspend: false` and cron schedule syntax
- **Job runs but fails**: Check logs: `kubectl logs -n port-ocean <job-name>`
- **Stuck jobs**: Verify `resyncTimeoutMinutes` is appropriate for data volume
- **Memory issues**: Increase resource limits in `resources.limits.memory`

### 2. Live Events Worker Deployment

**Purpose**: Real-time event processing via webhook ingestion

#### Configuration
```yaml
liveEvents:
  baseUrl: "https://live-events.mycompany.com"  # External webhook URL
  worker:
    enabled: true
    replicaCount: 2  # Can scale horizontally
    initializePortResources: false
    resources:
      requests:
        memory: "512Mi"
        cpu: "200m"
      limits:
        memory: "1024Mi"
        cpu: "500m"
  deployment:
    rolloutStrategy:
      type: RollingUpdate
      rollingUpdate:
        maxSurge: 25%
        maxUnavailable: 25%
    revisionHistoryLimit: 1
  service:
    enabled: true
    type: ClusterIP
    port: 8000
    portName: ocean-port
```

#### How It Works

1. **Service Setup**:
   - Kubernetes Service exposes port 8000 on ClusterIP
   - Ingress optional - routes external webhook traffic to service
   - Multiple replicas (e.g., 2) for high availability and load balancing

2. **Event Flow**:
   ```
   Third-Party System
        │
        │ (Webhook POST to baseUrl)
        ▼
   Ingress (if enabled)
        │
        ▼
   K8s Service (port 8000)
        │
        ├─► Live Events Pod #1 (replica 1)
        │
        └─► Live Events Pod #2 (replica 2)
        │
        ▼
   Event Transformation (JQ mapping)
        │
        ▼
   Port Ingest API
   ```

3. **Persistent Pods**:
   - Pods run continuously (unlike CronJob)
   - Ready to receive webhooks immediately (no cold start)
   - Connection pooling to Port API
   - Handles high-frequency event bursts

4. **Scaling Strategy**:
   - Horizontal scaling: Increase `replicaCount` for higher webhook throughput
   - Each pod handles independent webhook requests
   - Kubernetes Service distributes traffic via round-robin

#### Ingress Configuration for Live Events

For external webhook delivery:

```yaml
liveEvents:
  baseUrl: "https://webhook.company.com/live-events"
  ingress:
    enabled: true
    className: "nginx"
    host: "webhook.company.com"
    path: "/live-events"
    pathType: Prefix
    annotations:
      cert-manager.io/cluster-issuer: "letsencrypt-prod"
```

The third-party system must be configured to send webhooks to this `baseUrl`.

#### Troubleshooting Live Events

- **Webhooks not received**: Verify `baseUrl` is reachable, check Ingress configuration
- **Events not processing**: Check pod logs: `kubectl logs -n port-ocean deployment/port-ocean-live-events`
- **High latency**: Check Pod CPU/memory usage, consider increasing replicas
- **Connection timeouts**: Verify network policies allow outbound connections to Port API

### 3. Actions Processor Deployment

**Purpose**: Bi-directional integration for Port action execution

#### Configuration
```yaml
actionsProcessor:
  enabled: true
  worker:
    enabled: true
    rolloutStrategy:
      type: Recreate
    revisionHistoryLimit: 1
    replicaCount: 1  # Currently single-replica due to state management
    initializePortResources: false
    resources:
      requests:
        memory: "256Mi"
        cpu: "100m"
      limits:
        memory: "512Mi"
        cpu: "200m"
  service:
    enabled: true
    type: ClusterIP
    port: 8000
    portName: ocean-port
```

#### How It Works

1. **Action Registration**:
   - Port Ocean automatically registers available actions with Port API
   - Actions are defined in integration configuration
   - Port UI displays actions for end users

2. **Action Execution Flow**:
   ```
   Port UI User Triggers Action
        │
        ▼
   Port API Webhook
        │
        ▼
   K8s Service (Actions Processor)
        │
        ▼
   Actions Processor Pod
        │
        ├─► Execute action on target system
        │   (API call, script, etc.)
        │
        ├─► Receive response
        │
        ▼
   Report status back to Port
   ```

3. **State Considerations**:
   - **Single replica** (replicaCount: 1) for state consistency
   - Rollout strategy: `Recreate` (not Rolling) to avoid split-brain scenarios
   - No horizontal scaling recommended (maintains action ordering, idempotency)

4. **Resource Efficiency**:
   - Lower resource requirements than other components
   - Lightweight, mostly I/O bound
   - Can run on smaller nodes

#### Troubleshooting Actions Processor

- **Actions not visible in Port UI**: Verify `actionsProcessor.enabled: true`, check initialization logs
- **Action execution fails**: Check pod logs: `kubectl logs -n port-ocean deployment/port-ocean-actions-processor`
- **Timeout during action**: Increase pod resource limits or target system timeout
- **Multiple replicas causing issues**: Ensure only 1 replica configured

## PostgreSQL Integration (Optional)

When enabled, PostgreSQL serves as a state store for integrations that require persistence:

```yaml
postgresql:
  enabled: true
  global:
    postgresql:
      auth:
        database: ocean
        username: port_admin
        password: your-secure-password
```

### Initialization Flow with PostgreSQL

All workloads (CronJob, Live Events, Actions) include an init container:

```yaml
initContainers:
  - name: wait-for-postgresql
    image: bitnamisecure/postgresql:latest
    command:
      - sh
      - -c
      - |
        until pg_isready -h postgresql -p 5432; do
          echo 'Waiting for PostgreSQL...'
          sleep 2
        done
```

**Process**:
1. Pod starts
2. Init container blocks until PostgreSQL responds to `pg_isready`
3. Main container starts only after DB is accessible
4. Prevents connection errors on pod initialization

## Architecture Decision Matrix

Choose your architecture based on these factors:

| Requirement | CronJob | Live Events | Actions Processor | Recommendation |
|---|---|---|---|---|
| **Continuous polling** | ✓ Only runs on schedule | ✗ | ✗ | Use CronJob with frequent schedule |
| **Real-time webhooks** | ✗ Polling lag | ✓ Immediate | ✗ | Always enable for webhook-based systems |
| **Bi-directional actions** | ✗ No | ✗ No | ✓ Required | Enable if Port needs to execute commands |
| **High event throughput** | ✗ | ✓ Horizontal scale | ✗ Single replica | Use Live Events + increase replicas |
| **Cost optimization** | ✓ Idle-free | ✗ Always running | ✗ Always running | Prefer CronJob for periodic-only sync |
| **Low latency ingestion** | ✗ Batch every N min | ✓ <100ms | ✗ | Use Live Events for real-time |
| **Data consistency** | ✓ Scheduled sync | ~ Eventual | ✓ Transactional | Combine all three for best results |

## Performance Tuning

### Resource Allocation

```yaml
# For Large Dataset Syncs (CronJob)
resources:
  requests:
    memory: "1Gi"
    cpu: "500m"
  limits:
    memory: "2Gi"
    cpu: "1000m"

# For High-Throughput Webhooks (Live Events)
liveEvents:
  worker:
    replicaCount: 3  # Increase as needed
    resources:
      requests:
        memory: "768Mi"
        cpu: "300m"
      limits:
        memory: "1536Mi"
        cpu: "600m"
```

### Cron Schedule Optimization

```yaml
# Light load (small dataset)
scheduledResyncInterval: "0 */4 * * *"  # Every 4 hours

# Medium load (standard dataset)
scheduledResyncInterval: "0 */1 * * *"  # Hourly

# Heavy load (large dataset, long sync time)
scheduledResyncInterval: "0 0 * * *"    # Daily at midnight

# Continuous polling (real-time requirement)
# Use Live Events + Actions instead of CronJob
```

### Timeout Configuration

```yaml
workload:
  cron:
    resyncTimeoutMinutes: 120  # Data sync takes ~90 min
    
# Formula: Set to 1.5x expected sync time
```

## Monitoring & Logging

### Viewing CronJob Status
```bash
# List all CronJob executions
kubectl get cronjobs -n port-ocean

# View recent jobs
kubectl get jobs -n port-ocean --sort-by='.metadata.creationTimestamp'

# View job logs
kubectl logs -n port-ocean job/<job-name>

# Describe a failed job
kubectl describe job -n port-ocean <job-name>
```

### Viewing Live Events Pod Status
```bash
# List live events pods
kubectl get pods -n port-ocean -l app=port-ocean-live-events

# Stream logs from live events
kubectl logs -n port-ocean -f deployment/port-ocean-live-events

# Check readiness
kubectl describe pod -n port-ocean <pod-name>
```

### Viewing Actions Processor Status
```bash
# Check actions processor
kubectl get pods -n port-ocean -l app=port-ocean-actions-processor

# View action execution logs
kubectl logs -n port-ocean deployment/port-ocean-actions-processor -f
```

## Common Issues and Solutions

### Issue: CronJob never runs
**Cause**: Suspend flag is true or schedule is invalid
**Solution**:
```yaml
workload:
  cron:
    suspend: false  # Ensure not suspended

scheduledResyncInterval: "0 */1 * * *"  # Valid cron format
```

### Issue: Live events pods crash with OOM
**Cause**: Webhook throughput exceeds memory capacity
**Solution**:
```yaml
liveEvents:
  worker:
    replicaCount: 3  # Increase replicas
    resources:
      limits:
        memory: "2Gi"  # Increase per-pod memory
```

### Issue: Actions not triggering
**Cause**: Actions Processor disabled or not initialized
**Solution**:
```yaml
actionsProcessor:
  enabled: true
  worker:
    enabled: true
    initializePortResources: false  # Only init once
```

### Issue: Data sync takes longer than cron interval
**Cause**: Insufficient timeout or resync interval too aggressive
**Solution**:
```yaml
workload:
  cron:
    resyncTimeoutMinutes: 150  # Increase timeout

# Also consider longer intervals if data doesn't change frequently
scheduledResyncInterval: "0 0 * * *"  # Daily instead of hourly
```

### Issue: Database connection failures
**Cause**: PostgreSQL not ready or incorrect credentials
**Solution**:
```bash
# Check PostgreSQL pod status
kubectl get pods -n port-ocean | grep postgres

# Check connection string
kubectl exec -n port-ocean <integration-pod> -- \
  psql -h postgresql -U port_admin -d ocean -c "SELECT 1;"
```

## Security Considerations

1. **Secret Management**:
   - Store integration secrets in Kubernetes Secrets
   - Use `secret.useExistingSecret` for sensitive credentials
   - Rotate secrets regularly

2. **Service Accounts**:
   - Use minimal RBAC permissions
   - Enable pod security policies for CronJob service accounts

3. **Network Policies**:
   - Restrict outbound to Port API only
   - Allow ingress only from trusted webhook sources for Live Events

4. **PostgreSQL Security**:
   - Use strong passwords in production
   - Enable SSL/TLS for database connections
   - Restrict database access via network policies

## Conclusion

The recommended production architecture combines:
- **CronJob** for scheduled, periodic data synchronization
- **Live Events Worker** for real-time webhook ingestion
- **Actions Processor** for bi-directional Port action execution

This approach provides:
- ✓ Resilience through separation of concerns
- ✓ Scalability for webhook throughput
- ✓ Efficiency through optimized resource usage
- ✓ Consistency through scheduled and event-driven sync


