# EKS Cluster
resource "aws_eks_cluster" "eks_cluster" {
  name     = "${var.creator_tag}-${terraform.workspace}-cluster"
  role_arn = aws_iam_role.eks_cluster_iam.arn
  version  = var.eks_kubernetes_version

  vpc_config {
    subnet_ids              = flatten([aws_subnet.eks_public[*].id, aws_subnet.eks_private[*].id])
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = var.authorized_networks[*].cidr_block
  }

  tags = {
    Env     = "${var.creator_tag}-${terraform.workspace}",
    Name    = "${var.creator_tag}-${terraform.workspace}-cluster"
    Creator = "${var.creator_tag}"
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy
  ]
}

# EKS Cluster Security Group
resource "aws_security_group" "eks_cluster_sg" {
  name        = "${var.creator_tag}-${terraform.workspace}-cluster-sg"
  description = "Cluster communication with worker nodes"
  vpc_id      = aws_vpc.eks_vpc.id

  tags = {
    Env     = "${var.creator_tag}-${terraform.workspace}",
    Name    = "${var.creator_tag}-${terraform.workspace}-cluster-sg"
    Creator = "${var.creator_tag}"
  }
}

# EKS Cluster security group rules
resource "aws_security_group_rule" "eks_cluster_inbound" {
  description              = "Allow worker nodes to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster_sg.id
  source_security_group_id = aws_security_group.eks_nodes_sg.id
  to_port                  = 443
  type                     = "ingress"
}

resource "aws_security_group_rule" "eks_cluster_outbound" {
  description              = "Allow cluster API Server to communicate with the worker nodes"
  from_port                = 1024
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster_sg.id
  source_security_group_id = aws_security_group.eks_nodes_sg.id
  to_port                  = 65535
  type                     = "egress"
}


# EKS Node Groups
resource "aws_eks_node_group" "eks_ng" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "${terraform.workspace}-node-group"
  node_role_arn   = aws_iam_role.eks_node.arn
  subnet_ids      = aws_subnet.eks_private[*].id

  scaling_config {
    desired_size = var.eks_node_count
    max_size     = var.eks_node_max
    min_size     = var.eks_node_min
  }

  ami_type       = "AL2_x86_64"
  capacity_type  = "ON_DEMAND"
  instance_types = [var.eks_instance_type]

  launch_template {
    id      = aws_launch_template.eks_ng.id
    version = aws_launch_template.eks_ng.latest_version
  }

  tags = {
    Env     = "${var.creator_tag}-${terraform.workspace}",
    Name    = "${var.creator_tag}-${terraform.workspace}-node-group"
    Creator = "${var.creator_tag}"
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node_AmazonEKSServicePolicy,
    aws_iam_role_policy_attachment.node_AmazonEKSVPCResourceController,
  ]
}

# EKS Node Launch Template
resource "aws_launch_template" "eks_ng" {
  name = "${var.creator_tag}-${terraform.workspace}-node-lt"

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = var.eks_node_volume_size
      volume_type           = "gp3"
      delete_on_termination = true
    }
  }

  tags = {
    Env     = "${var.creator_tag}-${terraform.workspace}",
    Name    = "${var.creator_tag}-${terraform.workspace}-node-lt"
    Creator = "${var.creator_tag}"
  }
}

# EKS Node Security Group
resource "aws_security_group" "eks_nodes_sg" {
  name        = "${var.creator_tag}-${terraform.workspace}-nodes-sg"
  description = "Security group for all nodes in the cluster"
  vpc_id      = aws_vpc.eks_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Env     = "${var.creator_tag}-${terraform.workspace}",
    Name    = "${var.creator_tag}-${terraform.workspace}-node-sg",
    Creator = "${var.creator_tag}"

    "kubernetes.io/cluster/${var.creator_tag}-${terraform.workspace}-cluster" = "owned"
  }
}

resource "aws_security_group_rule" "eks_nodes_internal" {
  description              = "Allow nodes to communicate with each other"
  security_group_id        = aws_security_group.eks_nodes_sg.id
  source_security_group_id = aws_security_group.eks_nodes_sg.id
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "-1"
}

resource "aws_security_group_rule" "eks_nodes_cluster_inbound" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  security_group_id        = aws_security_group.eks_nodes_sg.id
  source_security_group_id = aws_security_group.eks_cluster_sg.id
  type                     = "ingress"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
}


