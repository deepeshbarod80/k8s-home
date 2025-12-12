
# Kubernetes Gateway API – A Comprehensive, Hands-on Guide

> **Audience:** DevOps / Platform Engineers (like you, Deepesh) who already know Kubernetes Ingress and want a clear, modern approach to service networking using **Gateway API**.

---

## 1) What is Gateway API and Why It Exists

**Gateway API** is a **family of Kubernetes APIs** that standardize how traffic is exposed and routed into your cluster. Think of it as a **next‑generation Ingress** that’s:

- **Role-oriented**: Separates infra concerns (load balancers) from platform concerns (gateways) and app concerns (routes).
- **Portable**: Vendor-neutral specification—works across multiple controllers (Traefik, Istio, Envoy, Cilium, etc.).
- **Expressive & Extensible**: Modular building blocks with **GatewayClass → Gateway → Routes**, plus **filters** (URL rewrite, header mods, redirects, mirroring), **protocols** (HTTP/gRPC/TCP/UDP), and evolving policy resources.

In contrast to a single Ingress object containing everything, **Gateway API breaks traffic config into logical roles**—enabling better security boundaries, ownership, and reusability.

---

## 2) The Role-Based Model (Who Does What?)

```
+-------------------------+  defines  +--------------------+
| Infra Providers         |---------->| GatewayClass       |
| (Cloud LB, provider)    |           | (Cluster-scoped)   |
+-------------------------+           +--------------------+

+-------------------------+  instantiates  +--------------+
| Cluster Operators       |---------------->| Gateway      |
| (Ports, TLS, listeners) |                 | (Namespaced) |
+-------------------------+                 +--------------+

+-------------------------+  attaches  +------------------+
| Application Developers  |------------->| *Route objects  |
| (HTTP, gRPC, TCP, UDP)  |              | (Namespaced)    |
+-------------------------+              +------------------+
```

- **GatewayClass (cluster-scoped):** Declares *which* implementation/controller (e.g., Traefik, Istio) powers your gateways.
- **Gateway (namespaced):** Defines **listeners** (HTTP/HTTPS/TCP/UDP), **ports**, **TLS termination**, and **which routes are allowed** to attach.
- **Routes (namespaced):** Define **traffic rules** (hostnames, matches, filters) and map to **backend Services**.

This separation allows infra teams to own cloud load balancers, platform teams to own gateway lifecycle and TLS, and dev teams to own routing to their services.

---

## 3) Core Resources & Concepts

### 3.1 GatewayClass (Cluster-scoped)
- Picks the **controller implementation** for all Gateways of this class.
- Example controllers: Traefik, Istio, Envoy, Cilium, Kong, etc.
- Multiple GatewayClasses can exist (e.g., `traefik`, `istio`).

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: traefik
spec:
  controllerName: traefik.io/gateway-controller
```

> After applying, **`kubectl describe gatewayclass traefik`** should show **Accepted**. If not, your controller may be misinstalled or misconfigured.

### 3.2 Gateway (Namespaced)
- Represents an instance of traffic-handling infra (e.g., backed by a cloud LB or a daemonset/Deployment based controller).
- Declares **listeners** and **allowedRoutes** policies.

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: platform-gw
  namespace: default
spec:
  gatewayClassName: traefik
  listeners:
    - name: http
      protocol: HTTP
      port: 80
      allowedRoutes:
        namespaces:
          from: Same
    - name: https
      protocol: HTTPS
      port: 443
      tls:
        mode: Terminate
        certificateRefs:
          - kind: Secret
            name: tls-secret
            namespace: default
      allowedRoutes:
        namespaces:
          from: Same
```

> **Tip:** You can centralize TLS secrets in one namespace and reference them from the Gateway. Use **RBAC** to restrict updates.

### 3.3 Routes (Namespaced)
- **HTTPRoute / GRPCRoute / TCPRoute / UDPRoute** map traffic from **Gateway listeners** to **backend Services**.
- **parentRefs** bind a Route to a specific Gateway (and optionally, a specific listener via `sectionName`).
- **hostnames**, **matches** (path, headers, query params), and **filters** (URLRewrite, HeaderModifiers, Redirects, Mirroring) enable advanced traffic behavior.

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: python-route
  namespace: default
