
# **CA-Certificate Setup in Kubernetes**

---

## **Introduction**

Managing certificates in Kubernetes (K8s) is streamlined with tools like **cert-manager**, which automates the provisioning, renewal, and management of TLS certificates. Below is a comprehensive guide on how to manage certificates in Kubernetes, integrate with **AWS Certificate Manager (ACM)** or **AWS Private Certificate Authority (PCA)**, and configure user permissions for secure certificate management.

---

## **1. Managing Certificates in Kubernetes with cert-manager**

**cert-manager** is a widely adopted Kubernetes add-on that automates the issuance and renewal of TLS certificates. It integrates with various certificate authorities (CAs), including public CAs like Let’s Encrypt and private CAs like AWS PCA.

### **Steps to Set Up cert-manager**

1. **Install cert-manager**:
   - Use Helm to install cert-manager in your Kubernetes cluster:
     ```bash
     helm repo add jetstack https://charts.jetstack.io
     helm repo update
     helm install cert-manager jetstack/cert-manager \
       --namespace cert-manager \
       --create-namespace \
       --set installCRDs=true
     ```
   - Verify the installation:
     ```bash
     kubectl get pods -n cert-manager
     ```

2. **Configure a ClusterIssuer or Issuer**:
   - A `ClusterIssuer` is a Kubernetes resource that defines how certificates are issued. For example, to use Let’s Encrypt:
     ```yaml
     apiVersion: cert-manager.io/v1
     kind: ClusterIssuer
     metadata:
       name: letsencrypt-staging
     spec:
       acme:
         server: https://acme-staging-v02.api.letsencrypt.org/directory
         email: your-email@example.com
         privateKeySecretRef:
           name: letsencrypt-staging
         solvers:
         - http01:
             ingress:
               class: nginx
     ```
     Apply it:
     ```bash
     kubectl apply -f clusterissuer-lets-encrypt-staging.yaml
     ```

3. **Request a Certificate**:
   - Create a `Certificate` resource to request a certificate:
     ```yaml
     apiVersion: cert-manager.io/v1
     kind: Certificate
     metadata:
       name: example-cert
       namespace: default
     spec:
       secretName: example-tls
       dnsNames:
       - example.com
       issuerRef:
         name: letsencrypt-staging
         kind: ClusterIssuer
     ```
     Apply it:
     ```bash
     kubectl apply -f certificate.yaml
     ```
   - cert-manager will store the certificate and private key in a Kubernetes Secret named `example-tls`.

4. **Use the Certificate**:
   - Mount the Secret into a pod or use it with an Ingress resource:
     ```yaml
     apiVersion: networking.k8s.io/v1
     kind: Ingress
     metadata:
       name: example-ingress
       annotations:
         cert-manager.io/cluster-issuer: letsencrypt-staging
     spec:
       tls:
       - hosts:
         - example.com
         secretName: example-tls
       rules:
       - host: example.com
         http:
           paths:
           - path: /
             pathType: Prefix
             backend:
               service:
                 name: example-service
                 port:
                   number: 80
     ```

5. **Automate Renewal**:
   - cert-manager automatically renews certificates before they expire, typically 30 days prior, based on the CA’s configuration.



---


## **2. Integrating cert-manager with AWS Certificate Manager (ACM) or AWS Private CA**

AWS Certificate Manager (ACM) manages public and private certificates, but it’s primarily designed for AWS services like Elastic Load Balancers (ELBs) and CloudFront. For Kubernetes, **AWS Private CA** (ACM PCA) is more relevant, as it integrates with cert-manager to issue certificates for Kubernetes workloads.

### **Integration with AWS Private CA**

1. **Set Up AWS Private CA**:
   - Create a Private CA in the AWS Management Console or via the AWS CLI:
     ```bash
     aws acm-pca create-certificate-authority \
       --certificate-authority-configuration "KeyAlgorithm=RSA_2048,SigningAlgorithm=SHA256WITHRSA,Subject={CommonName=my-private-ca}" \
       --certificate-authority-type "ROOT" \
       --region us-east-1
     ```
   - Note the CA’s ARN for later use.

2. **Install the AWS Private CA Issuer Plugin**:
   - Add the AWS PCA Issuer Helm chart:
     ```bash
     helm repo add awspca https://cert-manager.github.io/aws-privateca-issuer
     helm install awspcaissuer awspca/aws-privateca-issuer --namespace cert-manager
     ```

