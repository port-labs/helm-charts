# Port Agent

Port Agent allows to consume and run Port Self-Service Actions in your VPC.

## Introduction

This chart installs the Port Agent via a `Deployment` resource.

## Usage

[Helm](https://helm.sh) must be installed to use the charts. Please refer to
Helm's [documentation](https://helm.sh/docs) to get started.

Once Helm has been set up correctly, add the repo as follows:

    helm repo add port-labs https://port-labs.github.io/helm-charts

If you had already added this repo earlier, run `helm repo update` to retrieve
the latest versions of the packages. You can then run `helm search repo
port-labs` to see the charts.

Then, install the chart using the following command:

    helm upgrade --install my-port-agent port-labs/port-agent \
        --create-namespace --namespace port-agent \
        --set env.normal.PORT_ORG_ID=YOUR_PORT_ORG_ID
        --set env.normal.PORT_API_BASE_URL=https://api.getport.io \
        --set env.normal.KAFKA_CONSUMER_GROUP_ID=YOUR_KAFKA_CONSUMER_GROUP_ID \
        --set env.secret.PORT_CLIENT_ID=YOUR_PORT_CLIENT_ID \
        --set env.secret.PORT_CLIENT_SECRET=YOUR_PORT_CLIENT_SECRET

*

Replace `YOUR_PORT_ORG_ID`, `YOUR_KAFKA_CONSUMER_GROUP_ID`, `YOUR_PORT_CLIENT_ID`, `YOUR_PORT_CLIENT_SECRET`
with the values that Port supplied you.

To uninstall the chart use:

    helm uninstall my-port-agent --namespace port-agent

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Configuration

The following table lists the configuration parameters of the `port-agent` chart and default values.

| Parameter                                            | Description                                                                                | Default                                                                                                                                                                                                                           |
|------------------------------------------------------|--------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `image.repository`                                   | Image repository                                                                           | `ghcr.io/port-labs/port-agent`                                                                                                                                                                                                    |
| `image.pullPolicy`                                   | Image pull policy                                                                          | `IfNotPresent`                                                                                                                                                                                                                    |
| `image.tag`                                          | Image tag                                                                                  | `""`                                                                                                                                                                                                                              |
| `replicaCount`                                       | Number of port-agent replicas (ensure Kafka topic has enough partitions when scaling up)   | `1`                                                                                                                                                                                                                               |
| `imagePullSecrets`                                   | Image pull secrets                                                                         | `[]`                                                                                                                                                                                                                              |
| `nameOverride`                                       | Chart name override                                                                        | `""`                                                                                                                                                                                                                              |
| `fullnameOverride`                                   | Fully qualified app name override                                                          | `""`                                                                                                                                                                                                                              |
| `secret.annotations`                                 | Annotations for Secret object                                                              | `{}`                                                                                                                                                                                                                              |
| `secret.name`                                        | Secret object name                                                                         | `""`                                                                                                                                                                                                                              |
| `secret.useExistingSecret`                           | Enable this if you wish to create your own secret with credentials                         | `false`                                                                                                                                                                                                                           |
| `podServiceAccount.name`                             | Service account to attach to the pod.                                                      | `null`                                                                                                                                                                                                                            |
| `env.normal.STREAMER_NAME`                           | Streamer name, available: [`KAFKA`]                                                        | `"KafkaToWebhookStreamer"`                                                                                                                                                                                                        |
| `env.normal.PORT_ORG_ID`                             | Your Port org id - **Required**                                                            | `""`                                                                                                                                                                                                                              |
| `env.normal.PORT_API_BASE_URL`                       | Port API base url                                                                          | `"https://api.getport.io"`                                                                                                                                                                                                        |
| `env.normal.KAFKA_CONSUMER_GROUP_ID`                 | Kafka consumer group id - **Required if using any Kafka streamer**                         | `""`                                                                                                                                                                                                                              |
| `env.normal.KAFKA_CONSUMER_SECURITY_PROTOCOL`        | Kafka consumer security protocol                                                           | `"SASL_SSL"`                                                                                                                                                                                                                      |
| `env.normal.KAFKA_CONSUMER_AUTHENTICATION_MECHANISM` | Kafka consumer authentication mechanism                                                    | `"SCRAM-SHA-512"`                                                                                                                                                                                                                 |
| `env.normal.KAFKA_CONSUMER_AUTO_OFFSET_RESET`        | Kafka consumer auto offset reset                                                           | `"largest"`                                                                                                                                                                                                                       |
| `env.secret.PORT_CLIENT_ID`                          | Port API client id                                                                         | `""`                                                                                                                                                                                                                              |
| `env.secret.PORT_CLIENT_SECRET`                      | Port API client secret                                                                     | `""`                                                                                                                                                                                                                              |
| `controlThePayloadConfig`                            | Override the default control the payload configuration file with custom json configuration | `""`                                                                                                                                                                                                                              |
| `podAnnotations`                                     | Annotations to be added to the pod                                                         | `{}`                                                                                                                                                                                                                              |
| `podSecurityContext`                                 | Security context applied to the pod                                                        | `{}`                                                                                                                                                                                                                              |
| `containerSecurityContext`                           | Security context applied to the container                                                  | `{}`                                                                                                                                                                                                                              |
| `resources`                                          | Container resource requests & limits                                                       | `{}`                                                                                                                                                                                                                              |
| `nodeSelector`                                       | NodeSelector applied to the pod                                                            | `{}`                                                                                                                                                                                                                              |
| `tolerations`                                        | Tolerations applied to the pod                                                             | `[]`                                                                                                                                                                                                                              |
| `affinity`                                           | Affinity applied to the pod                                                                | `{}`                                                                                                                                                                                                                              |
| `selfSignedCertificate` | Self Signed certificate for the agent                                                      | `{}`                     |
| `selfSignedCertificate.enabled`     | Enable self-signed certificate trust for the agent                                         | `false`                        |
| `selfSignedCertificate.certificate` | The value of the self-signed certificate (only when `selfSignedCertificate.enabled=true`)  | `""`                        |
| `selfSignedCertificate.secret` | Secret with self-signed certificate                                                        | `{}`                        |
| `selfSignedCertificate.secret.useExistingSecret` | Enable this if you wish to use your own secret with the self-signed certificate            | `false`                        |
| `selfSignedCertificate.secret.key` | The key in the existing self-signed certificate secret                                     | `crt`                        |
| `selfSignedCertificate.secret.name` | The name of an existing secret containing the self-signed certificate                      | `""`                        |

To override values in `helm install`, use either the `--set` flag or the `--set-file` flag to set individual values from
a file.

Alternatively, you can use a YAML file that specifies the values while installing the chart. For example:

    helm install my-port-agent port-labs/port-agent \
       --create-namespace --namespace port-agent \
       -f custom_values.yaml


### Self-signed certificate trust
For self-hosted 3rd-party applications with self-signed certificates, you will need to add your CA to the integration's configuration. 
To do so, you will need to run the `helm install` command with the following flags:

```sh
helm install my-port-agent port-labs/port-agent \
   --create-namespace --namespace port-agent \
   -f custom_values.yaml
   # Flag for enabling self signed certificates
   --set selfSignedCertificate.enabled=true \ 
   # Flag for passing the certificate file
   --set-file selfSignedCertificate.certificate=/PATH/TO/CERTIFICATE.crt
```
