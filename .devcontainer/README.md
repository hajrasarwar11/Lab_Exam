# DevContainer Configuration

This devcontainer includes:
- **Terraform** - Infrastructure as Code
- **Ansible** - Configuration Management
- **AWS CLI** - AWS Command Line Interface

## AWS Configuration

After rebuilding the container, configure AWS:
```bash
aws configure
```

For SSH keys, place them in `~/.ssh/` and they'll persist across container rebuilds if you use a persistent volume.

## Rebuild Container

To apply these changes: Press `F1` → Select "Dev Containers: Rebuild Container"
