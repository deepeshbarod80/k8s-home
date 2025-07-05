
# Kubernetes Cheatsheet

### Pod Commands:-
```bash
kubectl get pod                                      # Get pod
kubectl get pod -o wide                              # Get pod wide information
kubectl get pod -w                                   # Get pod with watch
kubectl get pod -o yaml                              # Get pod in yaml
kubectl edit pod <pod_name>                          # Edit pod
kubectl describe pod <pod_name>                      # Describe pod
kubectl delete pod <pod_name>                        # Delete pod
kubectl logs pod <pod_name>                          # Logs of the pod
kubectl exec -it pod <pod_name> /bin/bash            # Execute into pod
```

### Node Commands:-
```bash
kubectl describe node <node_name>                     # Describe node
kubectl get node <node_name> -o yaml                  # Get node in
kubectl get node <node_name>                          # Get node yaml
kubectl drain node <node_name>                        # Drain node
kubectl cordon node <node_name>                       # Cordon node
kubectl uncordon node <node_name>                     # Uncordon node
```

### Creating Objects:-
```bash
kubectl apply -f <file_name> yaml                      # Create resource
kubectl apply -f <file_name>.yaml -f <file_name>.yaml  # Create from multiple files
kubectl apply -f ./ <directory_name>                   # Create all files in directory
kubectl apply -f https:// <url>                        # Create from url
kubectl run <pod_name> --image <image_name>            # Create pod

# Create pod, then expose it as service
kubectl run <pod_name> --image <image_name> --port <port> --expose  

# Create Pod YAML File in dry run mode
kubectl run <pod_name> --image=<image_name> --dry-run=client -o yaml > <file_name>.yaml 

# Create Deployment 
kubectl create deployment <deployment_name> --image=<image_name>

# Create Deployment YAML File in dry run mode
kubectl create deployment <deployment_name> --image=<image_name> -o yaml > <file_name>.yaml

# Create Service
kubectl create service <service-type><service_name> --tcp=<port:target_port> : Create Service

# Create Service in a YAML File
kubectl create service <service-type> <service_name> --tcp=<port:target_port> -o yaml > <file_name>.yaml

# Expose Service from Pod/Deployment
kubectl expose deployment <pod/deployment_name> --type=<service-type> --port=<port> --target-port=<target_port>

# Create ConfigMap from Key-Value Pairs
kubectl create configmap <configmap_name> --from-literal=<key>=<value> --from-literal=<key>=<value>

# Create ConfigMap from File
kubectl create configmap <configmap_name> --from-file=<file_name>

# Create ConfigMap from Environment File
kubectl create configmap <configmap_name> --from-env-file=<file_name>  

# Create Secret from Key-Value Pairs
kubectl create secret generic <secret_name> --from-literal=<key>=<value> --from-literal=<key>=<value>

# Create Secret from File
kubectl create secret generic <secret_name> --from-file=<file_name>
```

### Monitoring Usage Commands:-
```bash
kubectl top node <node_name>                  # Get node cpu and memory utilization
kubectl top pods <pod_name>                   # Get pod cpu and memory utilization
```

### Deployment Commands:-
```bash
kubectl get deployment <deployment_name>                          # Get Deployment
kubectl get deployment <deployment_name> -o yaml                  # Get Deployment in YAML Format
kubectl get deployment <deployment_name> -o wide                  # Get Deployment Wide Information
kubectl edit deployment <deployment_name>                         # Edit Deployment
kubectl describe deployment <deployment_name>                     # Describe Deployment
kubectl delete deployment <deployment_name>                       # Delete Deployment
kubectl scale deployment <deployment_name> --replicas=<replicas>  # Scale Deployment Replicas
```

### Service Commands:-
```bash
kubectl get service <service>                   # Get Service
kubectl get service <service> -o yaml           # Get Service in YAML Format
kubectl get service <service> -o wide           # Get Service Wide Information
kubectl edit service <service>                  # Edit Service
kubectl describe service <service>              # Describe Service
kubectl delete service <service>                # Delete Service
```

### Ingress Commands:-
```bash
kubectl get ingress                             # Get Ingress resources
kubectl get ingress -o yaml                     # Get Ingress in YAML Format
kubectl get ingress -o wide                     # Get Ingress Wide Information
kubectl edit ingress <ingress_name>             # Edit Ingress
kubectl describe ingress <ingress_name>         # Describe Ingress
kubectl delete ingress <ingress_name>           # Delete Ingress
```

### Endpoints Commands:-
```bash
kubectl get endpoints <endpoints _name>         # Get endpoints
```

