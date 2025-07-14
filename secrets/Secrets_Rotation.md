
# Kubernetes Secrets Management
* Secrets Rotation
* Backup and Recovery
* Security
* Monitoring

Below is a detailed explanation of **Secret Rotation**, **Backup and Recovery**, **Security**, and **Monitoring** for managing Secrets in Kubernetes (K8s) with integration to **AWS Secrets Manager (SM)** and **AWS Key Management Service (KMS)**. I’ll include step-by-step instructions for real-world scenarios, practical examples, and operational considerations to ensure clarity and applicability.

---

## **1. Secret Rotation**

### Overview
AWS Secrets Manager (SM) supports automatic secret rotation to periodically update sensitive data (e.g., database credentials, API keys) to enhance security. Rotation is typically implemented using AWS Lambda functions, which update the secret in SM. In a Kubernetes environment, the **External Secrets Operator** ensures that rotated secrets are synced to Kubernetes Secrets for use in your workloads.

### Detailed Steps for Secret Rotation

1. **Set Up a Secret in AWS Secrets Manager**:
   - Create a secret in AWS SM for a resource, such as database credentials:
     ```bash
     aws secretsmanager create-secret \
       --name my-k8s-secret \
       --secret-string '{"username":"admin","password":"initialpassword"}' \
       --region us-east-1
     ```
   - Note the secret’s ARN: `arn:aws:secretsmanager:us-east-1:<account-id>:secret:my-k8s-secret-XXXXXX`.

2. **Create a Lambda Function for Rotation**:
   - AWS SM supports rotation for certain managed services (e.g., RDS, Redshift) or custom resources via Lambda.
   - Example: Create a Lambda function to rotate a custom secret (e.g., a password):
     - Go to the AWS Lambda Console and create a function (e.g., `rotate-my-k8s-secret`).
     - Use the AWS-provided template for Secrets Manager rotation or write a custom function in Python:
       ```python
       import json
       import boto3
       import secrets
       import string

       def lambda_handler(event, context):
           sm_client = boto3.client('secretsmanager')
           secret_id = event['SecretId']
           client_request_token = event['ClientRequestToken']
           step = event['Step']

           if step == "createSecret":
               # Generate a new random password
               new_password = ''.join(secrets.choice(string.ascii_letters + string.digits) for _ in range(16))
               secret = sm_client.get_secret_value(SecretId=secret_id)
               secret_dict = json.loads(secret['SecretString'])
               secret_dict['password'] = new_password
               sm_client.put_secret_value(
                   SecretId=secret_id,
                   ClientRequestToken=client_request_token,
                   SecretString=json.dumps(secret_dict),
                   VersionStages=['AWSPENDING']
               )
           elif step == "setSecret":
               # Update the external resource (e.g., a database) with the new password
               # Add logic to update your resource here
               pass
           elif step == "testSecret":
               # Test the new secret (e.g., verify database connectivity)
               pass
           elif step == "finishSecret":
               # Finalize rotation by promoting AWSPENDING to AWSCURRENT
               sm_client.update_secret_version_stage(
                   SecretId=secret_id,
                   VersionStage='AWSCURRENT',
                   MoveToVersionId=client_request_token,
                   RemoveFromVersionId=sm_client.get_secret_value(SecretId=secret_id)['VersionId']
               )
       ```
   - Attach an IAM role to the Lambda function with permissions:
     ```json
     {
       "Version": "2012-10-17",
       "Statement": [
         {
           "Effect": "Allow",
           "Action": [
             "secretsmanager:GetSecretValue",
             "secretsmanager:PutSecretValue",
             "secretsmanager:UpdateSecretVersionStage"
           ],
           "Resource": "arn:aws:secretsmanager:us-east-1:<account-id>:secret:my-k8s-secret-*"
         }
       ]
     }
     ```

3. **Configure Rotation in AWS Secrets Manager**:
   - Enable rotation for the secret:
     ```bash
     aws secretsmanager rotate-secret \
       --secret-id my-k8s-secret \
       --rotation-lambda-arn arn:aws:lambda:us-east-1:<account-id>:function:rotate-my-k8s-secret \
       --rotation-rules AutomaticallyAfterDays=30
     ```
   - Alternatively, configure via the AWS Console:
     - Navigate to Secrets Manager > `my-k8s-secret` > Rotation.
     - Select the Lambda function and set a rotation interval (e.g., 30 days).

4. **Sync Rotated Secrets to Kubernetes**:
   - Ensure the **External Secrets Operator** is installed (as described in the previous response).
   - Create an `ExternalSecret` to sync the secret:
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
   - The `refreshInterval` (e.g., `1h`) ensures the Kubernetes Secret is updated after rotation.

