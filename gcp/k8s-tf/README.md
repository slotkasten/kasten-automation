# GKE / Kasten Automation

This Terraform code deploys:

* [argocd.tf](./argocd.tf): if `var.argocd_deployment` is set to `true`, ArgoCD is deployed via the [Terraform Helm Provider](https://registry.terraform.io/providers/hashicorp/helm/latest/docs).
* [gcs.tf](./gcs.tf): a Google Cloud Storage bucket which is used for application backups via Kasten.
* [github.tf](./github.tf): if `var.argocd_deployment` is set to `true`, dynamic ArgoCD application and addon YAML specification files are created which are then committed to git using the [Terraform GitHub Provider](https://registry.terraform.io/providers/integrations/github/latest).
* [gke.tf](./gke.tf): a **zonal** GKE cluster, with most other options configurable via variables.
* [main.tf](./main.tf): required provider versions and credential file information.
* [vpc.tf](./vpc.tf): A new VPC, subnetwork with necessary secondary networks, firewall, and router and NAT gateway for egress internet access.

Please see the [main readme](../../README.md) for information on how to deploy.

## Credentials

There are three main credentials which are required:

* `github_repo_token`: a local file which contains a [fine-grained token](https://github.blog/security/application-security/introducing-fine-grained-personal-access-tokens-for-github/) for your GitHub account:
  * Optionally (but recommended) constrained to your `kasten-automation` repository
  * **Read** access to metadata
  * **Read** and **Write** access to code (also referred to as 'content')
* `sa_creds`: a local file to the [service account credential](https://cloud.google.com/iam/docs/service-account-creds#key-types) which is used to deploy Terraform resources with the following permissions:
  * roles/compute.admin
  * roles/compute.securityAdmin
  * roles/container.admin
  * roles/container.clusterAdmin
  * roles/container.developer
  * roles/iam.serviceAccountAdmin
  * roles/iam.serviceAccountUser
  * roles/resourcemanager.projectIamAdmin
  * roles/secretmanager.admin
  * roles/storage.admin
* `k10_sa_creds`: a local file to the [service account credential](https://cloud.google.com/iam/docs/service-account-creds#key-types) which is [used by Kasten](https://docs.kasten.io/latest/install/google/google#using-a-separate-gcp-service-account) to manage `volumesnapshot` in the GCP account, with the `compute.storageAdmin` permission

## Other Settings

### GitHub Settings

All of these variables *must* be updated to match your GitHub owner and repository information.

### GCP Settings

All of these variables *must* be updated to match your GCP service accounts, user, and project information.

### Authorized Networks

The bottom of the `tfvars` file contains an `authorized_networks` list which permits access to the deployed resources. You should update the values (and optionally add additional values) to match any IP ranges that you wish to access the environment from (`curl http://checkip.amazonaws.com` is a useful command to figure out your IP address).

## Output Variables

Once Terraform has finished deploying, there will be several output variables displayed, for example:

```text
_1_cloud_kubeconfig_cmd = "gcloud container clusters get-credentials mhaigh-uscentral-gke --region us-central1-b"
_2_argocd_apply_app_of_apps_cmd = "kubectl apply -f ../argocd/app-of-apps.yaml"
_3_argocd_endpoint = "https://34.172.210.102"
_4_argocd_admin_secret_copy_cmd = "terraform output -raw argocd_admin_secret | pbcopy"
_5_kasten_dashboard_cmd = "open http://`kubectl -n kasten-io get svc gateway-ext -ojsonpath='{.status.loadBalancer.ingress[0].ip}'`/k10/"
_6_kasten_token_cmd = "kubectl --namespace kasten-io create token dashboard-sa --duration=24h"
```

Additional detail on these outputs:

* `_1_cloud_kubeconfig_cmd`: a `gcloud` command to configure kubeconfig credentials
* `_2_argocd_apply_app_of_apps_cmd`: a `kubectl` command to deploy the parent `app-of-apps` application (this is the only ArgoCD application that must be manually deployed)
* `_3_argocd_endpoint`: The URL of the ArgoCD user interface
* `_4_argocd_admin_secret_copy_cmd`: A command to copy the ArgoCD admin password to your clipboard (if on MacOS, otherwise omit the `| pbcopy` to display the password)
* `_5_kasten_dashboard_cmd`: A command to open the Kasten K10 dashboard (it will take about 5 minutes after running `_2_argocd_apply_app_of_apps_cmd` for Kasten to be fully deployed)
* `_6_kasten_token_cmd`: A command to generate a 24 hour token to login to the Kasten K10 dashboard