3. **Configure IAM Permissions**:
   - Create an IAM role for the cert-manager service account using **IAM Roles for Service Accounts (IRSA)** or EKS Pod Identities:
     ```bash
     eksctl create iamserviceaccount \
       --cluster <cluster-name> \
       --namespace cert-manager \
       --name awspcaissuer \
       --attach-policy-arn arn:aws:iam::aws:policy/AWSPrivateCAFullAccess \
       --approve
     ```
   - For production, scope the IAM policy to the specific CA ARN:
     ```json
     {
       "Version": "2012-10-17",
       "Statement": [
         {
           "Effect": "Allow",
           "Action": [
             "acm-pca:IssueCertificate",
             "acm-pca:GetCertificate",
             "acm-pca:DescribeCertificateAuthority"
           ],
           "Resource": "arn:aws:acm-pca:<region>:<account-id>:certificate-authority/<ca-id>"
         }
       ]
     }
     ```

4. **Create an AWSPCAIssuer**:
   - Define an `AWSPCAIssuer` resource to connect cert-manager to AWS PCA:
     ```yaml
     apiVersion: awspca.cert-manager.io/v1beta1
     kind: AWSPCAIssuer
     metadata:
       name: awspca-issuer
       namespace: cert-manager
     spec:
       arn: arn:aws:acm-pca:<region>:<account-id>:certificate-authority/<ca-id>
       region: us-east-1
     ```
   - Apply it:
     ```bash
     kubectl apply -f awspca-issuer.yaml
     ```

5. **Request a Certificate from AWS PCA**:
   - Create a `Certificate` resource referencing the `AWSPCAIssuer`:
     ```yaml
     apiVersion: cert-manager.io/v1
     kind: Certificate
     metadata:
       name: example-cert
       namespace: default
     spec:
       secretName: example-tls
       dnsNames:
       - example.com
       issuerRef:
         name: awspca-issuer
         kind: AWSPCAIssuer
         group: awspca.cert-manager.io
     ```
   - Apply it:
     ```bash
     kubectl apply -f certificate.yaml
     ```

6. **Use the Certificate**:
   - The certificate is stored in a Kubernetes Secret (`example-tls`) and can be used in Ingress resources or mounted to pods, as described earlier.

### **Notes on AWS ACM Integration**
- **Public ACM Certificates**: AWS ACM public certificates are not directly supported by cert-manager because ACM manages private keys internally and doesn’t allow exporting them. They are primarily for AWS services like ALB, CloudFront, or API Gateway.
- **Workaround**: Use AWS PCA for Kubernetes workloads, as it allows cert-manager to manage certificates dynamically. Alternatively, store ACM certificates in **AWS Secrets Manager** and sync them to Kubernetes Secrets using a custom controller or the **External Secrets Operator**.

---


## **3. Configuring User Permissions for Certificate Management**

To securely manage certificates in Kubernetes, you need to configure **Kubernetes RBAC** (Role-Based Access Control) and **AWS IAM** permissions.

### **Kubernetes RBAC for cert-manager**

1. **Create a ServiceAccount for cert-manager**:
   - cert-manager requires a ServiceAccount to interact with the Kubernetes API:
     ```yaml
     apiVersion: v1
     kind: ServiceAccount
     metadata:
       name: cert-manager
       namespace: cert-manager
     ```

2. **Define a ClusterRole**:
   - Grant permissions to manage certificates, secrets, and other resources:
     ```yaml
     apiVersion: rbac.authorization.k8s.io/v1
     kind: ClusterRole
     metadata:
       name: cert-manager-role
     rules:
     - apiGroups: ["cert-manager.io"]
       resources: ["certificates", "issuers", "clusterissuers"]
       verbs: ["create", "update", "delete", "get", "list", "watch"]
     - apiGroups: [""]
       resources: ["secrets", "configmaps"]
       verbs: ["create", "update", "delete", "get", "list", "watch"]
     - apiGroups: ["networking.k8s.io"]
       resources: ["ingresses"]
       verbs: ["get", "list", "watch"]
     ```

