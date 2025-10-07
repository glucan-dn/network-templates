# Network Templates Repository

This repository contains per-device configuration templates that trigger external API calls when updated.

## Structure

- `templates/` - Device configuration templates organized by type and environment
- `schemas/` - JSON schemas for template validation
- `examples/` - Example configurations and usage patterns
- `.github/workflows/` - GitHub Actions for automated API notifications

## Workflow

When templates are updated:
1. **Commit** → Triggers GitHub Action
2. **GitHub Action** → Sends HTTP API call to external system (CMS, etc.)
3. **External System** → Processes the notification as needed

## Template Structure

Templates follow this naming convention:
- `{device-type}-{environment}-{version}.yaml`
- Example: `router-production-v1.2.yaml`, `switch-staging-v2.1.yaml`

## API Integration

The repository sends webhook notifications to any external API endpoint:
- **Configurable Endpoint**: Set via `DEPLOYMENT_API_URL` secret
- **Rich Payload**: Contains template metadata, changes, and commit information
- **Authentication**: Bearer token via `DEPLOYMENT_API_TOKEN` secret
- **No Dependencies**: Works with any external system that accepts HTTP POST

## Repository Independence

This repository is completely independent and can notify any external system. It does not depend on or connect to any specific deployment system.
