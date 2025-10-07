# Network Templates Repository

This repository contains per-device configuration templates that trigger external API calls when updated.

## Structure

- `templates/` - Device configuration templates organized by type and environment
- `schemas/` - JSON schemas for template validation  
- `examples/` - Example configurations and usage patterns
- `api-config.yaml` - External API endpoint configuration
- `deployment-config.yaml` - Template processing and notification configuration
- `setup.sh` - Repository setup and validation script
- `validate-templates.sh` - Local template validation script

## Configuration

### API Endpoint Configuration
The external API endpoint is configured in `api-config.yaml`:

```yaml
api:
  base_url: "https://your-external-system.com"
  endpoint: "/api/v1/network-templates/updated"
  timeout: 30
```

### Authentication
Both configuration files (`api-config.yaml` and `deployment-config.yaml`) use the same authentication:
- **Bearer token** - Configured directly in the configuration files

### Advantages
✅ **Visible Configuration** - API endpoint visible in repository  
✅ **Version Controlled** - Changes tracked in git  
✅ **Developer Friendly** - No GitHub admin access needed  
✅ **Environment Support** - Different URLs for prod/staging/dev  

## Template Structure

Templates follow this naming convention:
- `{device-type}-{environment}-{version}.yaml`
- Example: `router-production-v1.2.yaml`, `switch-staging-v2.1.yaml`

## Integration Workflow

When templates are updated, the system can trigger external API calls:
1. **Template Change** → Detected by monitoring system
2. **API Call** → Sends HTTP POST to configured endpoint
3. **External System** → Processes notification (CMS, ITSM, etc.)

## API Payload Format

```json
{
  "event": "template_updated",
  "repository": "your-org/network-templates",  
  "changed_files": [
    {
      "path": "templates/router-production-v1.yaml",
      "device_type": "router",
      "environment": "production", 
      "version": "1.0"
    }
  ]
}
```

## Setup

1. **Configure API endpoints** in `api-config.yaml` and `deployment-config.yaml`
2. **Validate templates** with `./validate-templates.sh`
3. **Test setup** with `./setup.sh`

## Repository Independence

This repository is completely independent and can integrate with any external system that accepts HTTP webhooks.