5. **Real-World Scenario**:
   - **Scenario**: A Kubernetes application uses a PostgreSQL database hosted on AWS RDS. The database credentials are stored in AWS SM and synced to a Kubernetes Secret.
   - **Operation**:
     - The Lambda function rotates the RDS password every 30 days, updating both the RDS instance and the secret in AWS SM.
     - The External Secrets Operator detects the change and updates the Kubernetes Secret `my-secret`.
     - The application pod, which mounts `my-secret`, must be restarted to pick up the new credentials. Use a sidecar or a controller like **Reloader** to automatically restart pods when Secrets change:
       ```bash
       helm repo add stakater https://stakater.github.io/stakater-charts
       helm install reloader stakater/reloader --namespace default
       ```
     - Add an annotation to the deployment:
       ```yaml
       metadata:
         annotations:
           secret.reloader.stakater.com/reload: "my-secret"
       ```

6. **Operational Considerations**:
   - **Rotation Frequency**: Balance security and operational overhead. Frequent rotation (e.g., daily) may increase complexity.
   - **Testing**: Test the Lambda function thoroughly to ensure it updates both the secret and the external resource (e.g., database).
   - **Error Handling**: Monitor Lambda execution logs in CloudWatch for rotation failures.
   - **Downtime**: Ensure applications can handle credential changes gracefully (e.g., connection pooling with retry logic).

---

## **2. Backup and Recovery**

### Overview
Backing up Kubernetes Secrets and storing them in AWS SM with versioning enabled ensures recoverability in case of data loss or cluster failure. Tools like **Velero** can back up Kubernetes resources, while AWS SM versioning allows restoring previous secret versions.

### Detailed Steps for Backup and Recovery

1. **Enable Versioning in AWS Secrets Manager**:
   - AWS SM automatically versions secrets. Each update (manual or via rotation) creates a new version with a unique `VersionId`.
   - To view versions:
     ```bash
     aws secretsmanager list-secret-version-ids --secret-id my-k8s-secret --region us-east-1
     ```
   - To restore a previous version:
     ```bash
     aws secretsmanager get-secret-value \
       --secret-id my-k8s-secret \
       --version-id <version-id> \
       --region us-east-1
     ```
   - Update the `AWSCURRENT` stage to restore the version:
     ```bash
     aws secretsmanager update-secret-version-stage \
       --secret-id my-k8s-secret \
       --version-stage AWSCURRENT \
       --move-to-version-id <version-id> \
       --region us-east-1
     ```

2. **Install Velero for Kubernetes Backups**:
   - Install Velero with AWS support:
     ```bash
     helm repo add vmware-tanzu https://vmware-tanzu.github.io/helm-charts
     helm install velero vmware-tanzu/velero \
       --namespace velero \
       --create-namespace \
       --set configuration.provider=aws \
       --set configuration.backupStorageLocation.bucket=<s3-bucket-name> \
       --set configuration.backupStorageLocation.config.region=us-east-1 \
       --set credentials.secretContents.cloud="AWS_ACCESS_KEY_ID=<key>\nAWS_SECRET_ACCESS_KEY=<secret>"
     ```
   - Create an S3 bucket for backups:
     ```bash
     aws s3 mb s3://<s3-bucket-name> --region us-east-1
     ```

3. **Back Up Kubernetes Secrets**:
   - Create a backup of all Secrets in a namespace:
     ```bash
     velero backup create my-backup \
       --include-namespaces default \
       --include-resources secrets
     ```
   - Schedule regular backups (e.g., daily):
     ```bash
     velero schedule create daily-secrets-backup \
       --schedule "0 0 * * *" \
       --include-namespaces default \
       --include-resources secrets
     ```

4. **Restore Secrets**:
   - Restore a specific backup:
     ```bash
     velero restore create --from-backup my-backup
     ```
   - Verify the restored Secret:
     ```bash
     kubectl get secret my-secret -n default -o yaml
     ```

5. **Real-World Scenario**:
   - **Scenario**: A Kubernetes cluster is accidentally deleted, and Secrets need to be restored.
   - **Operation**:
     - Restore Secrets from Velero backups stored in S3.
     - If a specific secret version is needed (e.g., due to a failed rotation), retrieve it from AWS SM using the version ID.
     - Sync the restored AWS SM secret to Kubernetes using the External Secrets Operator.
   - **Steps**:
     - Restore the Velero backup to recreate the Kubernetes Secret.
     - If the Secret is missing or outdated, update AWS SM to the desired version and trigger a resync:
       ```bash
       kubectl delete externalsecret my-external-secret -n default
       kubectl apply -f external-secret.yaml
       ```

