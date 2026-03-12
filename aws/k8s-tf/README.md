# EKS / Kasten Automation

This Terraform code deploys:

* [argocd.tf](./argocd.tf): ArgoCD Helm deployment (conditional on `argocd_deployment` variable), with wait timers and health status customization.
* [eks.tf](./eks.tf): an EKS cluster and managed node group, with most options configurable via variables.
* [github.tf](./github.tf): template rendering and GitHub repository file commits for ArgoCD GitOps (conditional on `argocd_deployment`).
* [iam.tf](./iam.tf): IAM roles and policies for the EKS cluster, worker nodes, EBS CSI driver, EFS CSI driver, VPC CNI, and AWS Load Balancer Controller (using IRSA), plus an IAM user with access keys for Kasten K10.
* [main.tf](./main.tf): required provider versions and credential file information.
* [s3.tf](./s3.tf): an S3 bucket which is used for application backups via Kasten, with a bucket policy restricting access to the VPC and authorized networks.
* [secrets.tf](./secrets.tf): AWS Secrets Manager secrets for External Secrets Operator (ESO) integration (including Kasten access keys, S3 bucket info, and DR passphrase), and an ESO IRSA role for reading from Secrets Manager.
* [variables.tf](./variables.tf): variable declarations.
* [vpc.tf](./vpc.tf): a new VPC, public and private subnets across multiple availability zones, internet gateway, NAT gateway, VPC endpoints for S3 and Secrets Manager, and associated security groups and route tables.

Please see the [main readme](../../README.md) for information on how to deploy.

## Credentials

Two credentials are required:

* `aws_cred_file`: this variable should point to a local JSON file containing AWS credentials with the following format:
    ```text
    {
        "aws_access_key_id": "AKIAIOSFODNN7EXAMPLE",
        "aws_secret_access_key": "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
    }
    ```
* `github_repo_token`: this variable should point to a local file containing a GitHub personal access token with read/write repository permissions.

## Other Settings

### GitHub Settings

The `github_owner`, `github_repo`, and `github_repo_url` variables must be updated to match your GitHub repository.

### AWS Settings

All of these variables *must* be updated to match your AWS region and credential file location.

### ArgoCD / Deployed Apps Settings

Set `argocd_deployment = true` to enable ArgoCD deployment and GitOps file commits. When disabled, only core infrastructure (EKS, VPC, S3, IAM, Secrets Manager) is deployed.

### Authorized Networks

The bottom of the `tfvars` file contains an `authorized_networks` list which permits access to the deployed resources. You should update the values (and optionally add additional values) to match any IP ranges that you wish to access the environment from (`curl http://checkip.amazonaws.com` is a useful command to figure out your IP address).

## Output Variables

Once Terraform has finished deploying, there will be several output variables displayed, for example:

```text
_1_aws_kubeconfig_cmd = "aws eks update-kubeconfig --region us-east-2 --name mhaigh-default-cluster"
```

Additional detail on these outputs:

* `_1_aws_kubeconfig_cmd`: an `aws` CLI command to configure kubeconfig credentials
* `_2_argocd_apply_app_of_apps_cmd`: the `kubectl` command to apply the app-of-apps manifest
* `_3_argocd_endpoint`: the URL to access the ArgoCD UI
* `_4_argocd_admin_secret_copy_cmd`: a command to copy the ArgoCD admin secret to clipboard
* `_5_kasten_dashboard_cmd`: the command to open the Kasten K10 dashboard
* `_6_kasten_token_cmd`: the command to create a Kasten dashboard login token