spec:
  parentRefs:
    - name: platform-gw
      sectionName: http  # or https when binding to TLS listener
  hostnames:
    - exampleapp-python.com
  rules:
    - backendRefs:
        - name: python-svc
          port: 5000
          weight: 1
```

---

## 4) Cluster Setup & Prerequisites (as used in the demo)

- **Cluster:** Kind (Kubernetes v1.34 in the demo). Any cluster works.
- **CRDs:** Install Gateway API CRDs (stable or experimental channel depending on features you want to test).
- **Controller:** For the demo, Traefik Gateway API controller was installed via Helm.
- **Access for local testing:** `kubectl port-forward` to the controller service/pod. No need for a cloud LB locally.
- **DNS locally:** Use `/etc/hosts` (Linux/macOS) or `C:\Windows\System32\drivers\etc\hosts` (Windows) to map test domains to `127.0.0.1`.

> For production, you’d typically use cloud LBs (ALB/NLB, Azure LB) hooked to Gateways via Service of type `LoadBalancer`.

---

## 5) Traffic Management Scenarios (with YAML)

### 5.1 Route by **Hostname**
Map **different hostnames** to different services.

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: python-by-host
  namespace: default
spec:
  parentRefs:
    - name: platform-gw
      sectionName: http
  hostnames:
    - exampleapp-python.com
  rules:
    - backendRefs:
        - name: python-svc
          port: 5000
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: go-by-host
  namespace: default
spec:
  parentRefs:
    - name: platform-gw
      sectionName: http
  hostnames:
    - exampleapp-go.com
  rules:
    - backendRefs:
        - name: go-svc
          port: 5000
```

### 5.2 Route by **Path** – Exact vs Prefix
- **Exact**: Only `/` (or the exact literal path) matches; everything else will 404 **at the Gateway**.
- **Prefix**: `/` + anything after it passes through to the upstream service.

```yaml
# Exact match – only "/" goes upstream
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: go-exact
  namespace: default
spec:
  parentRefs:
    - name: platform-gw
      sectionName: http
  hostnames:
    - exampleapp-go.com
  rules:
    - matches:
        - path:
            type: Exact
            value: /
      backendRefs:
        - name: go-svc
          port: 5000

---
# Prefix match – "/" and all subpaths pass through
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: go-prefix
  namespace: default
spec:
  parentRefs:
    - name: platform-gw
      sectionName: http
  hostnames:
    - exampleapp-go.com
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /
      backendRefs:
        - name: go-svc
          port: 5000
```

> **Debugging 404s:** Know whether the 404 originates from the **Gateway** (route didn’t match) or the **upstream service** (path exists at Gateway but app doesn’t serve it).

### 5.3 **Shared Domain** with **URL Rewrite**
Serve multiple microservices under one domain like `centralapp.com` by rewriting prefixes.

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: python-under-central
  namespace: default
spec:
  parentRefs:
    - name: platform-gw
      sectionName: http
  hostnames:
    - centralapp.com
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /api/python
      filters:
        - type: URLRewrite
          urlRewrite:
            path:
              type: ReplacePrefixMatch
              replacePrefixMatch: /
      backendRefs:
        - name: python-svc
          port: 5000
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: go-under-central
  namespace: default
spec:
  parentRefs:
    - name: platform-gw
      sectionName: http
  hostnames:
    - centralapp.com
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /api/go
      filters:
        - type: URLRewrite
          urlRewrite:
            path:
              type: ReplacePrefixMatch
              replacePrefixMatch: /
      backendRefs:
        - name: go-svc
          port: 5000
```

### 5.4 **Header Manipulation** (Response/Request)
Useful for debugging, injecting headers, or temporarily working around browser CORS in local dev.

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: go-with-response-headers
  namespace: default
spec:
  parentRefs:
    - name: platform-gw
      sectionName: http
  hostnames:
    - centralapp.com
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /api/go
      filters:
        - type: ResponseHeaderModifier
          responseHeaderModifier:
            add:
              - name: Access-Control-Allow-Origin
                value: http://localhost:8000
              - name: Access-Control-Allow-Methods
                value: GET, POST, OPTIONS
        - type: URLRewrite
          urlRewrite:
            path:
              type: ReplacePrefixMatch
              replacePrefixMatch: /
      backendRefs:
        - name: go-svc
          port: 5000
```

