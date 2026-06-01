<img align="right" width="100" height="74" src="https://user-images.githubusercontent.com/8277210/183290025-d7b24277-dfb4-4ce1-bece-7fe0ecd5efd4.svg" />

# Port Helm Charts

[![Slack](https://img.shields.io/badge/Slack-4A154B?style=for-the-badge&logo=slack&logoColor=white)](https://join.slack.com/t/devex-community/shared_invite/zt-1bmf5621e-GGfuJdMPK2D8UN58qL4E_g)

Port is the Developer Platform meant to supercharge your DevOps and Developers, and allow you to regain control of your environment.

### Docs

- [Port Docs](https://docs.getport.io)

## Charts

| Chart                                                  | Description                                                     | Source Code                                    |
|--------------------------------------------------------|-----------------------------------------------------------------|------------------------------------------------|
| [charts/port-k8s-exporter](charts/port-k8s-exporter)   | Port K8s Exporter - export and map K8s objects to Port entities | https://github.com/port-labs/port-k8s-exporter |
| [charts/port-agent](charts/port-agent)   | Port Agent - consume and invoke Port Self-Service Actions | https://github.com/port-labs/port-agent |
| [charts/port-ocean](charts/port-ocean)   | Port Ocean - export and map data from 3rd party systems  | https://github.com/port-labs/port-ocean |

## Contributing

When making changes to any chart, you **must** bump the chart version in `Chart.yaml` according to [semantic versioning](https://semver.org/):
- **MAJOR** version for incompatible API changes
- **MINOR** version for backwards-compatible functionality additions
- **PATCH** version for backwards-compatible bug fixes

The CI/CD pipeline will automatically validate that chart versions are bumped when content changes are detected.
