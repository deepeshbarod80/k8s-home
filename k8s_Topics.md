
# Kubernetes Topics to learn

---

## 🧠 **Level 1: Kubernetes Basics (Foundational)**

> 🔑 Goal: K8s Components

- Master Node (Contol Plane)
  * API Server
  * Scheduler
  * ETCD 
  * Controller Manager
  * Cloud Controller Manager

- Worker Node
  * Kubelet
  * KubeProxy
  * Container Runtime (e.g., Docker)

- Core Objects
  * Pods
  * ReplicaSets
  * Deployments
  * StatefulSets
  * DaemonSets
  * Services (ClusterIP, NodePort, LoadBalancer) 
  * ConfigMaps
  * Secrets
  * Namespaces (ns)
  * Ingress
  * Persistant Volume
  * Persistent Volume Claim (pvc)
  * Jobs & Cronjobs
  * 

- Common Controllers
  * Ingress Controller
  * Replication Controller
  * Admission Controller
  * HPA Controller
  * VPA controller
  * Cronjob Controller
  * Deployment Controller
  * Replicaset Controller
  * Statefulset Controller
  * Daemonset Controller
  * 





> 🔑 Goal: Understand K8s architecture and core objects

* What is Kubernetes? Benefits & Use Cases
* Kubernetes Architecture: Master vs Worker nodes
* Core Components: kube-apiserver, etcd, kube-scheduler, kube-controller-manager, kubelet, kube-proxy
* Kubernetes Object Basics:
  * Pods
  * ReplicaSets
  * Deployments
  * Services (ClusterIP, NodePort, LoadBalancer)
  * ConfigMaps
  * Secrets
* Namespaces
* Labels & Selectors
* Lifecycle of a Pod
* kubectl CLI usage & YAML definitions

---

## ⚙️ **Level 2: Intermediate Operations**

> 🔑 Goal: Handle production-like tasks and setups

* Volumes and PersistentVolumes / PersistentVolumeClaims (PV/PVC)
* StatefulSets vs Deployments
* DaemonSets
* Jobs and CronJobs
* Rolling Updates and Rollbacks
* Liveness & Readiness Probes
* Resource requests & limits
* Taints and Tolerations
* Node Affinity & Pod Affinity/Anti-Affinity
* Service Discovery and DNS
* Ingress and Ingress Controllers (e.g., NGINX Ingress)
* Helm package manager
* Secrets
* Certificates
* HPA (Horizontal Pod Autoscaler)
* CRD (Custom Resource Definition) (e.g., Ingress, PodSecurityPolicy, ClusterRole, ClusterRoleBinding, etc)
* CSI (Container Storage Interface) Driver (e.g., azure disk, aws ebs, gce pd)
* CNI (Container Network Interface) plugins (e.g., Calico, Weave)
* Metrics server and node exporter
* ExternalSecret Operator and ExternalSecret Resource
* Cluster Issuer 
* RBAC (Role, RoleBinding, ClusterRole, ClusterRoleBinding)
* Service Accounts

> 🔑 Goal: AWS Services Related Topics
* AWS SM (Secrets manager)
* AWS KMS (Key management service)
* AWS CM (Certificate manager)
* AWS PCA (Private certificate authority)
* AWS IAM (Identity and Access Management)




---

## 🧪 **Level 3: Advanced Cluster Management**

> 🔑 Goal: Production-grade cluster management

* Kubeadm / Kops / Kubespray / EKS / GKE / AKS cluster provisioning
* Node Pool management (auto-scaling, node upgrades)
* Cluster Autoscaler vs HPA vs VPA
* Kubernetes Dashboard and Metrics Server
* Custom Resource Definitions (CRDs) and Operators
* Admission Controllers (Mutating & Validating Webhooks)
* API Aggregation Layer
* EKS Pod Identities

---

## 🔐 **Level 4: Kubernetes Security**

> 🔑 Goal: Secure workloads and the cluster

