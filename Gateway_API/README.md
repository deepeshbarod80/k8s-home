# Gateway API Configuration Files

This folder contains Kubernetes Gateway API configuration files extracted from the comprehensive guide.

## Files Overview

- `01-gatewayclass.yaml` - Defines the Traefik GatewayClass
- `02-gateway.yaml` - Creates the main Gateway with HTTP/HTTPS listeners
- `03-basic-httproute.yaml` - Basic HTTPRoute example
- `04-hostname-routing.yaml` - Hostname-based routing examples
- `05-path-routing.yaml` - Path-based routing (exact vs prefix)
- `06-url-rewrite.yaml` - URL rewrite examples for shared domains
- `deploy.sh` - Script to deploy all resources
- `cleanup.sh` - Script to clean up all resources

## Usage

1. Deploy all resources:
   ```bash
   chmod +x deploy.sh
   ./deploy.sh
   ```

2. Clean up resources:
   ```bash
   chmod +x cleanup.sh
   ./cleanup.sh
   ```

3. Deploy individual files:
   ```bash
   kubectl apply -f 01-gatewayclass.yaml
   ```

## Prerequisites

- Kubernetes cluster with Gateway API CRDs installed
- Traefik Gateway API controller installed
- Required services (python-svc, go-svc) deployed