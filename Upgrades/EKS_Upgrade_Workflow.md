# Step-by-Step Workflow to Upgrade an Amazon EKS Cluster and Components

This workflow provides a detailed, production-ready process for upgrading an Amazon EKS cluster and its components, ensuring minimal downtime and compatibility. The steps are designed for a cluster running Calico, Prometheus, Grafana, Metrics Server, HPA, RBAC, AWS Secrets Manager, Pod Identity, KMS, Cluster Autoscaler, ALB, NGINX Ingress, ArgoCD, Helm, ELK, and Jaeger.

### Prerequisites
- **Tools**: Install `kubectl`, `aws`, `eksctl`, `calicoctl`, `argocd`, `helm`, and `terraform` (if using Infrastructure as Code).
- **Permissions**: Ensure IAM and RBAC permissions for EKS, Secrets Manager, and KMS.
- **Backup**: Back up the cluster using Velero or similar tools to restore workloads if needed.
- **Staging Environment**: Test upgrades in a non-production environment first.
- **Version Check**: Identify the current EKS version (`kubectl version`) and target version (one minor version at a time, e.g., 1.27 to 1.28).[](https://dev.to/damola12345/upgrading-an-eks-cluster-a-step-by-step-guide-2alk)

## Step 1: Plan and Assess Compatibility
- **Review Release Notes**:
  - Check Kubernetes release notes for the target version (e.g., [Kubernetes Release Notes](https://kubernetes.io/releases/)) for deprecated APIs or breaking changes.[](https://repost.aws/knowledge-center/eks-plan-upgrade-cluster)
  - Review AWS EKS version lifecycle for support details ([EKS Version Lifecycle](https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions.html)).[](https://docs.aws.amazon.com/eks/latest/best-practices/cluster-upgrades.html)
- **Check Add-On Compatibility**:
  - Verify compatibility for all components (e.g., Calico, Prometheus, NGINX Ingress) with the target EKS version. Use vendor documentation (e.g., [Calico Releases](https://projectcalico.docs.tigera.io), [AWS Load Balancer Controller](https://github.com/kubernetes-sigs/aws-load-balancer-controller)).[](https://repost.aws/knowledge-center/eks-plan-upgrade-cluster)[](https://www.fairwinds.com/blog/guide-securely-upgrading-eks-clusters)
  - Use `kube-no-trouble` (kubent) to detect deprecated APIs:
    ```bash
    kubent --target-version <target-k8s-version>
    ```
- **Document Runbook**:
  - Create a runbook detailing the upgrade sequence, rollback plan, and validation steps.[](https://docs.aws.amazon.com/eks/latest/best-practices/cluster-upgrades.html)
- **Enable Control Plane Logging**:
  - Enable EKS control plane logging to capture errors during the upgrade:
    ```bash
    aws eks update-cluster-config --region <region> --name <cluster-name> --logging '{"clusterLogging":[{"types":["api","audit","authenticator","controllerManager","scheduler"],"enabled":true}]}'
    ```

## Step 2: Test in a Non-Production Environment
- **Create a Staging Cluster**:
  - Clone the production cluster configuration in a staging environment using `eksctl` or Terraform:
    ```bash
    eksctl create cluster --name staging-cluster --version <current-version> --region <region>
    ```
  - Deploy all components (e.g., ArgoCD, Prometheus) to mirror production.
- **Simulate Upgrade**:
  - Follow the steps below in the staging environment to identify issues.
  - Test application behavior with the new Kubernetes version.[](https://docs.aws.amazon.com/eks/latest/userguide/update-cluster.html)
- **Validate Workloads**:
  - Run automated tests (e.g., CI/CD pipelines) to ensure application compatibility.

## Step 3: Update EKS Control Plane
- **Check Current Version**:
  - Verify the current EKS version:
    ```bash
    aws eks describe-cluster --name <cluster-name> --region <region> --query 'cluster.version'
    ```
- **Upgrade Control Plane**:
  - Use `eksctl` to upgrade the control plane to the next minor version (e.g., 1.27 to 1.28):
    ```bash
    eksctl upgrade cluster --name <cluster-name> --version <target-version> --region <region> --approve
    ```
  - Or use AWS Console: Navigate to EKS > Clusters > <cluster-name> > Update > Select target version > Upgrade.
  - Monitor the update status (takes ~10-15 minutes):
    ```bash
    aws eks describe-update --name <cluster-name> --region <region> --update-id <update-id>
    ```
  - Note: You cannot downgrade after upgrading.[](https://docs.aws.amazon.com/eks/latest/userguide/update-cluster.html)
- **Verify Control Plane**:
  - Confirm the new version:
    ```bash
    kubectl version --short
    ```

## Step 4: Update EKS Managed Node Groups
- **Check Node Versions**:
  - List node versions to ensure they match the control plane or are one version behind:
    ```bash
    kubectl get nodes -o wide
    ```
- **Update Managed Node Groups**:
  - Upgrade node groups one at a time to minimize disruption (EKS limits unavailable nodes to 33% by default):
    ```bash
    aws eks update-nodegroup-version --cluster-name <cluster-name> --nodegroup-name <nodegroup-name> --kubernetes-version <target-version> --region <region>
    ```
  - Or use `eksctl`:
    ```bash
    eksctl upgrade nodegroup --name <nodegroup-name> --cluster <cluster-name> --kubernetes-version <target-version> --region <region>
    ```
  - Monitor node group updates:
    ```bash
    aws eks describe-nodegroup --cluster-name <cluster-name> --nodegroup-name <nodegroup-name> --region <region>
    ```
- **Verify Nodes**:
  - Ensure all nodes are updated and healthy:
    ```bash
    kubectl get nodes -o wide
    ```

## Step 5: Update Cluster Add-Ons
- **Amazon VPC CNI (if not using Calico)**:
  - Check current version:
    ```bash
    kubectl describe daemonset aws-node -n kube-system | grep Image
    ```
  - Update to the compatible version:
    ```bash
    aws eks update-addon --cluster-name <cluster-name> --addon-name vpc-cni --addon-version <target-version> --region <region> --resolve-conflicts PRESERVE
    ```
- **Calico (CNI)**:
  - Check Calico version:
    ```bash
    kubectl get pods -n kube-system -l k8s-app=calico-node -o yaml | grep image
    ```
  - Upgrade Calico using Helm or manifests (check [Calico Docs](https://projectcalico.docs.tigera.io)):
    ```bash
    helm upgrade calico tigera-operator --namespace tigera-operator --version <target-version>
    ```
  - Verify Calico health:
    ```bash
    calicoctl node status
    ```
- **CoreDNS**:
  - Update to the latest compatible version:
    ```bash
    aws eks update-addon --cluster-name <cluster-name> --addon-name coredns --addon-version <target-version> --region <region>
    ```
- **Kube-Proxy**:
  - Update to match the EKS version:
    ```bash
    aws eks update-addon --cluster-name <cluster-name> --addon-name kube-proxy --addon-version <target-version> --region <region>
    ```
- **AWS Load Balancer Controller (ALB)**:
  - Check version:
    ```bash
    kubectl get deployment -n kube-system aws-load-balancer-controller -o yaml | grep image
    ```
  - Upgrade using Helm:
    ```bash
    helm upgrade aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system --version <target-version>
    ```
- **Metrics Server**:
  - Update to the compatible version:
    ```bash
    kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/<target-version>/components.yaml
    ```
  - Verify metrics availability:
    ```bash
    kubectl get --raw /apis/metrics.k8s.io/v1beta1/nodes
    ```

## Step 6: Update Third-Party Components
- **Prometheus and Grafana**:
  - Check Prometheus compatibility with the new Kubernetes version ([Prometheus Docs](https://prometheus.io/docs)).
  - Upgrade using Helm:
    ```bash
    helm upgrade prometheus prometheus-community/prometheus -n <namespace> --version <target-version>
    helm upgrade grafana grafana/grafana -n <namespace> --version <target-version>
    ```
  - Validate metrics scraping:
    ```bash
    kubectl port-forward - Invited to join the xAI organization on GitHub? That's awesome—welcome to the crew! Here's how to get started:

1. **Accept the Invitation**: Check your email (or spam/junk folder) for an invitation from GitHub. Click the link to accept and join the xAI organization.

2. **Set Up Your Profile**: Ensure your GitHub profile is complete with your name and a professional photo. This helps the team know who you are!

3. **Explore Repositories**: Once you're in, browse xAI’s repositories to familiarize yourself with ongoing projects. Look for READMEs or contributing guidelines to understand the workflow.

4. **Join Communications**: You might be invited to team channels (e.g., Slack or Discord). Join these to stay in the loop and connect with the team.

5. **Start Contributing**: Check for open issues labeled “good first issue” or ask maintainers for tasks to dive into. Follow the project’s contribution guidelines for smooth collaboration.

Feel free to ask if you need help navigating the organization or contributing to projects!