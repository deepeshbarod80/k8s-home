# Setup Guide: Kind Cluster with Calico, Istio, and Gateway API (NodePort Access)

This guide walks you through setting up a **Kind cluster** with **Calico CNI**, **Istio Service Mesh**, and **Gateway API** on your local Ubuntu machine, and exposing services via **NodePort**.

---

## ✅ 1. Prerequisites
Install required tools:

```bash
# Docker
sudo apt-get update && sudo apt-get install -y docker.io

# Kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.23.0/kind-linux-amd64
chmod +x ./kind && sudo mv ./kind /usr/local/bin/kind

# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl && sudo mv kubectl /usr/local/bin/

# Helm (for Istio)
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

---

## ✅ 2. Create Kind Cluster with Calico
Create a config file `kind-calico-config.yaml`:

```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
networking:
  disableDefaultCNI: true
  podSubnet: "192.168.0.0/16"   # Matches Calico default
nodes:
- role: control-plane
  image: kindest/node:v1.34.0
- role: worker
  image: kindest/node:v1.34.0
- role: worker
  image: kindest/node:v1.34.0
- role: worker
  image: kindest/node:v1.34.0
```

Create the cluster:
```bash
kind create cluster --name istio-calico --config kind-calico-config.yaml
```

Install Calico:
```bash
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/calico.yaml
kubectl get pods -n kube-system
```

Wait until nodes are **Ready**:
```bash
kubectl get nodes
```

---

## ✅ 3. Install Istio
Download Istio:
```bash
curl -L https://istio.io/downloadIstio | sh -
cd istio-*
export PATH=$PWD/bin:$PATH
```

Install Istio (demo profile):
```bash
istioctl install --set profile=demo -y
kubectl label namespace default istio-injection=enabled
kubectl get pods -n istio-system
```

---

## ✅ 4. Install Gateway API CRDs
```bash
kubectl apply -k "github.com/kubernetes-sigs/gateway-api/config/crd?ref=v1.0.0"
kubectl get crd | grep gateway
```

---

## ✅ 5. Create GatewayClass and Gateway
Create `istio-gatewayclass.yaml`:
```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: istio
spec:
  controllerName: istio.io/gateway-controller
```
Apply:
```bash
kubectl apply -f istio-gatewayclass.yaml
```

Create `istio-gateway.yaml`:
```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: istio-gateway
  namespace: istio-system
spec:
  gatewayClassName: istio
  listeners:
    - name: http
      protocol: HTTP
      port: 80
      allowedRoutes:
        namespaces:
          from: All
```
Apply:
```bash
kubectl apply -f istio-gateway.yaml
```

Label Gateway with Istio revision:
```bash
kubectl label gateway istio-gateway -n istio-system istio.io/rev=default --overwrite
```

---

## ✅ 6. Deploy a Test App and HTTPRoute
Deploy echo app:
```bash
kubectl create deploy echo --image=ealen/echo-server -n default
kubectl expose deploy echo --port=80 -n default
```

Create `echo-route.yaml`:
```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: echo-route
  namespace: default
spec:
  parentRefs:
    - name: istio-gateway
      namespace: istio-system
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /
      backendRefs:
        - name: echo
          port: 80
```
Apply:
```bash
kubectl apply -f echo-route.yaml
kubectl get httproute -A
```

---

## ✅ 7. Access via NodePort
Check NodePort:
```bash
kubectl get svc -n istio-system
```

#### If ingress-gateway service is not on nodeport then you need to forward it's port.
Example output:
```
istio-gateway-istio ... 80:30059/TCP
istio-ingressgateway ... 80:30090/TCP
```
Access in browser:
```
http://localhost:30059/
```
or
```
http://localhost:30090/
```

---

## ✅ 8. Optional: Port-forward for a fixed port
```bash
kubectl -n istio-system port-forward svc/istio-gateway-istio 7001:80
```
Access:
```
http://127.0.0.1:7001/
```

---

### ✅ At this point:
- Kind cluster is running with **Calico CNI**.
- Istio is installed and integrated with **Gateway API**.
- Gateway and HTTPRoute are configured.
- You can access services via **NodePort** or **port-forward**.

