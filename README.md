# Kasten Automation

This repository contains Terraform code which creates hyperscaler Kubernetes-as-a-Service offerings (AWS will be added in the future):

* [Azure Kubernetes Service (AKS)](https://azure.microsoft.com/en-us/products/kubernetes-service)
* [Google Kubernetes Engine (GKE)](https://cloud.google.com/kubernetes-engine)

In addition to deploying Kubernetes, the Terraform IaC will optionally install ArgoCD, which is then used to bootstrap the cluster by:

* Dynamically generating ArgoCD application and addon specification YAML, which are automatically committed to the repository with the [Terraform GitHub Provider](https://registry.terraform.io/providers/integrations/github/latest/docs) (adhering to the GitOps principle of git being the single source of truth)
* ArgoCD then deploys the following applications via the [app-of-apps](https://argo-cd.readthedocs.io/en/latest/operator-manual/cluster-bootstrapping/#app-of-apps-pattern) pattern:
  * [External Secrets Operator](https://external-secrets.io/latest/) to securely generate Kubernetes secrets on the deployed cluster
  * [Kasten K10](https://github.com/kastenhq/k10/tree/master/helm/k10) with infrasructure and location profiles to store Kubernetes application backups
  * [Pacman](https://github.com/MichaelHaigh/pacman) demo application with a Kasten policy for protection

## Getting Started

This repository *must* be forked, as `git push` privileges are required for automated Terraform commits. Then change into the hyperscaler directory of your choice, and initialize terraform:

```text
terraform init
```

The provider version in each `main.tf` file is constrained by the `~>` operator to ensure code compatibility, however feel free to change to a different operator if needed. Information on required privileges for the various providers can be found in the specific hyperscaler directory ReadMe.

Next, update the `default.tfvars` file to have the deployment parameters of your choosing. Additional information on their meanings can be found in the `variables.tf` file.

Plan your deployment with the following command (more information on [workspaces](#workspaces-support) in the section below):

```text
terraform plan -var-file="$(terraform workspace show).tfvars"
```

Create your deployment:

```text
terraform apply -var-file="$(terraform workspace show).tfvars" && git pull
```

The `git pull` portion of the command is to keep your local branch up to date with the origin branch.

When your deployment is no longer needed, run the following command to clean up all resources:

```text
terraform destroy -var-file="$(terraform workspace show).tfvars" && git pull
```

## Workspaces Support

All code in this respository has been designed to support [Terraform Workspaces](https://developer.hashicorp.com/terraform/cli/workspaces). This enables multiple deployments (for example: `prod` and `dr`, and/or `useast1` and `useast2`) of the same type of environments. To create new workspaces (beyond the `default` workspace), run the following commands:

```text
terraform workspace new <workspace-name>
git checkout -b $(terraform workspace show)
git push -u origin $(terraform workspace show)
```

> **Note**: your workspace name and git branch name *must* be identical.

Next, copy the `default.tfvars` file:

```text
cp default.tfvars $(terraform workspace show).tfvars
```

Optionally edit the `<workspace-name>.tfvars` file, and then deploy the new environment with the same command:

```text
terraform apply -var-file="$(terraform workspace show).tfvars" && git pull
```

It is also recommended to commit your tfvars file to git to adhere to GitOps principles (assuming no secrets are contained directly within the file).

To switch to a different workspace, run:

```text
terraform workspace select <workspace-name>
```

To view all available workspaces, run:

```text
terraform workspace list
```
