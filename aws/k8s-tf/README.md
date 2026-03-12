# EKS / Kasten Automation

This Terraform code deploys:

* [argocd.tf](./argocd.tf): if `var.argocd_deployment` is set to `true`, ArgoCD is deployed via the [Terraform Helm Provider](https://registry.terraform.io/providers/hashicorp/helm/latest/docs).
* [eks.tf](./eks.tf): an EKS cluster and managed node group, with most options configurable via variables.
* [github.tf](./github.tf): if `var.argocd_deployment` is set to `true`, dynamic ArgoCD application and addon YAML specification files are created which are then committed to git using the [Terraform GitHub Provider](https://registry.terraform.io/providers/integrations/github/latest).
* [iam.tf](./iam.tf): IAM roles and policies for the EKS cluster, worker nodes, EBS CSI driver, EFS CSI driver, VPC CNI, and AWS Load Balancer Controller (using IRSA), plus an IAM user with access keys for Kasten K10.
* [main.tf](./main.tf): required provider versions and credential file information.
* [s3.tf](./s3.tf): an S3 bucket which is used for application backups via Kasten, with a bucket policy restricting access to the VPC and authorized networks.
* [secrets.tf](./secrets.tf): AWS Secrets Manager secrets for External Secrets Operator (ESO) integration (including Kasten access keys, S3 bucket info, and DR passphrase), and an ESO IRSA role for reading from Secrets Manager.
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
* `github_repo_token`: a local file which contains a [fine-grained token](https://github.blog/security/application-security/introducing-fine-grained-personal-access-tokens-for-github/) for your GitHub account:
  * Optionally (but recommended) constrained to your `kasten-automation` repository
  * **Read** access to metadata
  * **Read** and **Write** access to code (also referred to as 'content')

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
_2_argocd_apply_app_of_apps_cmd = "kubectl apply -f ../argocd/app-of-apps.yaml"
_3_argocd_endpoint = "https://a1b2c3d4e5f6g7.us-east-2.elb.amazonaws.com"
_4_argocd_admin_secret_copy_cmd = "terraform output -raw argocd_admin_secret | pbcopy"
_5_kasten_dashboard_cmd = "open http://`kubectl -n kasten-io get svc gateway-ext -ojsonpath='{.status.loadBalancer.ingress[0].hostname}'`/k10/"
_6_kasten_token_cmd = "kubectl --namespace kasten-io create token dashboard-sa --duration=24h"
```

Additional detail on these outputs:

* `_1_aws_kubeconfig_cmd`: an `aws` command to configure kubeconfig credentials
* `_2_argocd_apply_app_of_apps_cmd`: a `kubectl` command to deploy the parent `app-of-apps` application (this is the only ArgoCD application that must be manually deployed)
* `_3_argocd_endpoint`: the URL of the ArgoCD user interface
* `_4_argocd_admin_secret_copy_cmd`: a command to copy the ArgoCD admin password to your clipboard (if on MacOS, otherwise omit the `| pbcopy` to display the password)
* `_5_kasten_dashboard_cmd`: a command to open the Kasten K10 dashboard (it will take about 5 minutes after running `_2_argocd_apply_app_of_apps_cmd` for Kasten to be fully deployed)
* `_6_kasten_token_cmd`: a command to generate a 24 hour token to login to the Kasten K10 dashboard
