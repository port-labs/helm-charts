# Port Ocean

Port Ocean chart allow you to deploy Port intergations that were developed with [Port Ocean Framewok](https://github.com/port-labs/port-ocean.git) .

## Introduction

This chart installs any Port ocean integration and it's dependencies.

## Usage

[Helm](https://helm.sh) must be installed to use the charts.  Please refer to
Helm's [documentation](https://helm.sh/docs) to get started.

Once Helm has been set up correctly, add the repo as follows:

```bash showLineNumbers
helm repo add port-labs https://port-labs.github.io/helm-charts
```

If you had already added this repo earlier, run `helm repo update` to retrieve
the latest versions of the packages.  You can then run `helm search repo
port-labs` to see the charts.

Use your `PORT_CLIENT_ID` & `PORT_CLIENT_SECRET` to install the chart, with the following command:

```bash showLineNumbers
helm upgrade --install my-ocean-integration port-labs/port-ocean \
  --create-namespace --namespace port-ocean \
  --set integration.config.<sensitiveConfigKeyName>.key="KEY_OF_CHOICE" \
  --set integration.config.<sensitiveConfigKeyName>.type="secret" \
  --set integration.config.<sensitiveConfigKeyName>.value="INTEGRATION_SECRET" \
  --set integration.config.<notSensitiveConfigKeyName>="RAW_STRING" \
  --set integration.identifier="my-integration-identifier" \
  --set integration.triggerChannel.type="KAFKA" \
  --set integration.type="integration type (i.e pager-duty, gitlab)" \
  --set port.baseUrl="https://api.stg-01.getport.io/v1" \
  --set port.clientId.value="PORT_CLIENT_ID" \
  --set port.clientSecret.value="PORT_CLIENT_SECRET"
```

To uninstall the chart use:

    helm uninstall my-ocean-integration --namespace port-ocean

The command removes all the Kubernetes components associated with the chart and deletes the release.


## Configuration

The following table lists the configuration parameters of the `port-ocean` chart and default values.

| Parameter                             | Description                                                                                          | Default                               |
|---------------------------------------|------------------------------------------------------------------------------------------------------|---------------------------------------|
| `nameOverride`                        | Chart name override.                                                                                 | `""`                                  |
| `fullnameOverride`                    | Fully qualified app name override.                                                                   | `""`                                  |
| `port.clientId`                       | Type: secret<br>Key: PORT_CLIENT_ID<br>Value: "".<br>Client ID for Port API authentication.          |                                       |
| `port.clientSecret`                   | Type: secret<br>Key: PORT_CLIENT_SECRET<br>Value: "".<br>Client secret for Port API authentication.  |                                       |
| `port.baseUrl`                        | Base URL for the Port API.                                                                           | `https://api.getport.io/v1`           |
| `podAnnotations`                      | Annotations to be added to the pod.                                                                  | `{}`                                  |
| `podSecurityContext`                  | Security context applied to the pod.                                                                 | `{}`                                  |
| `securityContext`                     | Security context applied to the container.                                                           | `{}`                                  |
| `resources`                           | Container resource requests and limits.                                                              | `{}`                                  |
| `nodeSelector`                        | NodeSelector applied to the pod.                                                                     | `{}`                                  |
| `tolerations`                         | Tolerations applied to the pod.                                                                      | `[]`                                  |
| `affinity`                            | Affinity applied to the pod.                                                                         | `{}`                                  |
| `service.enabled`                     | Specifies whether the service is enabled or not.                                                     | `true`                                |
| `service.type`                        | Service type for the Port application.                                                               | `ClusterIP`                           |
| `service.port`                        | Port number for the service.                                                                         | `8000`                                |
| `ingress.enabled`                     | Specifies whether the ingress is enabled or not.                                                     | `false`                               |
| `ingress.annotations`                 | Annotations for the ingress object.                                                                  | `{}`                                  |
| `ingress.host`                        | Hostname for the ingress.                                                                            | `null`                                |
| `integration.identifier`              | Identifier for the integration.                                                                      | `""`                                  |
| `integration.version`                 | Version of the integration.                                                                          | `""`                                  |
| `integration.type`                    | Type of the integration. i.e (`pager-duty`)                                                                            | `""`                                  |
| `integration.config`                  | Configuration for the integration.                                                                    | `{}`                                  |
| `integration.triggerChannel.type`     | Type of the trigger channel for the integration.                                                     | `"KAFKA"`                             |

To override values in `helm install`, use either the `--set` flag.

Alternatively, you can use a YAML file that specifies the values while installing the chart. For example:

    helm install my-ocean-integration port-labs/port-ocean \
       --create-namespace --namespace port-ocean \
       -f custom_values.yaml