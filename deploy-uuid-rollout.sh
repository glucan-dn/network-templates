#!/bin/bash

# Deploy UUID Device Rollout Script
# This script helps deploy the parameterized rollout with your actual device UUIDs

set -e

NAMESPACE="${NAMESPACE:-default}"
ROLLOUT_NAME="device-rollout-parameterized"
TEMP_DIR="/tmp/argo-rollout-$$"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Deploy parameterized Argo Rollout with UUID device lists"
    echo ""
    echo "Options:"
    echo "  -f, --file FILE       File containing device UUIDs (one per line)"
    echo "  -d, --devices LIST    Comma-separated list of device UUIDs"
    echo "  -b, --batch-size N    Number of devices per rollout step (default: 5)"
    echo "  -n, --namespace NS    Kubernetes namespace (default: default)"
    echo "  -e, --endpoint URL    API endpoint URL"
    echo "  --dry-run            Show what would be deployed without applying"
    echo "  -h, --help           Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -f my-devices.txt -b 10"
    echo "  $0 -d 'uuid1,uuid2,uuid3' -b 3"
    echo "  $0 -f devices.txt -e 'https://my-api.com/endpoint'"
}

# Parse command line arguments
DEVICE_FILE=""
DEVICE_LIST=""
BATCH_SIZE=5
API_ENDPOINT=""
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--file)
            DEVICE_FILE="$2"
            shift 2
            ;;
        -d|--devices)
            DEVICE_LIST="$2"
            shift 2
            ;;
        -b|--batch-size)
            BATCH_SIZE="$2"
            shift 2
            ;;
        -n|--namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        -e|--endpoint)
            API_ENDPOINT="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            print_usage
            exit 1
            ;;
    esac
done

# Validate UUID format
validate_uuid() {
    local uuid="$1"
    if [[ ! "$uuid" =~ ^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$ ]]; then
        echo -e "${RED}ERROR: Invalid UUID format: $uuid${NC}"
        echo "Expected format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
        return 1
    fi
    return 0
}

