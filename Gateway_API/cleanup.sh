#!/bin/bash

# Kubernetes Gateway API Cleanup Script

echo "Cleaning up Gateway API resources..."

# Delete HTTPRoutes first
echo "Deleting HTTPRoutes..."
kubectl delete -f 06-url-rewrite.yaml --ignore-not-found=true
kubectl delete -f 05-path-routing.yaml --ignore-not-found=true
kubectl delete -f 04-hostname-routing.yaml --ignore-not-found=true
kubectl delete -f 03-basic-httproute.yaml --ignore-not-found=true

# Delete Gateway
echo "Deleting Gateway..."
kubectl delete -f 02-gateway.yaml --ignore-not-found=true

# Delete GatewayClass
echo "Deleting GatewayClass..."
kubectl delete -f 01-gatewayclass.yaml --ignore-not-found=true

echo "Cleanup complete!"