> **Note:** Production-grade CORS is typically handled via dedicated CORS features/policies in the controller or app. Header hacks are for demos/local dev.

### 5.5 **TLS Termination at the Gateway**
Terminate TLS at the Gateway (offload) and send HTTP to upstream services.

1. **Create TLS Secret** (self-signed for local, or real cert in prod):
   ```bash
   kubectl create secret tls tls-secret \
     --namespace default \
     --cert /path/to/tls.crt \
     --key /path/to/tls.key
   ```

2. **Add HTTPS listener on the Gateway** and reference the Secret (see Gateway spec in §3.2).

3. **Bind HTTPRoutes** to the `https` listener via `sectionName: https`.

4. **Port-forward** 443 for local testing:
   ```bash
   kubectl -n default port-forward svc/traefik 443:443
   ```

> Result: `https://centralapp.com/api/go/...` is served via TLS at the Gateway even if `go-svc` only speaks HTTP internally.

---

## 6) Installation Walkthrough (Demo Pattern)

### 6.1 Install Gateway API CRDs
Depending on your desired features, apply **stable** or **experimental** CRDs.

```bash
# Example – stable channel (typical)
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/standard-install.yaml

# Example – experimental channel (includes additional filters/routes)
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/experimental-install.yaml
```

> The exact release URLs change over time; pick the version appropriate for your cluster and controller.

### 6.2 Install a Controller (Traefik example)
```bash
helm repo add traefik https://traefik.github.io/charts
helm repo update
helm install traefik traefik/traefik --namespace default --create-namespace \
  --set experimental.kubernetesGateway.enabled=true

kubectl get pods -n default
kubectl logs -n default deploy/traefik
```

### 6.3 Local Access
- Use `kubectl port-forward` against the Traefik service or pod.
- Add test hostnames to `hosts` file pointing to `127.0.0.1`.

---

## 7) Allowed Routes & Multi-Tenancy Controls

Gateways support **AllowedRoutes** with policies like:
- `from: Same` – only routes in the same namespace can attach.
- `from: All` – routes from any namespace can attach.
- **Label selectors** – allow specific namespaces based on labels.

This enables patterns like **per-namespace Gateways** or **central Gateways** shared across teams.

---

## 8) Infrastructure Customization (Infra Labels / Annotations)

Controllers may support **infrastructure labels/annotations** to tweak the underlying cloud LB (e.g., ALB/NLB, Azure LB) behavior. In Gateway API ecosystems, these are typically configured via the Gateway or Service object according to controller docs. Think **timeouts, idle connection settings, target group attributes**, etc.

> Exact keys and semantics differ per controller/cloud; consult your chosen controller’s documentation.

---

## 9) Common Pitfalls & Debugging Checklist

- **CRDs missing/outdated**: Ensure the correct Gateway API CRDs are installed for the features you’re using.
- **Controller not accepting GatewayClass**: `kubectl describe gatewayclass <name>` → look for `Accepted: True`.
- **Routes not attached**: Check `parentRefs`, `sectionName`, and `allowedRoutes`; ensure hostnames match.
- **404 confusion**: Determine if 404 is from Gateway (route didn’t match) or upstream app (path not served).
- **TLS secret scope**: Verify `certificateRefs` points to the correct Secret and namespace.
- **Namespace boundaries**: Routes may be blocked by AllowedRoutes policies.
- **Port-forward vs Service LB**: In local tests, ensure you’re forwarding the port for the listener you’re using (80 vs 443).

Useful commands:
```bash
kubectl get gatewayclasses,gateway,httproutes -A
kubectl describe gateway <name> -n <ns>
kubectl describe httproute <name> -n <ns>
kubectl logs -n <ns> deploy/<controller-deployment>
```

---

## 10) Gateway API vs Ingress (Quick Comparison)

| Aspect | Ingress | Gateway API |
|---|---|---|
| Scope | Single object per LB/controller | Modular: GatewayClass → Gateway → Routes |
| Roles | App + infra mixed | Role-oriented: infra, platform, app |
| Protocols | Primarily HTTP/HTTPS | HTTP, gRPC, TCP, UDP (controller-dependent) |
| Extensibility | Annotations vendor-specific | Standard filters (rewrite, headers, redirect, mirror) + policies |
| Multi-tenancy | Harder; fewer boundaries | Strong boundaries via AllowedRoutes & RBAC |
| Portability | Controller-specific behaviors | Vendor-neutral spec across controllers |

