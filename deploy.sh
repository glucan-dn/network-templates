#!/bin/bash

# Simple Argo Rollouts Test Deployment Script
# This script deploys test applications to demo Argo Rollouts functionality

set -e

NAMESPACE="${NAMESPACE:-default}"
CONTEXT="${CONTEXT:-}"

echo "🚀 Deploying Argo Rollouts test applications..."

# Set kubectl context if specified
if [ -n "$CONTEXT" ]; then
    echo "📋 Using kubectl context: $CONTEXT"
    kubectl config use-context "$CONTEXT"
fi

# Ensure namespace exists
echo "🔧 Ensuring namespace $NAMESPACE exists..."
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# Deploy test secrets (optional)
echo "🔐 Deploying test secrets..."
kubectl apply -f deployments/secrets-template.yaml -n "$NAMESPACE"

# Deploy ConfigMaps
echo "📦 Deploying ConfigMaps..."
kubectl apply -f configmaps/ -n "$NAMESPACE"

# Deploy Services  
echo "🌐 Deploying Services..."
kubectl apply -f services/ -n "$NAMESPACE"

# Deploy Analysis Templates (if using Prometheus)
echo "📊 Deploying Analysis Templates..."
kubectl apply -f rollouts/analysis-templates.yaml -n "$NAMESPACE"

# Deploy Rollouts
echo "🔄 Deploying Argo Rollouts..."
kubectl apply -f rollouts/test-app-canary.yaml -n "$NAMESPACE"
kubectl apply -f rollouts/test-app-bluegreen.yaml -n "$NAMESPACE"

# Wait a moment for rollouts to initialize
sleep 5

# Check rollout status
echo "⏳ Checking rollout status..."
echo "📊 Canary Rollout:"
kubectl argo rollouts get rollout test-app -n "$NAMESPACE" --watch=false || echo "   (Use 'kubectl argo rollouts get rollout test-app --watch' to monitor)"

echo ""
echo "📊 Blue-Green Rollout:"
kubectl argo rollouts get rollout test-app-bg -n "$NAMESPACE" --watch=false || echo "   (Use 'kubectl argo rollouts get rollout test-app-bg --watch' to monitor)"

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📋 Test commands:"
echo "1. List all rollouts:"
echo "   kubectl argo rollouts list -n $NAMESPACE"
echo ""
echo "2. Watch canary rollout:"
echo "   kubectl argo rollouts get rollout test-app -n $NAMESPACE --watch"
echo ""
echo "3. Watch blue-green rollout:"
echo "   kubectl argo rollouts get rollout test-app-bg -n $NAMESPACE --watch"
echo ""
echo "4. Test updates (change image version):"
echo "   kubectl argo rollouts set image test-app test-app=nginx:1.21 -n $NAMESPACE"
echo "   kubectl argo rollouts set image test-app-bg test-app-bg=httpd:2.4.54 -n $NAMESPACE"
echo ""
echo "5. Get service endpoints:"
echo "   kubectl get svc -n $NAMESPACE"
echo ""
echo "6. Promote rollouts manually:"
echo "   kubectl argo rollouts promote test-app -n $NAMESPACE"
echo "   kubectl argo rollouts promote test-app-bg -n $NAMESPACE"
