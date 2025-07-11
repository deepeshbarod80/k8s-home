

# **Kubernetes Dashboard Installation and Setup on kind Cluster**
This guide walks you through setting up the Kubernetes Dashboard on a kind (Kubernetes in Docker) cluster, including cluster creation, dashboard deployment, and secure access configuration.

#### Prerequisites
- Docker installed and running
- kind installed (go install sigs.k8s.io/kind@v0.24.0 or equivalent)
- kubectl installed
- Basic familiarity with Kubernetes and command-line tools


### **Step 1: Create a kind Cluster**
1) Create a kind cluster with a single control-plane node using configuration file for the kind cluster:
```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
```

- Save this as `kind-config.yaml`.

2) Create the cluster:
```bash
kind create cluster --config kind-config.yaml --name my-cluster
```

3) Verify the cluster is running:
```bash
kubectl cluster-info --context kind-my-cluster
```

### **Step 2: Deploy the Kubernetes Dashboard**
- Deploy the official Kubernetes Dashboard using the recommended YAML manifest.
- Apply the Kubernetes Dashboard manifest:
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
```

- Verify the dashboard pods are running in the kubernetes-dashboard namespace:
```bash
kubectl get pods -n kubernetes-dashboard
```

### **Step 3: Create a Service Account for Dashboard Access**
1) Create a service account and bind it to a cluster role to allow dashboard access.
- Create a file named dashboard-admin.yaml with the following content:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: dashboard-admin
  namespace: kubernetes-dashboard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: dashboard-admin-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: dashboard-admin
  namespace: kubernetes-dashboard
```

- Apply the service account and role binding:
```bash
kubectl apply -f dashboard-admin.yaml
```

- Verify the service account and role binding are created:


2) Retrieve the token for the service account:
```bash
kubectl -n kubernetes-dashboard create token dashboard-admin
```
- Save the output token for later use.


### **Step 4: Access the Kubernetes Dashboard**
- Access the dashboard by setting up a proxy and logging in with the token.

- Start the kubectl proxy:
```bash
kubectl proxy
```

- Open the dashboard in your browser at:
```bash
http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:dashboard-kubernetes-dashboard:/proxy/
```

- Choose the Token option on the dashboard login page and paste the token obtained in Step 3.



### **Step 5: Verify Dashboard Functionality**
- After logging in, you should see the Kubernetes Dashboard interface.
- Explore cluster resources like pods, deployments, and nodes.
- Ensure you can view and interact with resources in the default and kubernetes-dashboard namespaces.


### **Step 6: Clean Up (Optional)**
1) To delete the kind cluster and dashboard resources when done:

- Delete the kind cluster:
```bash
kind delete cluster --name my-cluster
```

- Alternatively, delete only the dashboard:
```bash
kubectl delete -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
kubectl delete -f dashboard-admin.yaml
```

### Notes
- The Kubernetes Dashboard is deployed in the kubernetes-dashboard namespace by default.
- The cluster-admin role provides full access; for production, consider least-privilege roles.

- If you encounter issues, check pod logs:
```bash
kubectl logs -n kubernetes-dashboard -l k8s-app=kubernetes-dashboard
```

---
