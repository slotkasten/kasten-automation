# EKS / Kasten Automation

This Terraform code deploys:

* [argocd.tf](./argocd.tf): if `var.deployment.argocd` is set to `true`, ArgoCD is deployed via the [Terraform Helm Provider](https://registry.terraform.io/providers/hashicorp/helm/latest/docs).
* [eks.tf](./eks.tf): an EKS cluster and managed node group, with most options configurable via variables.
* [github.tf](./github.tf): if `var.deployment.argocd` is set to `true`, dynamic ArgoCD application and addon YAML specification files are created which are then committed to git using the [Terraform GitHub Provider](https://registry.terraform.io/providers/integrations/github/latest).
* [iam.tf](./iam.tf): IAM roles and policies for the EKS cluster, worker nodes, EBS CSI driver, EFS CSI driver, VPC CNI, and AWS Load Balancer Controller (using IRSA), plus an IAM user with access keys for Kasten K10.
* [main.tf](./main.tf): required provider versions and credential file information.
* [s3.tf](./s3.tf): an S3 bucket which is used for application backups via Kasten, with a bucket policy restricting access to the VPC and authorized networks.
* [secrets.tf](./secrets.tf): AWS Secrets Manager secrets for External Secrets Operator (ESO) integration (including Kasten access keys, S3 bucket info, DR passphrase, and optionally a Cloudflare API token), and an ESO IRSA role for reading from Secrets Manager.
* [vpc.tf](./vpc.tf): a new VPC, public and private subnets across multiple availability zones, internet gateway, NAT gateway, VPC endpoints for S3 and Secrets Manager, and associated security groups and route tables.

Please see the [main readme](../../README.md) for information on how to deploy.

## Credentials

Two credentials are required (three if `deployment.cert_manager` is enabled):

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
* `cloudflare_api_token` (only required if `deployment.cert_manager = true`): a local file containing a [Cloudflare API token](https://developers.cloudflare.com/fundamentals/api/get-started/create-token/) with the following permissions:
  * **Zone:DNS:Edit** — cert-manager creates TXT records for DNS-01 challenges; ExternalDNS creates A records for routing
  * **Zone:Zone:Read** — cert-manager needs this for DNS-01 zone lookup
  * Scoped to the specific zone (domain) specified in `domain_name`

## Other Settings

### GitHub Settings

The `github_owner`, `github_repo`, and `github_repo_url` variables must be updated to match your GitHub repository.

### AWS Settings

All of these variables *must* be updated to match your AWS region and credential file location.

### ArgoCD / Deployed Apps Settings

Set `deployment.argocd = true` to enable ArgoCD deployment and GitOps file commits. When disabled, only core infrastructure (EKS, VPC, S3, IAM, Secrets Manager) is deployed.

### cert-manager / Gateway API Settings

Set `deployment.cert_manager = true` to enable cert-manager, Envoy Gateway, ExternalDNS, and Kubernetes Gateway API resources. This requires `deployment.argocd = true`.

When enabled, all applications (ArgoCD, Kasten, Pacman) are accessible via TLS-enabled subdomains using the naming convention `{app}.{creator}-{workspace}.{domain_name}` (e.g. `argocd.mhaigh-default.example.com`). A single wildcard certificate (`*.{creator}-{workspace}.{domain_name}`) is issued by cert-manager via a Cloudflare DNS-01 challenge, covering all subdomains. ExternalDNS automatically creates Cloudflare A records by watching HTTPRoute resources.

| Variable | Description |
|---|---|
| `deployment.cert_manager` | Master toggle for all Gateway API resources (default: `false`) |
| `cert_manager_version` | cert-manager Helm chart version |
| `envoy_gateway_version` | Envoy Gateway Helm chart version |
| `external_dns_version` | ExternalDNS Helm chart version |
| `cloudflare_api_token` | Path to file containing Cloudflare API token |
| `domain_name` | Base domain (e.g. `example.com`) |
| `email` | Email for Let's Encrypt registration |
| `letsencrypt_staging` | Use Let's Encrypt staging server (default: `true`, recommended for testing to avoid rate limits) |

> **Note**: `letsencrypt_staging` defaults to `true`, which issues certificates from the Let's Encrypt staging CA. Browsers will show a certificate warning. Set to `false` for production-trusted certificates once you've verified the deployment works correctly.

### Authorized Networks

The bottom of the `tfvars` file contains an `authorized_networks` list which permits access to the deployed resources. You should update the values (and optionally add additional values) to match any IP ranges that you wish to access the environment from (`curl http://checkip.amazonaws.com` is a useful command to figure out your IP address).

## ArgoCD Applications

The following applications are deployed via the [app-of-apps](https://argo-cd.readthedocs.io/en/latest/operator-manual/cluster-bootstrapping/#app-of-apps-pattern) pattern, ordered by [sync wave](https://argo-cd.readthedocs.io/en/latest/user-guide/sync-waves/):

| Sync Wave | Application | Description |
|---|---|---|
| -10 | cert-manager * | cert-manager with CRDs and Gateway API support |
| -10 | envoy-gateway * | Envoy Gateway (Gateway API controller) |
| -10 | external-secrets | External Secrets Operator (ESO) with IRSA and ClusterSecretStore |
| -10 | snapshot-controller | Piraeus snapshot controller for EBS volume snapshots |
| -9 | external-dns * | ExternalDNS with Cloudflare provider and gateway-httproute source |
| -8 | argocd-gateway * | ArgoCD HTTPRoute |
| -8 | cert-manager-config * | ClusterIssuer and Cloudflare API token ExternalSecret |
| -8 | envoy-gateway-config * | GatewayClass, Gateway (wildcard TLS), and HTTP-to-HTTPS redirect |
| -5 | kasten-io | Kasten K10 with token auth, EULA, and Kasten HTTPRoute * |
| -3 | kasten-profiles | Infrastructure and location profiles for Kasten backups |
| -1 | kasten-dr | Disaster recovery policy and passphrase secret |
| 5 | pacman | Pacman demo app with backup policy and Pacman HTTPRoute * |

\* Only deployed when `deployment.cert_manager = true`

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

When `deployment.cert_manager = true`, some outputs change to domain-based URLs:

```text
_3_argocd_endpoint = "https://argocd.mhaigh-default.example.com # once Gateway is up"
_5_kasten_dashboard_cmd = "open https://kasten.mhaigh-default.example.com/k10/"
_7_pacman_url = "https://pacman.mhaigh-default.example.com"
argocd_port_forward_cmd = "open http://localhost:8080; kubectl port-forward svc/argocd-server -n argocd 8080:80"
```

> **Note**: When `deployment.cert_manager = true`, it will take 10 to 20 minutes for all workloads to come up after applying the app-of-apps YAML. This includes time for cert-manager to issue a wildcard TLS certificate via Let's Encrypt DNS-01 validation, Envoy Gateway to provision a load balancer, and ExternalDNS to create Cloudflare A records.

Additional detail on these outputs:

* `_1_aws_kubeconfig_cmd`: an `aws` command to configure kubeconfig credentials
* `_2_argocd_apply_app_of_apps_cmd`: a `kubectl` command to deploy the parent `app-of-apps` application (this is the only ArgoCD application that must be manually deployed)
* `_3_argocd_endpoint`: the URL of the ArgoCD user interface (domain-based when cert-manager is enabled)
* `_4_argocd_admin_secret_copy_cmd`: a command to copy the ArgoCD admin password to your clipboard (if on MacOS, otherwise omit the `| pbcopy` to display the password)
* `_5_kasten_dashboard_cmd`: a command to open the Kasten K10 dashboard (it will take about 5 minutes after running `_2_argocd_apply_app_of_apps_cmd` for Kasten to be fully deployed)
* `_6_kasten_token_cmd`: a command to generate a 24 hour token to login to the Kasten K10 dashboard
* `_7_pacman_url`: the URL of the Pacman demo app (only shown when cert-manager is enabled)
* `argocd_port_forward_cmd`: a port-forward command to access ArgoCD locally before the Gateway stack is fully deployed (only shown when cert-manager is enabled)
