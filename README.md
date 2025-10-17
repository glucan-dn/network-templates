# Argo Rollouts Test Repository

This repository contains simple test applications to demonstrate Argo Rollouts functionality.

## Structure

- `rollouts/` - Argo Rollouts manifests
  - `test-app-canary.yaml` - Canary deployment strategy example
  - `test-app-bluegreen.yaml` - Blue-Green deployment strategy example
  - `analysis-templates.yaml` - Analysis templates for success rate and latency metrics  
- `services/` - Service definitions for exposing the test applications
- `configmaps/` - Simple test configuration maps
- `deployments/` - Test secrets template (optional)
- `deploy.sh` - Automated deployment script

## Quick Start

### Prerequisites

1. Kubernetes cluster with Argo Rollouts installed:
   ```bash
   kubectl create namespace argo-rollouts
   kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml
   ```

2. Install Argo Rollouts CLI:
   ```bash
   # macOS
   brew install argoproj/tap/kubectl-argo-rollouts
   
   # Linux
   curl -LO https://github.com/argoproj/argo-rollouts/releases/latest/download/kubectl-argo-rollouts-linux-amd64
   chmod +x ./kubectl-argo-rollouts-linux-amd64
   sudo mv ./kubectl-argo-rollouts-linux-amd64 /usr/local/bin/kubectl-argo-rollouts
   ```

### Deploy

**One-command deployment**:
```bash
./deploy.sh
```

**Manual step-by-step**:
```bash
# 1. Deploy resources
kubectl apply -f configmaps/
kubectl apply -f services/
kubectl apply -f deployments/
kubectl apply -f rollouts/

# 2. Check status
kubectl argo rollouts list
```

## Test Applications

### test-app (Canary Strategy)
- **Image**: `nginx:1.20`
- **Strategy**: Canary with 33% → 66% → 100% traffic shift
- **Service**: `test-app` (ClusterIP)

### test-app-bg (Blue-Green Strategy)  
- **Image**: `httpd:2.4`
- **Strategy**: Blue-Green with analysis validation
- **Services**: `test-app-bg-active` (LoadBalancer), `test-app-bg-preview` (ClusterIP)

## Testing Rollout Strategies

### 1. Watch Rollouts in Action
```bash
# Monitor canary rollout
kubectl argo rollouts get rollout test-app --watch

# Monitor blue-green rollout  
kubectl argo rollouts get rollout test-app-bg --watch
```

### 2. Trigger Updates
```bash
# Update canary app
kubectl argo rollouts set image test-app test-app=nginx:1.21

# Update blue-green app
kubectl argo rollouts set image test-app-bg test-app-bg=httpd:2.4.54
```

### 3. Manual Control
```bash
# Promote rollouts
kubectl argo rollouts promote test-app
kubectl argo rollouts promote test-app-bg

# Abort rollouts
kubectl argo rollouts abort test-app
kubectl argo rollouts abort test-app-bg

# Restart rollouts
kubectl argo rollouts restart test-app
kubectl argo rollouts restart test-app-bg
```

### 4. Check Application Status
```bash
# Get service endpoints
kubectl get svc

# Check pod status
kubectl get pods

# View rollout history
kubectl argo rollouts history test-app
kubectl argo rollouts history test-app-bg
```

## Analysis Templates

Optional Prometheus-based analysis templates are included:
- **Success Rate**: Monitors HTTP 2xx responses (≥95% required)
- **Latency P95**: Monitors response time (≤500ms required)

*Note: Requires Prometheus setup for analysis to work.*
