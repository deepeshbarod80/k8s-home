
# Kubernetes Secrets Management

Managing Secrets in Kubernetes (K8s) is critical for securely handling sensitive data like API keys, passwords, and certificates. Kubernetes provides native Secret objects, but integrating with external secrets management systems like **AWS Secrets Manager (SM)** and **AWS Key Management Service (KMS)** enhances security and scalability. Below is a comprehensive guide on managing Secrets in Kubernetes, integrating with AWS SM and KMS, and configuring user permissions using Kubernetes RBAC.

---

## 1. Managing Secrets in Kubernetes

Kubernetes Secrets store sensitive data in base64-encoded format and can be used by pods, deployments, or other resources. While native Secrets are simple, they lack advanced features like rotation and encryption at rest, which AWS SM and KMS address.

### Creating and Managing Kubernetes Secrets

1. **Create a Secret**:
   - Manually create a Secret using a YAML manifest:
     ```yaml
     apiVersion: v1
     kind: Secret
     metadata:
       name: my-secret
       namespace: default
     type: Opaque
     data:
       username: YWRtaW4= # base64-encoded "admin"
       password: cGFzc3dvcmQ= # base64-encoded "password"
     ```
     Apply it:
     ```bash
     kubectl apply -f secret.yaml
     ```

2. **Use Secrets in Pods**:
   - Mount a Secret as a volume or environment variable:
     ```yaml
     apiVersion: v1
     kind: Pod
     metadata:
       name: my-pod
     spec:
       containers:
       - name: my-container
         image: nginx
         env:
         - name: USERNAME
           valueFrom:
             secretKeyRef:
               name: my-secret
               key: username
         volumeMounts:
         - name: secret-volume
           mountPath: /etc/secret
           readOnly: true
       volumes:
       - name: secret-volume
         secret:
           secretName: my-secret
     ```

3. **Best Practices for Native Secrets**:
   - **Avoid Plaintext**: Never store sensitive data in ConfigMaps or unencoded in Secrets.
   - **Limit Access**: Restrict access to Secrets using RBAC (covered later).
   - **Encryption at Rest**: Enable Kubernetes Secrets encryption using a KMS provider (like AWS KMS).

---

## 2. Integrating with AWS Secrets Manager and AWS KMS

AWS Secrets Manager (SM) securely stores, manages, and rotates secrets, while AWS KMS provides cryptographic key management for encrypting secrets. Integrating these with Kubernetes requires tools like the **AWS Secrets and Configuration Provider (ASCP)** or the **External Secrets Operator**.

### Integration with AWS Secrets Manager

1. **Set Up AWS Secrets Manager**:
   - Create a secret in AWS SM via the AWS Console or CLI:
     ```bash
     aws secretsmanager create-secret \
       --name my-k8s-secret \
       --secret-string '{"username":"admin","password":"securepassword"}' \
       --region us-east-1
     ```
   - Note the secret’s ARN for later use.

2. **Install the External Secrets Operator**:
   - The External Secrets Operator syncs secrets from AWS SM to Kubernetes Secrets.
   - Install using Helm:
     ```bash
     helm repo add external-secrets https://charts.external-secrets.io
     helm install external-secrets external-secrets/external-secrets \
       --namespace external-secrets \
       --create-namespace
     ```

3. **Configure IAM Permissions**:
   - Create an IAM role for the External Secrets Operator using **IAM Roles for Service Accounts (IRSA)**:
     ```bash
     eksctl create iamserviceaccount \
       --cluster <cluster-name> \
       --namespace external-secrets \
       --name external-secrets-sa \
       --attach-policy-arn arn:aws:iam::aws:policy/AWSSecretsManagerReadWrite \
       --approve
     ```
   - For least privilege, use a custom IAM policy:
     ```json
     {
       "Version": "2012-10-17",
       "Statement": [
         {
           "Effect": "Allow",
           "Action": [
             "secretsmanager:GetSecretValue",
             "secretsmanager:DescribeSecret"
           ],
           "Resource": "arn:aws:secretsmanager:<region>:<account-id>:secret:my-k8s-secret-*"
         }
       ]
     }
     ```

4. **Create an ExternalSecret Resource**:
   - Define an `ExternalSecret` to sync the AWS SM secret to a Kubernetes Secret:
     ```yaml
     apiVersion: external-secrets.io/v1beta1
     kind: SecretStore
     metadata:
       name: aws-secret-store
       namespace: default
     spec:
       provider:
         aws:
           service: SecretsManager
           region: us-east-1
           auth:
             jwt:
               serviceAccountRef:
                 name: external-secrets-sa
     ---
     apiVersion: external-secrets.io/v1beta1
     kind: ExternalSecret
     metadata:
       name: my-external-secret
       namespace: default
     spec:
       refreshInterval: 1h
       secretStoreRef:
         name: aws-secret-store
         kind: SecretStore
       target:
         name: my-secret
         creationPolicy: Owner
       data:
       - secretKey: username
         remoteRef:
           key: my-k8s-secret
           property: username
       - secretKey: password
         remoteRef:
           key: my-k8s-secret
           property: password
     ```
     Apply it:
     ```bash
     kubectl apply -f external-secret.yaml
     ```
   - This creates a Kubernetes Secret named `my-secret` with the data from AWS SM.

### Integration with AWS KMS for Encryption