# ADD-ONS
resource "aws_eks_addon" "addons" {
  depends_on    = [aws_eks_node_group.eks_ng]
  for_each      = { for addon in var.eks_addons : addon.name => addon }
  cluster_name  = aws_eks_cluster.eks_cluster.id
  addon_name    = each.value.name
  addon_version = each.value.version
  service_account_role_arn = (each.value.name == "aws-ebs-csi-driver" ? aws_iam_role.eks_ebs_csi.arn :
    (each.value.name == "aws-efs-csi-driver" ? aws_iam_role.eks_efs_csi.arn :
      (each.value.name == "vpc-cni" ? aws_iam_role.eks_vpc_cni.arn :
  aws_iam_role.eks_node.arn)))

  tags = {
    Env     = "${var.creator_tag}-${terraform.workspace}",
    Name    = "${var.creator_tag}-${terraform.workspace}-${each.value.name}"
    Creator = "${var.creator_tag}"
  }
}
# EBS CSI Storage Class
resource "kubernetes_storage_class_v1" "ebs_csi" {
  depends_on = [aws_eks_addon.addons]

  metadata {
    name = "ebs-csi"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  storage_provisioner    = "ebs.csi.aws.com"
  volume_binding_mode    = "WaitForFirstConsumer"
  reclaim_policy         = "Delete"
  allow_volume_expansion = true

  parameters = {
    type = "gp3"
  }
}

data "external" "thumbprint" {
  program = [format("%s/scripts/get_thumbprint.sh", path.module), var.aws_region]
}
## OIDC config
resource "aws_iam_openid_connect_provider" "cluster" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.external.thumbprint.result.thumbprint]
  url             = aws_eks_cluster.eks_cluster.identity.0.oidc.0.issuer
}

# Cleanup ArgoCD applications before destroying infrastructure.
# Deleting app-of-apps triggers a cascade delete (via the resources-finalizer
# baked into the template) of all child apps in reverse sync-wave order, which
# in turn delete their managed resources. This ensures ExternalDNS cleans up
# Cloudflare DNS records as HTTPRoutes are removed, and cloud load balancers
# are deprovisioned.
resource "null_resource" "k8s_cleanup" {
  count = var.deployment.argocd ? 1 : 0

  triggers = {
    cluster_name = aws_eks_cluster.eks_cluster.name
    region       = var.aws_region
  }

  depends_on = [
    aws_eks_addon.addons,
    aws_nat_gateway.eks_nat_gw,
    aws_route.eks_route,
    github_repository_file.addons_argocd_httproute,
    github_repository_file.addons_certmanager_cloudflare_secret,
    github_repository_file.addons_certmanager_cluster_issuer,
    github_repository_file.addons_envoygateway_gateway,
    github_repository_file.addons_envoygateway_gatewayclass,
    github_repository_file.addons_envoygateway_http_redirect,
    github_repository_file.addons_externaldns_cloudflare_secret,
    github_repository_file.addons_externaldns_predelete_hook,
    github_repository_file.addons_externalsecrets_clustersecretstore,
    github_repository_file.addons_kastendr_policy,
    github_repository_file.addons_kastendr_secret,
    github_repository_file.addons_kastenio_httproute,
    github_repository_file.addons_kastenprofiles_aws_credential,
    github_repository_file.addons_kastenprofiles_infrastructure,
    github_repository_file.addons_kastenprofiles_location,
    github_repository_file.addons_pacman_backup,
    github_repository_file.addons_pacman_httproute,
    github_repository_file.app_of_apps,
    github_repository_file.apps_argocd_gateway,
    github_repository_file.apps_cert_manager,
    github_repository_file.apps_cert_manager_config,
    github_repository_file.apps_envoy_gateway,
    github_repository_file.apps_envoy_gateway_config,
    github_repository_file.apps_external_dns,
    github_repository_file.apps_external_secrets,
    github_repository_file.apps_kasten_dr,
    github_repository_file.apps_kasten_io,
    github_repository_file.apps_kasten_profiles,
    github_repository_file.apps_pacman,
    github_repository_file.apps_snapshot_controller,
    kubernetes_config_map_v1_data.argocd_cm,
    kubernetes_storage_class_v1.ebs_csi,
    time_sleep.wait_for_argocd,
  ]

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      aws eks update-kubeconfig --name ${self.triggers.cluster_name} --region ${self.triggers.region} &&
      kubectl delete application -n argocd app-of-apps --ignore-not-found || true
    EOT
  }
}
