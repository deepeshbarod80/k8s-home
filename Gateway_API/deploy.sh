#!/bin/bash

# Kubernetes Gateway API Deployment Script

echo "Deploying Gateway API resources..."

# Apply GatewayClass
echo "Creating GatewayClass..."
kubectl apply -f 01-gatewayclass.yaml

# Apply Gateway
echo "Creating Gateway..."
kubectl apply -f 02-gateway.yaml

# Apply basic HTTPRoute
echo "Creating basic HTTPRoute..."
kubectl apply -f 03-basic-httproute.yaml

# Apply hostname routing
echo "Creating hostname-based routing..."
kubectl apply -f 04-hostname-routing.yaml

# Apply path routing
echo "Creating path-based routing..."
kubectl apply -f 05-path-routing.yaml

# Apply URL rewrite
echo "Creating URL rewrite routing..."
kubectl apply -f 06-url-rewrite.yaml

echo "Deployment complete!"

# Check status
echo "Checking Gateway status..."
kubectl get gatewayclass
kubectl get gateway
kubectl get httproute