1. **Enable Encryption for Kubernetes Secrets**:
   - Kubernetes supports encrypting Secrets at rest using a KMS provider.
   - Configure the Kubernetes API server to use AWS KMS:
     - Create a KMS key in AWS:
       ```bash
       aws kms create-key --region us-east-1
       ```
       Note the KMS key ARN.
     - Update the Kubernetes API server configuration (e.g., in an EKS cluster) by modifying the `--encryption-provider-config` flag. Create an `EncryptionConfiguration`:
       ```yaml
       apiVersion: apiserver.config.k8s.io/v1
       kind: EncryptionConfiguration
       resources:
       - resources:
         - secrets
         providers:
         - kms:
             name: aws-kms
             endpoint: aws:kms:<region>:<account-id>:key/<key-id>
             cachesize: 1000
             region: us-east-1
         - identity: {}
       ```
     - Apply this configuration to the API server (requires cluster admin access and may involve updating EKS configurations).
     - Restart the API server to apply encryption.

2. **Encrypt Secrets in AWS Secrets Manager with KMS**:
   - When creating secrets in AWS SM, associate them with a KMS key for encryption:
     ```bash
     aws secretsmanager create-secret \
       --name my-k8s-secret \
       --secret-string '{"username":"admin","password":"securepassword"}' \
       --kms-key-id arn:aws:kms:<region>:<account-id>:key/<key-id> \
       --region us-east-1
     ```

3. **IAM Permissions for KMS**:
   - Ensure the IAM role used by the External Secrets Operator or Kubernetes has KMS permissions:
     ```json
     {
       "Version": "2012-10-17",
       "Statement": [
         {
           "Effect": "Allow",
           "Action": [
             "kms:Encrypt",
             "kms:Decrypt",
             "kms:GenerateDataKey"
           ],
           "Resource": "arn:aws:kms:<region>:<account-id>:key/<key-id>"
         }
       ]
     }
     ```

---

## 3. Configuring User Permissions in Kubernetes

Kubernetes uses **Role-Based Access Control (RBAC)** to manage permissions for Secrets. You can grant users or service accounts access to create, read, update, or delete Secrets.

### RBAC for Secrets Management

1. **Create a ServiceAccount for Secrets Access**:
   - For applications or automation tools:
     ```yaml
     apiVersion: v1
     kind: ServiceAccount
     metadata:
       name: secret-manager
       namespace: default
     ```

2. **Define a Role for Secrets**:
   - Create a `Role` to grant specific permissions in a namespace:
     ```yaml
     apiVersion: rbac.authorization.k8s.io/v1
     kind: Role
     metadata:
       namespace: default
       name: secret-reader
     rules:
     - apiGroups: [""]
       resources: ["secrets"]
       verbs: ["get", "list", "watch"]
       resourceNames: ["my-secret"]
     - apiGroups: [""]
       resources: ["secrets"]
       verbs: ["create", "update", "delete"]
     ```
     - This allows reading specific Secrets (`my-secret`) and creating/updating/deleting any Secret in the namespace.

3. **Bind the Role to Users or ServiceAccounts**:
   - Create a `RoleBinding` for a user or ServiceAccount:
     ```yaml
     apiVersion: rbac.authorization.k8s.io/v1
     kind: RoleBinding
     metadata:
       name: secret-reader-binding
       namespace: default
     subjects:
     - kind: User
       name: "user@example.com"
       apiGroup: rbac.authorization.k8s.io
     - kind: ServiceAccount
       name: secret-manager
       namespace: default
     roleRef:
       kind: Role
       name: secret-reader
       apiGroup: rbac.authorization.k8s.io
     ```
     Apply it:
     ```bash
     kubectl apply -f rolebinding.yaml
     ```

4. **Cluster-Wide Permissions (Optional)**:
   - For cluster-wide access, use a `ClusterRole` and `ClusterRoleBinding`:
     ```yaml
     apiVersion: rbac.authorization.k8s.io/v1
     kind: ClusterRole
     metadata:
       name: secret-admin
     rules:
     - apiGroups: [""]
       resources: ["secrets"]
       verbs: ["get", "list", "watch", "create", "update", "delete"]
     ---
     apiVersion: rbac.authorization.k8s.io/v1
     kind: ClusterRoleBinding
     metadata:
       name: secret-admin-binding
     subjects:
     - kind: User
       name: "admin@example.com"
       apiGroup: rbac.authorization.k8s.io
     roleRef:
       kind: ClusterRole
       name: secret-admin
       apiGroup: rbac.authorization.k8s.io
     ```

### Best Practices for Permissions
- **Least Privilege**: Grant only the necessary permissions (e.g., read-only for applications, full access for admins).
- **Namespace Scoping**: Prefer `Role` and `RoleBinding` for namespace-specific access over `ClusterRole`.
- **Audit Access**: Use Kubernetes audit logs and tools like **Prometheus** or **AWS CloudTrail** to monitor Secret access.
- **ServiceAccount Tokens**: Use IRSA or EKS Pod Identities for secure AWS API access instead of static credentials.

---

## 4. Additional Considerations

- **Secret Rotation**: AWS SM supports automatic secret rotation with Lambda functions. Configure rotation policies in SM and resync with Kubernetes using External Secrets Operator.
- **Backup and Recovery**: Store critical secrets in AWS SM with versioning enabled for recovery. Regularly back up Kubernetes Secrets using tools like **Velero**.
- **Security**: Use AWS KMS for envelope encryption of Secrets in Kubernetes and AWS SM. Restrict KMS key access to authorized roles only.
- **Monitoring**: Monitor Secret usage and access with Kubernetes audit logs and AWS CloudTrail for SM and KMS.

---

## References
- Kubernetes Secrets: https://kubernetes.io/docs/concepts/configuration/secret/
- External Secrets Operator: https://external-secrets.io/
- AWS Secrets Manager: https://docs.aws.amazon.com/secretsmanager/
- AWS KMS: https://docs.aws.amazon.com/kms/
- Kubernetes RBAC: https://kubernetes.io/docs/reference/access-authn-authz/rbac/