* Role-Based Access Control (RBAC)
* Network Policies
* PodSecurity Standards (PSS) [restricted, baseline, privileged]
* PodSecurityPolicies (PSP) [(deprecated) → OPA Gatekeeper / Kyverno]
* TLS Certificates and Encryption in Transit
* Secret Management (external providers like HashiCorp Vault, AWS Secrets Manager)
* Image Scanning (Trivy, Clair, Aqua)
* Seccomp, AppArmor, and SELinux basics
* Security Contexts in Pods
* Audit Logging
* Kubernetes CIS Benchmarks

---

## 📈 **Level 5: Monitoring, Logging & Observability**

> 🔑 Goal: Full visibility into app and cluster behavior

* Prometheus Setup (with AlertManager)
* Grafana Dashboards for K8s
* kube-state-metrics
* Node Exporter
* cAdvisor
* EFK/ELK Stack: Elasticsearch, Fluentd/FluentBit, Kibana
* Loki & Tempo (Grafana Stack)
* Tracing with Jaeger / OpenTelemetry
* Metrics-server and custom metrics

---

## 🔁 **Level 6: CI/CD with Kubernetes**

> 🔑 Goal: Automate builds, testing, and deployments

* GitOps (ArgoCD, FluxCD)
* Jenkins-X, Tekton Pipelines
* CI/CD pipelines deploying to K8s
* Canary Deployments
* Blue/Green Deployments
* Progressive Delivery (using Argo Rollouts or Flagger)

---

## 🛡️ **Level 7: High Availability & Disaster Recovery**

> 🔑 Goal: Build resilient, fault-tolerant clusters

* etcd backup and restore
* HA master nodes setup
* Cluster & Node level backups
* Velero for backup & restore
* Multi-region K8s cluster concepts
* HA Ingress Controllers
* Load Balancers (NGINX, HAProxy, AWS ALB/NLB, Istio Gateways)

---

## 🔍 **Level 8: Service Mesh & Advanced Networking**

> 🔑 Goal: Fine-grained traffic control and security

* Istio / Linkerd Basics
* Envoy Proxy
* Mutual TLS (mTLS)
* Traffic Splitting and Routing Rules
* Sidecar Injection
* Rate Limiting and Circuit Breakers
* Observability with Kiali + Istio

---

## 🧪 **Level 9: Troubleshooting & Performance Tuning**

> 🔑 Goal: Diagnose and resolve production issues

* Debugging Pods and Nodes (`kubectl describe`, `logs`, `exec`)
* CrashLoopBackOff, ImagePullBackOff, OOMKilled diagnostics
* Troubleshooting networking (CNI plugins, DNS, connectivity)
* Monitoring system & app performance (CPU, Memory, Latency)
* Benchmarking tools (wrk, hey, ApacheBench)
* Analyzing etcd performance

---

## 🧩 **Level 10: Multi-Tenancy, Multi-Cluster, and Edge**

> 🔑 Goal: Enterprise-scale architecture knowledge

* Multi-Tenancy Strategies (Namespace Isolation, RBAC, NetworkPolicies)
* Federation (KubeFed v2)
* Crossplane, Karmada
* Cluster API (CAPI)
* KubeEdge, MicroK8s, K3s
* Managing Edge Nodes
* Bare Metal K8s Considerations

---

## 📚 Bonus: Certifications & Tools to Master

> Helps validate your skills and build real experience

* **Certifications**:

  * CKA (Certified Kubernetes Administrator)
  * CKAD (Certified Kubernetes Application Developer)
  * CKS (Certified Kubernetes Security Specialist)

* **Tools & Platforms**:

  * Lens, k9s
  * Minikube, Kind
  * Rancher
  * OpenShift (for enterprise environments)
  * Terraform for K8s infrastructure
  * Kustomize

---

## ✅ Pro Tips for Senior DevOps Role:

* Always **document your clusters** and environments.
* Contribute to real-world projects or open source (e.g., helm charts, operators).
* Build a GitOps-based deployment model.
* Keep up with CNCF landscape & new tools.
* Learn cloud-native design patterns.

---