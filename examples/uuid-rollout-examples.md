# UUID Device Rollout Examples

This document shows how to use the parameterized device rollout with UUID device identifiers.

## Overview

The parameterized rollout (`device-rollout-parameterized.yaml`) accepts UUID device lists at runtime, allowing you to specify exactly which devices to target for each rollout step.

## Method 1: Runtime Parameter Override (Recommended)

### Step 1: Prepare Your UUID Device Lists

Organize your device UUIDs into batches for each rollout step:

```bash
# Example UUIDs (replace with your actual device UUIDs)
STEP_1_DEVICES="550e8400-e29b-41d4-a716-446655440001,550e8400-e29b-41d4-a716-446655440002,550e8400-e29b-41d4-a716-446655440003"
STEP_2_DEVICES="550e8400-e29b-41d4-a716-446655440004,550e8400-e29b-41d4-a716-446655440005,550e8400-e29b-41d4-a716-446655440006"
STEP_3_DEVICES="550e8400-e29b-41d4-a716-446655440007,550e8400-e29b-41d4-a716-446655440008,550e8400-e29b-41d4-a716-446655440009"
STEP_4_DEVICES="550e8400-e29b-41d4-a716-446655440010,550e8400-e29b-41d4-a716-446655440011,550e8400-e29b-41d4-a716-446655440012"
STEP_5_DEVICES="550e8400-e29b-41d4-a716-446655440013,550e8400-e29b-41d4-a716-446655440014,550e8400-e29b-41d4-a716-446655440015"
```

### Step 2: Create a Customized Rollout with Your UUIDs

Use `kubectl create` with inline parameter substitution:

```bash
# Create a temporary rollout manifest with your UUIDs
envsubst < rollouts/device-rollout-parameterized.yaml > /tmp/my-device-rollout.yaml

# Edit the temporary file to include your UUIDs
sed -i "s/value: \"\"  # Will be overridden at runtime/value: \"$STEP_1_DEVICES\"/" /tmp/my-device-rollout.yaml
# Repeat for each step...

# Apply the customized rollout
kubectl apply -f /tmp/my-device-rollout.yaml
```

### Step 3: Alternative - Direct kubectl patch

Or patch the rollout directly after deployment:

```bash
# Deploy the base rollout first
kubectl apply -f rollouts/device-rollout-parameterized.yaml
kubectl apply -f rollouts/device-analysis-template-uuid.yaml

# Patch each step with your device UUIDs
kubectl patch rollout device-rollout-parameterized --type='json' -p='[
  {
    "op": "replace", 
    "path": "/spec/strategy/canary/steps/1/analysis/args/1/value", 
    "value": "550e8400-e29b-41d4-a716-446655440001,550e8400-e29b-41d4-a716-446655440002"
  }
]'

# Repeat for other steps...
```

## Method 2: ConfigMap-Based Approach

### Step 1: Create ConfigMap with UUID Lists

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: device-list-uuid
  namespace: default
data:
  step-1: "550e8400-e29b-41d4-a716-446655440001,550e8400-e29b-41d4-a716-446655440002,550e8400-e29b-41d4-a716-446655440003"
  step-2: "550e8400-e29b-41d4-a716-446655440004,550e8400-e29b-41d4-a716-446655440005,550e8400-e29b-41d4-a716-446655440006"
  step-3: "550e8400-e29b-41d4-a716-446655440007,550e8400-e29b-41d4-a716-446655440008,550e8400-e29b-41d4-a716-446655440009"
  step-4: "550e8400-e29b-41d4-a716-446655440010,550e8400-e29b-41d4-a716-446655440011,550e8400-e29b-41d4-a716-446655440012"
  step-5: "550e8400-e29b-41d4-a716-446655440013,550e8400-e29b-41d4-a716-446655440014,550e8400-e29b-41d4-a716-446655440015"
```

### Step 2: Create Rollout Using ConfigMap Template

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: device-rollout-configmap
spec:
  replicas: 0
  strategy:
    canary:
      steps:
      - analysis:
          templates:
          - templateName: device-api-notification-configmap
          args:
          - name: step-name
            value: "step-1"
          - name: step-key
            value: "step-1"
          - name: configmap-name
            value: "device-list-uuid"
```