### DaemonSet Commands:-
```bash
kubectl get daemonset <daemonset_name>          # Get DaemonSet
kubectl get daemonset <daemonset_name> -o yaml  # Get DaemonSet in YAML Format
kubectl edit daemonset <daemonset_name>         # Edit DaemonSet
kubectl describe daemonset <daemonset_name>     # Describe DaemonSet
kubectl delete daemonset <daemonset_name>       # Delete DaemonSet
```

### Job Commands:-
```bash
kubectl get job <job_name>               # Get Job details
kubectl get job <job_name> -o yaml       # Get Job details in YAML format
kubectl edit job <job_name>              # Edit Job the specific job
kubectl describe job <job_name>          # Describe a specific Job
kubectl delete job <job_name>            # Delete a specific Job
```

### Rollout Commands:-
```bash
kubectl rollout restart deployment <deployment_name>      # Restart Deployment
kubectl rollout undo deployment <deployment_name>         # Undo Deployment with the Latest Revision

# Undo Deployment with Specified Revision
kubectl rollout undo deployment <deployment_name> --to-revision=<revision_number> 

# Get complete history Revisions of Deployment
kubectl rollout history deployment <deployment_name>

# Get Specified Revision of Deployment
kubectl rollout history deployment <deployment_name> --revision=<revision_number>
```

### Secret Commands:-
```bash
kubectl get secret <secret_name>          # Get Secret
kubectl describe secret <secret_name>     # Describe Secret
kubectl delete secret <secret_name>       # Delete Secret
kubectl edit secret <secret_name>         # Edit Secret
```

---

# Kubernetes (k8s) Cheat Sheet
## Basic kubectl Commands

### Cluster Information
```bash
kubectl cluster-info                                   # Display cluster info
kubectl version                                        # Show client and server versions
kubectl config current-context                         # Show current context
kubectl config get-contexts                            # List all contexts
kubectl config use-context <context>                   # Switch context
```

### Namespace Operations
```bash
kubectl get namespaces                                     # List all namespaces
kubectl create namespace <name>                            # Create a new namespace
kubectl delete namespace <name>                            # Delete a namespace
kubectl config set-context --current --namespace=<name>    # Set default namespace
```

---


## Pod Operations
### Viewing Pods
```bash
kubectl get pods                                  # List pods in current namespace
kubectl get pods -A                               # List pods in all namespaces
kubectl get pods -o wide                          # List pods with additional info
kubectl get pods --show-labels                    # List pods with labels
kubectl get pods -l app=myapp                     # List pods with specific label
```

### Pod Details
```bash
kubectl describe pod <pod-name>                    # Show detailed pod information
kubectl logs <pod-name>                            # Show pod logs
kubectl logs -f <pod-name>                         # Follow pod logs
kubectl logs <pod-name> -c <container>             # Show logs for specific container
kubectl exec -it <pod-name> -- /bin/bash           # Execute shell in pod
kubectl exec <pod-name> -- <command>               # Execute command in pod
```

### Pod Management
```bash
kubectl create pod <pod-name> --image=<image>             # Create a new pod
kubectl run <pod-name> --image=<image>                    # Create and run a pod
kubectl delete pod <pod-name>                             # Delete a pod
kubectl port-forward <pod-name> <local-port>:<pod-port>   # Port forward
```

---


## Deployment Operations

### Creating Deployments
```bash
kubectl create deployment <name> --image=<image>        # Create deployment
kubectl run <name> --image=<image> --replicas=3         # Create deployment with replicas
```

### Managing Deployments
```bash
kubectl get deployments                                 # List deployments
kubectl describe deployment <name>                      # Show deployment details
kubectl scale deployment <name> --replicas=5            # Scale deployment
kubectl rollout status deployment <name>                # Check rollout status
kubectl rollout history deployment <name>               # View rollout history
kubectl rollout undo deployment <name>                  # Rollback to previous version
```

### Updating Deployments
```bash
kubectl set image deployment/<name> <container>=<new-image>      # Update image
kubectl patch deployment <name> -p '{"spec":{"replicas":5}}'     # Patch deployment
```

---


## Service Operations
### Service Management
```bash
kubectl get services                                              # List all services
kubectl get svc                                                   # List all services (short)
kubectl describe service <name>                                   # Show service details
kubectl expose deployment <name> --type=LoadBalancer --port=80    # Expose deployment
kubectl delete service <name>                                     # Delete service
```

### Service Types
```bash
# ClusterIP (default) - Internal cluster access only
kubectl expose deployment <name> --port=80 --target-port=8080
# NodePort - External access via node IP
kubectl expose deployment <name> --type=NodePort --port=80
# LoadBalancer - External access via cloud load balancer
kubectl expose deployment <name> --type=LoadBalancer --port=80
```

---


## ConfigMap and Secret Operations

