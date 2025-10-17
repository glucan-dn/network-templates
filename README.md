# Network Device Rollouts with Argo

Progressive rollout system for network device configurations using Argo Rollouts. Supports both traditional test applications and real-world device UUID-based deployments.

## What's Included

### 🚀 **Device Rollout System** (Main Feature)
- **UUID-based device rollouts** - Use your actual device identifiers
- **Progressive batching** - Deploy to devices in controlled steps  
- **API integration** - HTTP callbacks to your management system
- **Flexible configuration** - Customize batch sizes and timing

### 🧪 **Test Applications** 
- **Canary rollouts** - Traffic-based progressive deployment
- **Blue-Green rollouts** - Zero-downtime environment switching
- **Analysis templates** - Automated success validation
- **deploy.sh script** - One-command deployment of all test components

## Repository Structure

```
├── rollouts/
│   ├── device-rollout-parameterized.yaml    # UUID device rollouts
│   ├── device-analysis-template-uuid.yaml   # API integration
│   ├── test-app-canary.yaml                 # Traditional canary
│   └── test-app-bluegreen.yaml              # Traditional blue-green
├── examples/
│   ├── uuid-rollout-examples.md             # Complete usage guide
│   └── sample-device-uuids.txt              # Example device IDs
├── templates/                               # Network device configs
├── schemas/                                 # Validation schemas
├── deploy-uuid-rollout.sh                   # Device rollout deployment
├── deploy.sh                                # Test app deployment
└── api-config.yaml                          # API endpoint configuration
```

## Quick Start

### Prerequisites
```bash
# 1. Install Argo Rollouts
kubectl create namespace argo-rollouts
kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml

# 2. Install Argo CLI (macOS)
brew install argoproj/tap/kubectl-argo-rollouts
```

### 🚀 Device Rollouts (Main Use Case)

Deploy progressive rollouts to your network devices:

```bash
# 1. Create your device list file (one UUID per line)
echo "f47ac10b-58cc-4372-a567-0e02b2c3d479" > my-devices.txt
echo "123e4567-e89b-12d3-a456-426614174000" >> my-devices.txt

# 2. Deploy rollout (10 devices per batch)
./deploy-uuid-rollout.sh -f my-devices.txt -b 10

# 3. Monitor progress
kubectl argo rollouts get rollout device-rollout-parameterized --watch
```

**API Integration**: Configure your endpoint in the rollout or use `-e` flag:
```bash
./deploy-uuid-rollout.sh -f devices.txt -e "https://your-api.com/devices"
```

### 🧪 Test Applications

Deploy traditional Argo Rollouts test applications for learning and experimentation:

```bash
# Deploy all test components (services, configmaps, rollouts)
./deploy.sh

# Watch canary rollout
kubectl argo rollouts get rollout test-app --watch

# Watch blue-green rollout  
kubectl argo rollouts get rollout test-app-bg --watch

# Test rollout updates
kubectl argo rollouts set image test-app test-app=nginx:1.21
```

The `deploy.sh` script automatically sets up:
- Test secrets and ConfigMaps
- Services for traffic routing
- Analysis templates for automated validation
- Both canary and blue-green rollout configurations

## How It Works

### Template Updates
1. **Modify templates** - Edit files in `templates/` directory
2. **Git push** - Commit and push changes to repository
3. **GitHub Actions trigger** - Automatic workflow detects template changes
4. **API notification** - Calls your `/api/v1/network-templates/updated` endpoint
5. **Your system responds** - Update CMS, trigger workflows, send notifications

### Device Rollouts
1. **Create device list** - File with UUIDs (one per line)
2. **Deploy rollout** - Script splits devices into batches
3. **Progressive execution** - Each step calls your API with device batch
4. **Monitor & control** - Watch progress, promote/abort as needed

### Example API Payload
Your endpoint receives:
```json
{
  "devices": [
    "f47ac10b-58cc-4372-a567-0e02b2c3d479",
    "123e4567-e89b-12d3-a456-426614174000",
    "987fcdeb-51a2-43d6-b789-123456789abc"
  ]
}
```

## API Integration

The system makes **two types** of API calls to keep your management system synchronized:

### 🔄 Template Update API
**Endpoint**: `/api/v1/network-templates/updated`  
**Trigger**: When templates in `templates/` directory are modified via Git push  
**Purpose**: Notify your system about configuration template changes

**Payload Example**:
```json
{
  "event": "template_updated",
  "repository": "your-org/network-templates",
  "commit_sha": "abc123...",
  "commit_message": "Update router production config",
  "author": "jane.doe",
  "timestamp": "2024-03-15T10:30:00Z",
  "changed_files": [
    {
      "path": "templates/router-production-v1.yaml",
      "device_type": "router",
      "environment": "production",
      "version": "v1"
    }
  ]
}
```

### 📱 Device Rollout API  
**Endpoint**: `/api/v1/start-config-update-on-devices`  
**Trigger**: During progressive device rollout execution  
**Purpose**: Update specific device batches with new configuration

**Payload Example**:
```json
{
  "devices": [
    "f47ac10b-58cc-4372-a567-0e02b2c3d479",
    "123e4567-e89b-12d3-a456-426614174000"
  ]
}
```

### Configuration
Configure API endpoints in `api-config.yaml`:
```yaml
api:
  base_url: "https://your-api.com"
  endpoints:
    template_updated: "/api/v1/network-templates/updated"
  authentication:
    type: "bearer_token"
    token: "your-secret-token"
```

## Common Commands

```bash
# List all rollouts
kubectl argo rollouts list

# Promote to next step
kubectl argo rollouts promote device-rollout-parameterized

# Abort rollout
kubectl argo rollouts abort device-rollout-parameterized

# View detailed logs
kubectl logs -l job-name=$(kubectl get jobs --no-headers | grep device | head -1 | awk '{print $1}')
```

## Documentation

- **[examples/uuid-rollout-examples.md](examples/uuid-rollout-examples.md)** - Comprehensive usage guide
- **[examples/sample-device-uuids.txt](examples/sample-device-uuids.txt)** - Example device identifiers  
- **[DEVICE_ROLLOUT_README.md](DEVICE_ROLLOUT_README.md)** - Legacy sequential ID documentation

## Network Templates

The `templates/` directory contains sample network device configurations for routers and switches that can be used with the rollout system.