---

## 11) Reference YAML Snippets (Copy‑Paste Ready)

- **GatewayClass:** see §3.1
- **Gateway (HTTP + HTTPS termination):** see §3.2
- **HTTPRoute (hostname mapping):** see §5.1
- **HTTPRoute (path prefix):** see §5.2
- **HTTPRoute (shared domain + rewrite):** see §5.3
- **HTTPRoute (response headers + rewrite):** see §5.4

> Combine these incrementally. Start with hostname routing, then add path matches, filters, and HTTPS.

---

## 12) Suggested Learning Path (for a Kubernetes Admin Track)

1. **Install CRDs & a controller** (Traefik/Istio/Envoy) in a dev cluster.
2. **Create GatewayClass** and a **central Gateway** with HTTP listener.
3. Add **HTTPRoute** with hostname routing to a demo service.
4. Add **PathPrefix** matches and **URLRewrite** to serve multiple services under one domain.
5. Add **HTTPS termination** at Gateway; rotate certs via Cert-Manager.
6. Explore **GRPCRoute/TCPRoute/UDPRoute** as needed.
7. Add **policies** (CORS, auth) as supported by your controller version.
8. Lock down with **RBAC** and **AllowedRoutes**.

---

## 13) Final Notes

- Gateway API is evolving quickly; feature availability can vary by **spec version** and **controller version**.
- Prefer **stable CRDs** for production; use **experimental CRDs** in labs to explore new filters/policies.
- Keep an eye on your controller’s docs for infra customization and policy resources.

---

## 14) A Minimal End-to-End Example (All in One)

```yaml
# 1) GatewayClass
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: traefik
spec:
  controllerName: traefik.io/gateway-controller
---
# 2) Gateway with HTTP + HTTPS termination
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: platform-gw
  namespace: default
spec:
  gatewayClassName: traefik
  listeners:
    - name: http
      protocol: HTTP
      port: 80
      allowedRoutes:
        namespaces:
          from: Same
    - name: https
      protocol: HTTPS
      port: 443
      tls:
        mode: Terminate
        certificateRefs:
          - kind: Secret
            name: tls-secret
            namespace: default
      allowedRoutes:
        namespaces:
          from: Same
---
# 3) HTTPRoutes under a shared domain with rewrite + headers
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: python-under-central
  namespace: default
spec:
  parentRefs:
    - name: platform-gw
      sectionName: https
  hostnames:
    - centralapp.com
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /api/python
      filters:
        - type: URLRewrite
          urlRewrite:
            path:
              type: ReplacePrefixMatch
              replacePrefixMatch: /
      backendRefs:
        - name: python-svc
          port: 5000
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: go-under-central
  namespace: default
spec:
  parentRefs:
    - name: platform-gw
      sectionName: https
  hostnames:
    - centralapp.com
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /api/go
      filters:
        - type: ResponseHeaderModifier
          responseHeaderModifier:
            add:
              - name: Access-Control-Allow-Origin
                value: https://centralapp.com
              - name: Access-Control-Allow-Methods
                value: GET, POST, OPTIONS
        - type: URLRewrite
          urlRewrite:
            path:
              type: ReplacePrefixMatch
              replacePrefixMatch: /
      backendRefs:
        - name: go-svc
          port: 5000
```

---

## 15) Quick Commands Cheat Sheet

```bash
# Install Traefik with Gateway API enabled
helm repo add traefik https://traefik.github.io/charts
helm repo update
helm install traefik traefik/traefik --namespace default --create-namespace \
  --set experimental.kubernetesGateway.enabled=true

# Check resources
kubectl get gatewayclass
kubectl get gateway -A
kubectl get httproute -A
kubectl describe gateway platform-gw -n default
kubectl describe httproute go-under-central -n default

# Port-forward for local testing (HTTP or HTTPS)
kubectl -n default port-forward svc/traefik 80:80
kubectl -n default port-forward svc/traefik 443:443
```

---

**Happy routing!** If you want, I can adapt this doc to your current stack (Istio with mTLS, Calico policies, Argo CD multi-cluster) and add GitOps-ready manifests.
