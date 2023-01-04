# Port K8s Exporter

Port K8s Exporter allows to list, watch and export K8s objects to Port entities of existing blueprints.

## Introduction

This chart installs the Port K8s Exporter via a `Deployment` resource.

## Usage

[Helm](https://helm.sh) must be installed to use the charts.  Please refer to
Helm's [documentation](https://helm.sh/docs) to get started.

Once Helm has been set up correctly, add the repo as follows:

    helm repo add port-labs https://port-labs.github.io/helm-charts

If you had already added this repo earlier, run `helm repo update` to retrieve
the latest versions of the packages.  You can then run `helm search repo
port-labs` to see the charts.

Next, prepare your own exporter `config.yaml` file, as explained [below](#Exporter).

Then, use the `config.yaml` and your `PORT_CLIENT_ID` & `PORT_CLIENT_SECRET` to install the chart, with the following command:

    helm install my-port-k8s-exporter port-labs/port-k8s-exporter \
        --create-namespace --namespace port-k8s-exporter \
        --set secret.secrets.portClientId=PORT_CLIENT_ID --set secret.secrets.portClientSecret=PORT_CLIENT_SECRET \
        --set-file configMap.config=config.yaml

Shortly, you should see entities reported in Port web UI and API.

To uninstall the chart use:

    helm uninstall my-port-k8s-exporter --namespace port-k8s-exporter

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Configuration

1. [Chart Config](#Chart)
2. [Exporter Config](#Exporter)

### Chart

The following table lists the configuration parameters of the `port-k8s-exporter` chart and default values.

| Parameter                             | Description                                                                                          | Default                               |
|---------------------------------------|------------------------------------------------------------------------------------------------------|---------------------------------------|
| `resyncInterval`                      | The interval in minutes before sending a sync event for all known objects                            | `0`                                   |
| `stateKey`                            | Unique state key to enable delete of stale Port entities (which not listed in `config.yaml` anymore) | `""` (when empty, replaced by uuid)   |
| `deleteDependents`                    | A flag to enable deletion of dependent Port Entities.                                                | `false`                               |
| `image.repository`                    | Image repository                                                                                     | `ghcr.io/port-labs/port-k8s-exporter` |
| `image.pullPolicy`                    | Image pull policy                                                                                    | `IfNotPresent`                        |
| `image.tag`                           | Image tag                                                                                            | `""`                                  |
| `imagePullSecrets`                    | Image pull secrets                                                                                   | `[]`                                  |
| `nameOverride`                        | Chart name override                                                                                  | `""`                                  |
| `fullnameOverride`                    | Fully qualified app name override                                                                    | `""`                                  |
| `secret.annotations`                  | Annotations for Secret object                                                                        | `{}`                                  |
| `secret.name`                         | Secret object name                                                                                   | `""`                                  |
| **`secret.secrets.portClientId`**     | **Port Client ID - Required**                                                                        | `""`                                  |
| **`secret.secrets.portClientSecret`** | **Port Client Secret - Required**                                                                    | `""`                                  |
| `configMap.annotations`               | Annotations for ConfigMap object                                                                     | `{}`                                  |
| `configMap.name`                      | ConfigMap object name                                                                                | `""`                                  |
| **`configMap.config`**                | **Port K8s Exporter `config.yaml` - Required**                                                       |                                       |
| `serviceAccount.create`               | If `true`, create and use ServiceAccount, ClusterRole & ClusterRoleBinding                           | `true`                                |
| `serviceAccount.annotations`          | Annotations for ServiceAccount object                                                                | `{}`                                  |
| `serviceAccount.name`                 | ServiceAccount object name                                                                           | `""`                                  |
| `clusterRole.annotations`             | Annotations for ClusterRole object                                                                   | `{}`                                  |
| `clusterRole.name`                    | ClusterRole object name                                                                              | `""`                                  |
| `clusterRole.apiGroups`               | ClusterRole apiGroups                                                                                | `"{'*'}"`                             |
| `clusterRole.resources`               | ClusterRole resources                                                                                | `"{'*'}"`                             |
| `clusterRoleBinding.annotations`      | Annotations for ClusterRoleBinding object                                                            | `{}`                                  |
| `clusterRoleBinding.name`             | ClusterRoleBinding object name                                                                       | `""`                                  |
| `podAnnotations`                      | Annotations to be added to the pod                                                                   | `{}`                                  |
| `podSecurityContext`                  | Security context applied to the pod                                                                  | `{}`                                  |
| `securityContext`                     | Security context applied to the container                                                            | `{}`                                  |
| `resources`                           | Container resource requests & limits                                                                 | `{}`                                  |
| `nodeSelector`                        | NodeSelector applied to the pod                                                                      | `{}`                                  |
| `tolerations`                         | Tolerations applied to the pod                                                                       | `[]`                                  |
| `affinity`                            | Affinity applied to the pod                                                                          | `{}`                                  |

To override values in `helm install`, use either the `--set` flag or the `--set-file` flag to set individual values from a file.

Alternatively, you can use a YAML file that specifies the values while installing the chart. For example:

    helm install my-port-k8s-exporter port-labs/port-k8s-exporter \
       --create-namespace --namespace port-k8s-exporter \
       -f custom_values.yaml

### Exporter

An example for `config.yaml`:

```yaml
resources: # List of K8s resources to list, watch, and export to Port.
  - kind: v1/pods # group/version/resource (G/V/R) format
    selector:
      query: .metadata.namespace != "kube-system" # JQ boolean query. If evaluated to false - skip syncing the object.
    port:
      entity:
        mappings: # Mappings between one K8s object to one or many Port Entities. Each value is a JQ query.
          - identifier: .metadata.name
            title: .metadata.name
            blueprint: '"deployedServicePod"'
            properties:
              text: '"Service Instance"'
              num: 1
              bool: true
              obj: .spec
              arr: .status.conditions
            relations:
              relateTo: '"target-entity"'
```

#### JQ

Read more about JQ JSON processor: https://stedolan.github.io/jq/manual/

JQ Playground: https://jqplay.org/

In order to get a K8s object to play with, you can run the following command against your K8s cluster:

    kubectl get <resource> <name> -o json