6. **Operational Considerations**:
   - **Retention**: Configure backup retention policies in Velero (e.g., expire after 90 days).
   - **Versioning Limits**: AWS SM retains all versions, but clean up old versions to manage costs:
     ```bash
     aws secretsmanager delete-secret --secret-id my-k8s-secret --force --region us-east-1
     ```
   - **Testing**: Periodically test restores to ensure backups are usable.
   - **Cross-Region**: Store backups in a different AWS region for disaster recovery.

---

## **3. Security with KMS**

### Overview
Using AWS KMS for envelope encryption ensures that Secrets in both Kubernetes and AWS SM are encrypted with a secure key management system. Restricting KMS key access to authorized roles minimizes the risk of unauthorized access.

### Detailed Steps for Security

1. **Enable KMS Encryption for Kubernetes Secrets**:
   - Create a KMS key:
     ```bash
     aws kms create-key --region us-east-1 --description "K8s Secrets Encryption"
     ```
     Note the KMS key ARN: `arn:aws:kms:us-east-1:<account-id>:key/<key-id>`.
   - Configure the Kubernetes API server for KMS encryption:
     - Create an `EncryptionConfiguration`:
       ```yaml
       apiVersion: apiserver.config.k8s.io/v1
       kind: EncryptionConfiguration
       resources:
       - resources:
         - secrets
         providers:
         - kms:
             name: aws-kms
             endpoint: aws:kms:us-east-1:<account-id>:key/<key-id>
             cachesize: 1000
             region: us-east-1
         - identity: {}
       ```
     - For EKS, update the cluster’s encryption provider:
       ```bash
       aws eks update-cluster-config \
         --region us-east-1 \
         --name <cluster-name> \
         --resources-encryption-config "{\"provider\": \"aws\", \"resources\": [\"secrets\"], \"key_id\": \"<key-id>\"}"
       ```
     - Restart the API server (handled automatically by EKS).
   - Encrypt existing Secrets:
     ```bash
     kubectl get secrets --all-namespaces -o json | kubectl replace -f -
     ```

2. **Encrypt AWS SM Secrets with KMS**:
   - Create or update a secret with a KMS key:
     ```bash
     aws secretsmanager create-secret \
       --name my-k8s-secret \
       --secret-string '{"username":"admin","password":"securepassword"}' \
       --kms-key-id arn:aws:kms:us-east-1:<account-id>:key/<key-id> \
       --region us-east-1
     ```