# Read device UUIDs
DEVICES=()
if [ -n "$DEVICE_FILE" ]; then
    if [ ! -f "$DEVICE_FILE" ]; then
        echo -e "${RED}ERROR: Device file not found: $DEVICE_FILE${NC}"
        exit 1
    fi
    
    echo -e "${BLUE}Reading device UUIDs from: $DEVICE_FILE${NC}"
    while IFS= read -r line; do
        # Skip empty lines and comments
        if [[ ! -z "$line" && ! "$line" =~ ^#.* ]]; then
            line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')  # Trim whitespace
            if validate_uuid "$line"; then
                DEVICES+=("$line")
            else
                exit 1
            fi
        fi
    done < "$DEVICE_FILE"
    
elif [ -n "$DEVICE_LIST" ]; then
    echo -e "${BLUE}Parsing device UUIDs from command line${NC}"
    IFS=',' read -ra DEVICE_ARRAY <<< "$DEVICE_LIST"
    for device in "${DEVICE_ARRAY[@]}"; do
        device=$(echo "$device" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')  # Trim whitespace
        if validate_uuid "$device"; then
            DEVICES+=("$device")
        else
            exit 1
        fi
    done
else
    echo -e "${RED}ERROR: Must provide device UUIDs via --file or --devices${NC}"
    print_usage
    exit 1
fi

if [ ${#DEVICES[@]} -eq 0 ]; then
    echo -e "${RED}ERROR: No valid device UUIDs found${NC}"
    exit 1
fi

echo -e "${GREEN}Found ${#DEVICES[@]} valid device UUIDs${NC}"

# Calculate number of steps needed
TOTAL_DEVICES=${#DEVICES[@]}
STEPS_NEEDED=$(( (TOTAL_DEVICES + BATCH_SIZE - 1) / BATCH_SIZE ))

echo -e "${BLUE}Planning rollout: $TOTAL_DEVICES devices in $STEPS_NEEDED steps of $BATCH_SIZE devices each${NC}"

# Create temporary directory
mkdir -p "$TEMP_DIR"
trap "rm -rf $TEMP_DIR" EXIT

# Generate the rollout YAML
ROLLOUT_FILE="$TEMP_DIR/device-rollout.yaml"

echo -e "${YELLOW}Generating rollout configuration...${NC}"

cat > "$ROLLOUT_FILE" << EOF
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: $ROLLOUT_NAME
  namespace: $NAMESPACE
  labels:
    app: $ROLLOUT_NAME
spec:
  replicas: 0  # No actual pods, just orchestrating device rollout
  strategy:
    canary:
      steps:
EOF

# Generate steps
for (( step=1; step<=STEPS_NEEDED; step++ )); do
    start_idx=$(( (step - 1) * BATCH_SIZE ))
    end_idx=$(( step * BATCH_SIZE - 1 ))
    
    if [ $end_idx -ge $TOTAL_DEVICES ]; then
        end_idx=$(( TOTAL_DEVICES - 1 ))
    fi
    
    # Build device list for this step
    step_devices=""
    for (( i=start_idx; i<=end_idx; i++ )); do
        if [ $i -lt $TOTAL_DEVICES ]; then
            if [ -z "$step_devices" ]; then
                step_devices="${DEVICES[$i]}"
            else
                step_devices="$step_devices,${DEVICES[$i]}"
            fi
        fi
    done
    
    actual_count=$(( end_idx - start_idx + 1 ))
    step_name="step-$step"
    if [ $step -eq $STEPS_NEEDED ]; then
        step_name="step-$step-final"
    fi
    
    echo "      # Step $step: $actual_count devices" >> "$ROLLOUT_FILE"
    echo "      - setWeight: 0" >> "$ROLLOUT_FILE"
    echo "      - analysis:" >> "$ROLLOUT_FILE"
    echo "          templates:" >> "$ROLLOUT_FILE"
    echo "          - templateName: device-api-notification-uuid" >> "$ROLLOUT_FILE"
    echo "          args:" >> "$ROLLOUT_FILE"
    echo "          - name: step-name" >> "$ROLLOUT_FILE"
    echo "            value: \"$step_name\"" >> "$ROLLOUT_FILE"
    echo "          - name: device-list" >> "$ROLLOUT_FILE"
    echo "            value: \"$step_devices\"" >> "$ROLLOUT_FILE"
    
    if [ -n "$API_ENDPOINT" ]; then
        echo "          - name: api-endpoint" >> "$ROLLOUT_FILE"
        echo "            value: \"$API_ENDPOINT\"" >> "$ROLLOUT_FILE"
    fi
    
    echo "      - pause: {duration: 5s}" >> "$ROLLOUT_FILE"
    echo "" >> "$ROLLOUT_FILE"
    
    echo -e "  ${GREEN}Step $step:${NC} $actual_count devices"
done

# Add the rest of the rollout spec
cat >> "$ROLLOUT_FILE" << EOF
  selector:
    matchLabels:
      app: $ROLLOUT_NAME
  template:
    metadata:
      labels:
        app: $ROLLOUT_NAME
    spec:
      containers:
      - name: device-orchestrator
        image: busybox:1.35
        command: ["sleep", "3600"]
        env:
        - name: ROLLOUT_TYPE
          value: "$ROLLOUT_NAME"
        - name: TOTAL_DEVICES
          value: "$TOTAL_DEVICES"
        resources:
          requests:
            memory: "16Mi"
            cpu: "10m"
          limits:
            memory: "32Mi"
            cpu: "50m"
EOF

if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}=== DRY RUN - Generated Rollout YAML ===${NC}"
    cat "$ROLLOUT_FILE"
    echo -e "\n${YELLOW}=== END DRY RUN ===${NC}"
    echo -e "${BLUE}To deploy for real, run without --dry-run${NC}"
    exit 0
fi

# Deploy the resources
echo -e "${YELLOW}Deploying analysis template...${NC}"
kubectl apply -f rollouts/device-analysis-template-uuid.yaml -n "$NAMESPACE"

echo -e "${YELLOW}Deploying rollout...${NC}"
kubectl apply -f "$ROLLOUT_FILE"

echo -e "${GREEN}✅ Deployment complete!${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "1. Monitor the rollout:"
echo "   kubectl argo rollouts get rollout $ROLLOUT_NAME -n $NAMESPACE --watch"
echo ""
echo "2. Promote through steps:"
echo "   kubectl argo rollouts promote $ROLLOUT_NAME -n $NAMESPACE"
echo ""
echo "3. Check analysis logs:"
echo "   kubectl logs -l job-name=\$(kubectl get jobs -n $NAMESPACE --no-headers | grep device | head -1 | awk '{print \$1}') -n $NAMESPACE"
echo ""
echo "4. Abort if needed:"
echo "   kubectl argo rollouts abort $ROLLOUT_NAME -n $NAMESPACE"
echo ""
echo -e "${GREEN}🎯 Your rollout is ready with $TOTAL_DEVICES devices across $STEPS_NEEDED steps!${NC}"
