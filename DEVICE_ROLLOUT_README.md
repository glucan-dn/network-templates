# Device Rollout with Argo Rollouts

This setup demonstrates how to use Argo Rollouts for progressive device configuration rollouts instead of traditional application deployments.

## Overview

The device rollout system:
- **0 replicas**: No actual pods are deployed - this is pure orchestration
- **100 device IDs**: Progressively rolls out to 5 groups of 20 devices each
- **API notifications**: Sends HTTP POST requests to Railway app after each step
- **Canary strategy**: Uses Argo Rollouts canary deployment for controlled progression

## Files Created

### 1. Device Rollout (`rollouts/device-rollout.yaml`)
- Main Rollout manifest with 5 steps (20 devices each)
- Replica count: 0 (no actual deployment)
- Each step triggers an AnalysisTemplate for Railway API notification
- Includes pause durations between steps

### 2. Analysis Templates (`rollouts/device-analysis-template.yaml`)
Two analysis templates:
- **`device-api-notification`**: Job-based provider with detailed device lists
- **`device-api-notification-web`**: Web-based provider (simpler, less flexible)

### 3. Device Configuration (`configmaps/device-list.yaml`)
- Complete list of 100 device IDs (device-001 to device-100)
- Step-by-step device groupings
- API configuration settings

## Usage

### 1. Deploy the Resources
```bash
# Deploy from the kubernetes-deployment directory
kubectl apply -f configmaps/device-list.yaml
kubectl apply -f rollouts/device-analysis-template.yaml
kubectl apply -f rollouts/device-rollout.yaml
```

### 2. API Endpoint Configuration
The Railway app endpoint is already configured in the rollout:

```yaml
- name: api-endpoint
  value: "https://discerning-surprise-production.up.railway.app/api/v1/start-config-update-on-devices"
```

To change the endpoint, update each step in `device-rollout.yaml` or modify the default value in `device-analysis-template.yaml`.

### 3. Start the Rollout
```bash
# View rollout status
kubectl argo rollouts get rollout device-rollout --watch

# Start rollout (if paused)
kubectl argo rollouts promote device-rollout

# Check analysis runs
kubectl get analysisrun -l rollout=device-rollout
```

### 4. Monitor Progress
```bash
# Watch rollout progression
kubectl argo rollouts get rollout device-rollout --watch

# Check analysis job logs
kubectl logs -l job-name=<analysis-job-name>

# View rollout history
kubectl argo rollouts history device-rollout
```

## API Payload Format

Each step sends a simplified JSON payload to your Railway endpoint:

```json
{
  "devices": [
    "device-001", "device-002", "device-003", 
    "...", "device-020"
  ]
}
```

The rollout sends exactly 20 device IDs per step:
- **Step 1**: devices 001-020
- **Step 2**: devices 021-040  
- **Step 3**: devices 041-060
- **Step 4**: devices 061-080
- **Step 5**: devices 081-100

## Customization

### Change Device Count
Edit `device-rollout.yaml` and update:
- Device range arguments (`device-range-start`, `device-range-end`)
- Device count arguments (`device-count`)
- Update the ConfigMap with your actual device IDs

### Modify Rollout Steps
Adjust the canary steps in `device-rollout.yaml`:
```yaml
steps:
- setWeight: 0
- analysis: # Your analysis configuration
- pause: {duration: 60s}  # Adjust pause duration
```

### Different API Provider
Switch between job-based and web-based analysis templates by changing the `templateName` in the rollout.

## Troubleshooting

### Rollout Stuck
```bash
# Check rollout status
kubectl argo rollouts get rollout device-rollout

# Check analysis runs
kubectl get analysisrun
kubectl describe analysisrun <analysis-run-name>

# Manually promote if needed
kubectl argo rollouts promote device-rollout
```

### API Call Failures
```bash
# Check analysis job logs
kubectl logs -l job-name=<analysis-job-name>

# Check analysis run status
kubectl describe analysisrun <analysis-run-name>
```

### Reset Rollout
```bash
# Abort current rollout
kubectl argo rollouts abort device-rollout

# Restart rollout
kubectl argo rollouts restart device-rollout
```

## Security Considerations

1. **API Authentication**: Add proper authentication headers in the analysis template
2. **Network Policies**: Restrict egress traffic if needed
3. **RBAC**: Ensure proper service account permissions for analysis jobs
4. **Secrets**: Store API keys in Kubernetes secrets, not ConfigMaps

## Integration with Google APIs

For Google API integration, you'll typically need:

1. **Service Account Key**: Mount as a secret
2. **OAuth Token**: Use Google's OAuth flow
3. **API Key**: Add to request headers

Example with service account:
```yaml
env:
- name: GOOGLE_APPLICATION_CREDENTIALS
  value: "/var/secrets/google/key.json"
volumeMounts:
- name: google-cloud-key
  mountPath: /var/secrets/google
  readOnly: true
```