3. **Bind the ClusterRole to the ServiceAccount**:
   - Create a `ClusterRoleBinding`:
     ```yaml
     apiVersion: rbac.authorization.k8s.io/v1
     kind: ClusterRoleBinding
     metadata:
       name: cert-manager-rolebinding
     subjects:
     - kind: ServiceAccount
       name: cert-manager
       namespace: cert-manager
     roleRef:
       kind: ClusterRole
       name: cert-manager-role
       apiGroup: rbac.authorization.k8s.io
     ```
   - Apply it:
     ```bash
     kubectl apply -f clusterrolebinding.yaml
     ```

4. **User Permissions for Certificate Approval**:
   - To approve or deny `CertificateSigningRequests` (CSRs), create a `ClusterRole` for administrators:
     ```yaml
     apiVersion: rbac.authorization.k8s.io/v1
     kind: ClusterRole
     metadata:
       name: csr-approver_quad
     rules:
     - apiGroups: ["certificates.k8s.io"]
       resources: ["certificatesigningrequests"]
       verbs: ["get", "list", "watch", "update"]
     - apiGroups: ["certificates.k8s.io"]
       resources: ["certificatesigningrequests/approval"]
       verbs: ["create", "update"]
     ```
   - Bind this role to specific users or groups:
     ```yaml
     apiVersion: rbac.authorization.k8s.io/v1
     kind: ClusterRoleBinding
     metadata:
       name: csr-approver
     subjects:
     - kind: User
       name: "user@example.com"
       apiGroup: rbac.authorization.k8s.io
     roleRef:
       kind: ClusterRole
       name: csr-approver
       apiGroup: rbac.authorization.k8s.io
     ```

### **AWS IAM Permissions for AWS PCA**

- Ensure the IAM role used by cert-manager or the AWS PCA Issuer has the necessary permissions:
  ```json
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "acm-pca:IssueCertificate",
          "acm-pca:GetCertificate",
          "acm-pca:DescribeCertificateAuthority"
        ],
        "Resource": "arn:aws:acm-pca:<region>:<account-id>:certificate-authority/<ca-id>"
      }
    ]
  }
  ```
- Use IRSA to associate this IAM role with the cert-manager ServiceAccount, as shown earlier.

### **Best Practices for Permissions**
- **Least Privilege**: Limit RBAC and IAM permissions to only what is necessary.
- **Namespace Scoping**: Use `Role` and `RoleBinding` instead of `ClusterRole` for namespace-specific access.
- **Secret Access**: Restrict access to Secrets containing certificates using RBAC:
  ```yaml
  apiVersion: rbac.authorization.k8s.io/v1
  kind: Role
  metadata:
    namespace: default
    name: secret-reader
  rules:
  - apiGroups: [""]
    resources: ["secrets"]
    verbs: ["get", "list"]
    resourceNames: ["example-tls"]
  ```
- **Audit Access**: Regularly audit RBAC and IAM policies to ensure compliance.

---


## **4. Additional Considerations**

- **Certificate Storage**: Certificates are stored in Kubernetes Secrets. For enhanced security, use **AWS Secrets Manager** to store sensitive certificate data and sync it to Kubernetes Secrets using tools like the External Secrets Operator.
- **Monitoring and Logging**: Integrate cert-manager with monitoring tools (e.g., Prometheus) to track certificate issuance and renewal events.
- **External CA Integration**: If using an external PKI, integrate it with AWS PCA and cert-manager to maintain your existing CA while leveraging Kubernetes automation.
- **Security**: Use envelope encryption with AWS KMS for Kubernetes Secrets and ensure private keys are never exposed.

---

## **References**
- Kubernetes certificate management:[](https://kubernetes.io/docs/tasks/tls/managing-tls-in-a-cluster/)
- AWS Private CA integration:[](https://aws.amazon.com/blogs/security/tls-enabled-kubernetes-clusters-with-acm-private-ca-and-amazon-eks-2/)[](https://docs.aws.amazon.com/privateca/latest/userguide/PcaKubernetes.html)[](https://github.com/cert-manager/aws-privateca-issuer)
- cert-manager documentation:[](https://github.com/cert-manager/cert-manager)
- AWS IAM and RBAC:[](https://dev.to/m_nitinkumar_12140be2dce/storing-certificate-files-in-aws-secrets-manager-and-accessing-them-in-kubernetes-secrets-53ca)[](https://aws.amazon.com/blogs/containers/securing-kubernetes-applications-with-aws-app-mesh-and-cert-manager/)