## Method 3: Script-Based Deployment

Create a deployment script that generates the rollout with your UUIDs:

```bash
#!/bin/bash

# deployment-script.sh
DEVICE_UUIDS=(
    "550e8400-e29b-41d4-a716-446655440001"
    "550e8400-e29b-41d4-a716-446655440002"
    "550e8400-e29b-41d4-a716-446655440003"
    # ... add all your device UUIDs
)

# Split into 5 batches
BATCH_SIZE=3
TOTAL_DEVICES=${#DEVICE_UUIDS[@]}

echo "Deploying rollout for $TOTAL_DEVICES devices in batches of $BATCH_SIZE"

# Generate the rollout YAML with actual UUIDs
for step in {1..5}; do
    START_IDX=$(( (step - 1) * BATCH_SIZE ))
    END_IDX=$(( step * BATCH_SIZE - 1 ))
    
    if [ $END_IDX -ge $TOTAL_DEVICES ]; then
        END_IDX=$(( TOTAL_DEVICES - 1 ))
    fi
    
    STEP_DEVICES=""
    for i in $(seq $START_IDX $END_IDX); do
        if [ $i -lt $TOTAL_DEVICES ]; then
            if [ -z "$STEP_DEVICES" ]; then
                STEP_DEVICES="${DEVICE_UUIDS[$i]}"
            else
                STEP_DEVICES="$STEP_DEVICES,${DEVICE_UUIDS[$i]}"
            fi
        fi
    done
    
    echo "Step $step: $STEP_DEVICES"
    
    # Update the rollout with this step's devices
    kubectl patch rollout device-rollout-parameterized --type='json' -p="[
        {\"op\": \"replace\", \"path\": \"/spec/strategy/canary/steps/$((step * 2 - 1))/analysis/args/1/value\", \"value\": \"$STEP_DEVICES\"}
    ]"
done
```

## Usage Examples

### Deploy and Start Rollout

```bash
# 1. Deploy the analysis template
kubectl apply -f rollouts/device-analysis-template-uuid.yaml

# 2. Deploy your customized rollout (using any method above)
kubectl apply -f /tmp/my-device-rollout.yaml

# 3. Monitor the rollout
kubectl argo rollouts get rollout device-rollout-parameterized --watch

# 4. Promote through steps (if needed)
kubectl argo rollouts promote device-rollout-parameterized
```

### Verify Device Lists

Check what devices will be sent to each step:

```bash
# View the rollout configuration
kubectl get rollout device-rollout-parameterized -o yaml | grep -A5 -B5 "device-list"

# Check analysis run logs to see actual API calls
kubectl logs -l job-name=$(kubectl get jobs --no-headers | grep device | head -1 | awk '{print $1}')
```

## Expected API Payload

Your Railway endpoint will receive JSON payloads like:

```json
{
  "devices": [
    "550e8400-e29b-41d4-a716-446655440001",
    "550e8400-e29b-41d4-a716-446655440002",
    "550e8400-e29b-41d4-a716-446655440003"
  ]
}
```

## Tips

1. **UUID Validation**: The analysis template includes basic UUID format validation
2. **Batch Sizing**: Adjust the number of devices per step based on your infrastructure capacity
3. **Error Handling**: Failed API calls will pause the rollout - check logs with `kubectl logs`
4. **Rollback**: Use `kubectl argo rollouts abort` to stop a problematic rollout

## Troubleshooting

### Common Issues

1. **Empty device-list parameter**: Make sure to set the device-list value for each step
2. **Invalid UUID format**: Check that UUIDs follow the standard format: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`
3. **API call failures**: Check Railway endpoint logs and network connectivity

### Debug Commands

```bash
# Check rollout status
kubectl argo rollouts get rollout device-rollout-parameterized

# View analysis run details
kubectl get analysisrun -l rollout=device-rollout-parameterized
kubectl describe analysisrun <analysis-run-name>

# Check job logs
kubectl logs -l job-name=<job-name>
```