### ConfigMaps
```bash
kubectl create configmap <name> --from-literal=key=value           # Create from literal
kubectl create configmap <name> --from-file=<file>                 # Create from file
kubectl get configmaps                                             # List configmaps
kubectl describe configmap <name>                                  # Show configmap details
```

### Secrets
```bash
kubectl create secret generic <name> --from-literal=key=value    # Create secret
kubectl get secrets                                              # List secrets
kubectl describe secret <name>                                   # Show secret details (values hidden)
kubectl delete secret <name>                                     # Delete secret

# Create a Docker registry secret
kubectl create secret docker-registry <name> --docker-server=<server> --docker-username=<user> --docker-password=<pass>

```

---


## Resource Management
### Apply and Delete
```bash
kubectl apply -f <file.yaml>                  # Apply configuration from file
kubectl apply -f <directory>/                 # Apply all files in directory
kubectl apply -f <url>                        # Apply configuration from URL
kubectl delete -f <file.yaml>                 # Delete resources from file
kubectl delete -f <directory>/                # Delete all files in directory
kubectl replace -f <file.yaml>                # Replace resources from file
```

### Resource Information
```bash
kubectl get all                               # List most resource types
kubectl get <resource-type>                   # List specific resource type
kubectl describe <resource-type> <name>       # Describe specific resource
kubectl explain <resource-type>               # Show resource documentation
```

---


## Troubleshooting Commands

### Debugging
```bash
kubectl get events --sort-by=.metadata.creationTimestamp      # View cluster events
kubectl top nodes                    # Show node resource usage (requires metrics-server)
kubectl top pods                                              # Show pod resource usage
kubectl describe node <node-name>                             # Show node details
```

### Network Troubleshooting
```bash
kubectl run test-pod --image=busybox --rm -it -- sh         # Create temporary test pod
kubectl exec -it <pod> -- nslookup <service-name>           # DNS lookup from pod
kubectl port-forward service/<service-name> <local-port>:<service-port> # Port forward service
```


### Labels and Selectors
```bash
kubectl label pods <pod-name> <key>=<value>            # Add label to pod
kubectl label pods <pod-name> <key>-                   # Remove label from pod
kubectl get pods -l <key>=<value>                      # Filter by label
kubectl get pods -l '<key> in (value1,value2)'         # Filter by multiple values
```

---


## Advanced Operations

### Persistent Volumes
```bash
kubectl get pv                                      # List persistent volumes
kubectl get pvc                                     # List persistent volume claims
kubectl describe pv <name>                          # Show PV details
kubectl describe pvc <name>                         # Show PVC details
```

### Jobs and CronJobs
```bash
kubectl create job <name> --image=<image>           # Create job
kubectl get jobs                                    # List jobs
kubectl create cronjob <name> --image=<image> --schedule="0 */6 * * *"  # Create cronjob
kubectl get cronjobs                                # List cronjobs
kubectl describe cronjob <name>                     # Show cronjob details
kubectl delete cronjob <name>                       # Delete cronjob
```

### Resource Quotas and Limits
```bash
kubectl describe quota              # Show resource quotas
kubectl describe limits             # Show limit ranges
kubectl top nodes                   # Resource usage by nodes
kubectl top pods --containers       # Resource usage by containers
```

---


## Useful Flags and Options

### Output Formats
```bash
-o wide                                 # Additional columns
-o yaml                                 # YAML output
-o json                                 # JSON output
-o jsonpath='{.items[*].metadata.name}' # Custom JSONPath
--no-headers                            # Remove headers
--show-labels                           # Show labels
```

### Common Flags
```bash
--all-namespaces, -A                # All namespaces
--namespace=<name>, -n <name>       # Specific namespace
--selector=<label>, -l <label>      # Label selector
--field-selector=<field>            # Field selector
--watch, -w                         # Watch for changes
--dry-run=client                    # Preview without applying
```

---


## Quick YAML Templates

### Basic Pod
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
spec:
  containers:
  - name: my-container
    image: nginx:latest
    ports:
    - containerPort: 80
```

### Basic Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
   name: my-deployment
spec:
   replicas: 3
   selector:
      matchLabels:
         app: my-app
   template:
      metadata:
         labels:
           app: my-app
      spec:
        containers:
        - name: my-container
          image: nginx:latest
          ports:
          - containerPort: 80
```

### Basic Service
```yaml
apiVersion: v1
kind: Service
metadata:
   name: my-service
spec:
   selector:
     app: my-app
   ports:
   - protocol: TCP
     port: 80
     targetPort: 80
   type: ClusterIP
```

---

## Helpful Aliases
- Add these to your shell profile:
```bash
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgd='kubectl get deployments'
alias kdp='kubectl describe pod'
alias kds='kubectl describe service'
alias kdd='kubectl describe deployment'
alias kaf='kubectl apply -f'
alias kdf='kubectl delete -f'
```

---