3. **Restrict KMS Key Access**:
   - Create an IAM policy for KMS access:
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
           "Resource": "arn:aws:kms:us-east-1:<account-id>:key/<key-id>"
         }
       ]
     }
     ```
   - Attach this policy to the IAM roles used by:
     - External Secrets Operator ServiceAccount (via IRSA).
     - Kubernetes API server (for EKS).
     - Lambda function for secret rotation.
   - Update the KMS key policy to allow only specific roles:
     ```json
     {
       "Version": "2012-10-17",
       "Statement": [
         {
           "Effect": "Allow",
           "Principal": {
             "AWS": [
               "arn:aws:iam::<account-id>:role/external-secrets-sa",
               "arn:aws:iam::<account-id>:role/eks-api-server-role",
               "arn:aws:iam::<account-id>:role/rotate-my-k8s-secret"
             ]
           },
           "Action": [
             "kms:Encrypt",
             "kms:Decrypt",
             "kms:GenerateDataKey"
           ],
           "Resource": "*"
         }
       ]
     }
     ```

4. **Real-World Scenario**:
   - **Scenario**: A Kubernetes application uses encrypted Secrets for a microservices architecture.
   - **Operation**:
     - Secrets are encrypted with KMS in both Kubernetes (via API server) and AWS SM.
     - Only the External Secrets Operator and specific admin roles can decrypt Secrets.
     - Developers are granted read-only RBAC access to Secrets but cannot access the KMS key directly.
   - **Steps**:
     - Deploy the `EncryptionConfiguration` to enable KMS encryption in Kubernetes.
     - Update AWS SM secrets to use the same KMS key.
     - Restrict KMS key access to the External Secrets Operator and rotation Lambda function.

5. **Operational Considerations**:
   - **Key Rotation**: Enable automatic KMS key rotation to maintain security:
     ```bash
     aws kms enable-key-rotation --key-id <key-id> --region us-east-1
     ```
   - **Access Control**: Regularly audit KMS key policies and IAM roles.
   - **Performance**: KMS encryption adds slight latency; monitor API server performance.

---

## 4. Monitoring Secrets

### Overview
Monitoring Secret usage and access involves tracking Kubernetes API interactions with Secrets and AWS SM/KMS operations. Kubernetes audit logs provide visibility into Secret access within the cluster, while AWS CloudTrail logs SM and KMS API calls.

### Detailed Steps for Monitoring

1. **Enable Kubernetes Audit Logs**:
   - Configure the Kubernetes API server to enable audit logging:
     - Create an audit policy:
       ```yaml
       apiVersion: audit.k8s.io/v1
       kind: Policy
       rules:
       - level: RequestResponse
         resources:
         - group: ""
           resources: ["secrets"]
         verbs: ["get", "create", "update", "delete"]
       ```
     - For EKS, update the cluster to use this policy:
       ```bash
       aws eks update-cluster-config \
         --region us-east-1 \
         --name <cluster-name> \
         --logging '{"clusterLogging":[{"types":["api"],"enabled":true}]}'
       ```
     - Store audit logs in an S3 bucket or send them to a SIEM (e.g., CloudWatch Logs).
   - Query logs for Secret access:
     ```bash
     aws logs filter-log-events \
       --log-group-name /aws/eks/<cluster-name>/cluster \
       --filter-pattern '"kind":"Secret"'
     ```

2. **Enable AWS CloudTrail for SM and KMS**:
   - Create a CloudTrail trail to log SM and KMS API calls:
     ```bash
     aws cloudtrail create-trail \
       --name my-k8s-trail \
       --s3-bucket-name <s3-bucket-name> \
       --region us-east-1
     aws cloudtrail put-event-selectors \
       --trail-name my-k8s-trail \
       --event-selectors '[{"ReadWriteType": "All", "IncludeManagementEvents": true, "DataResources": [{"Type": "AWS::SecretsManager::Secret", "Values": ["arn:aws:secretsmanager:us-east-1:<account-id>:secret:my-k8s-secret-*"]}, {"Type": "AWS::KMS::Key", "Values": ["arn:aws:kms:us-east-1:<account-id>:key/<key-id>"]}]}]'
     ```
   - Monitor CloudTrail logs for events like `GetSecretValue` or `Decrypt`:
     ```bash
     aws cloudtrail lookup-events \
       --lookup-attributes AttributeKey=ResourceName,AttributeValue=my-k8s-secret
     ```

3. **Integrate with Monitoring Tools**:
   - Use **Prometheus** and **Grafana** to visualize Secret-related metrics:
     - Install the Kubernetes Metrics Server and Prometheus:
       ```bash
       helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
       helm install prometheus prometheus-community/prometheus --namespace monitoring --create-namespace
       ```
     - Create custom Prometheus rules to alert on excessive Secret access.
   - Send CloudTrail logs to CloudWatch for real-time monitoring:
     ```bash
     aws logs create-log-group --log-group-name my-k8s-secrets-logs
     aws cloudtrail update-trail --name my-k8s-trail --cloud-watch-logs-log-group-arn arn:aws:logs:us-east-1:<account-id>:log-group:my-k8s-secrets-logs:*
     ```

4. **Real-World Scenario**:
   - **Scenario**: A security team needs to detect unauthorized Secret access in a Kubernetes cluster and AWS SM.
   - **Operation**:
     - Kubernetes audit logs reveal which users or ServiceAccounts accessed Secrets.
     - CloudTrail logs show who accessed the AWS SM secret or KMS key.
     - Alerts are set up in CloudWatch to notify the team of suspicious activity (e.g., repeated `GetSecretValue` calls).
   - **Steps**:
     - Enable audit logging and CloudTrail as described.
     - Create a CloudWatch Logs Insights query:
       ```sql
       fields @timestamp, eventName, userIdentity.arn
       | filter eventSource = "secretsmanager.amazonaws.com" and eventName = "GetSecretValue"
       | sort @timestamp desc
       ```
     - Set up a CloudWatch alarm to trigger on excessive API calls.

5. **Operational Considerations**:
   - **Log Retention**: Configure retention for audit logs and CloudTrail (e.g., 90 days).
   - **Cost**: Monitor S3 and CloudWatch storage costs for logs.
   - **Alerts**: Use AWS SNS or PagerDuty for real-time notifications of security events.
   - **SIEM Integration**: Integrate logs with a SIEM (e.g., Splunk, ELK) for advanced analysis.

---

## Summary of Real-World Operations
- **Secret Rotation**: Automate credential updates with AWS SM and Lambda, sync to Kubernetes with External Secrets Operator, and use Reloader to update pods.
- **Backup and Recovery**: Use Velero for Kubernetes Secret backups and AWS SM versioning for recovery. Test restores regularly.
- **Security**: Encrypt Secrets with AWS KMS in both Kubernetes and SM. Restrict KMS access to specific roles.
- **Monitoring**: Combine Kubernetes audit logs and CloudTrail for comprehensive visibility. Use Prometheus or CloudWatch for alerts.

---