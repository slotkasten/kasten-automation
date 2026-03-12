# EKS Cluster IAM Role
resource "aws_iam_role" "eks_cluster_iam" {
  name = "${var.creator_tag}-${terraform.workspace}-cluster-role"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "eks.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_iam.name
}

# EKS Node IAM Role
resource "aws_iam_role" "eks_node" {
  name = "${var.creator_tag}-${terraform.workspace}-worker-role"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ec2.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "node_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node.name
}
resource "aws_iam_role_policy_attachment" "node_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node.name
}
resource "aws_iam_role_policy_attachment" "node_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node.name
}
resource "aws_iam_role_policy_attachment" "node_AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks_node.name
}
resource "aws_iam_role_policy_attachment" "node_AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_node.name
}

# EKS VPC-CNI IAM Role (IRSA)
resource "aws_iam_role" "eks_vpc_cni" {
  name = "${var.creator_tag}-${terraform.workspace}-vpc-cni-role"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Federated" : aws_iam_openid_connect_provider.cluster.arn
        },
        "Action" : "sts:AssumeRoleWithWebIdentity",
        "Condition" : {
          "StringEquals" : {
            format("oidc.eks.${var.aws_region}.amazonaws.com/id/%s:aud", split("/", aws_iam_openid_connect_provider.cluster.arn)[3]) : "sts.amazonaws.com",
            format("oidc.eks.${var.aws_region}.amazonaws.com/id/%s:sub", split("/", aws_iam_openid_connect_provider.cluster.arn)[3]) : "system:serviceaccount:kube-system:aws-node"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy_IRSA" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_vpc_cni.name
}

# EKS EBS-CSI IAM Role
resource "aws_iam_role" "eks_ebs_csi" {
  name = "${var.creator_tag}-${terraform.workspace}-ebs-csi-role"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Federated" : aws_iam_openid_connect_provider.cluster.arn
        },
        "Action" : "sts:AssumeRoleWithWebIdentity",
        "Condition" : {
          "StringEquals" : {
            format("oidc.eks.${var.aws_region}.amazonaws.com/id/%s:aud", split("/", aws_iam_openid_connect_provider.cluster.arn)[3]) : "sts.amazonaws.com",
            format("oidc.eks.${var.aws_region}.amazonaws.com/id/%s:sub", split("/", aws_iam_openid_connect_provider.cluster.arn)[3]) : "system:serviceaccount:kube-system:ebs-csi-controller-sa"
          }
        }
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "AmazonEBSCSIDriverRoleAttachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.eks_ebs_csi.name
}

# EKS EFS-CSI IAM Role
resource "aws_iam_role" "eks_efs_csi" {
  name = "${var.creator_tag}-${terraform.workspace}-efs-csi-role"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Federated" : aws_iam_openid_connect_provider.cluster.arn
        },
        "Action" : "sts:AssumeRoleWithWebIdentity",
        "Condition" : {
          "StringEquals" : {
            format("oidc.eks.${var.aws_region}.amazonaws.com/id/%s:aud", split("/", aws_iam_openid_connect_provider.cluster.arn)[3]) : "sts.amazonaws.com",
            format("oidc.eks.${var.aws_region}.amazonaws.com/id/%s:sub", split("/", aws_iam_openid_connect_provider.cluster.arn)[3]) : "system:serviceaccount:kube-system:efs-csi-*"
          }
        }
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "AmazonEFSCSIDriverRoleAttachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
  role       = aws_iam_role.eks_efs_csi.name
}


# Data source for IAM Policy
data "http" "iam_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.11.0/docs/install/iam_policy.json"

  request_headers = {
    Accept = "application/json"
  }

  lifecycle {
    postcondition {
      condition     = contains([200], self.status_code)
      error_message = "Status code invalid"
    }
  }
}

# EKS Load Balancer IAM Policy
resource "aws_iam_policy" "eks_lb" {
  name        = "${var.creator_tag}-${terraform.workspace}-lb-policy"
  description = "IAM policy for the AWS Load Balancer Controller that allows it to make calls to AWS APIs on our behalf"

  policy = data.http.iam_policy.response_body
}

# EKS Load Balancer IAM Role
resource "aws_iam_role" "eks_lb" {
  name = "${var.creator_tag}-${terraform.workspace}-lb-role"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Federated" : aws_iam_openid_connect_provider.cluster.arn
        },
        "Action" : "sts:AssumeRoleWithWebIdentity",
        "Condition" : {
          "StringEquals" : {
            format("oidc.eks.${var.aws_region}.amazonaws.com/id/%s:aud", split("/", aws_iam_openid_connect_provider.cluster.arn)[3]) : "sts.amazonaws.com",
            format("oidc.eks.${var.aws_region}.amazonaws.com/id/%s:sub", split("/", aws_iam_openid_connect_provider.cluster.arn)[3]) : "system:serviceaccount:kube-system:aws-load-balancer-controller"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "AWSLoadBalancerControllerIAMPolicy" {
  policy_arn = aws_iam_policy.eks_lb.arn
  role       = aws_iam_role.eks_lb.name
}

# Kasten K10 IAM User
resource "aws_iam_user" "eks_kasten" {
  name = "${var.creator_tag}-${terraform.workspace}-kasten-user"

  tags = {
    Env     = "${var.creator_tag}-${terraform.workspace}"
    Name    = "${var.creator_tag}-${terraform.workspace}-kasten-user"
    Creator = "${var.creator_tag}"
  }
}

resource "aws_iam_access_key" "eks_kasten" {
  user = aws_iam_user.eks_kasten.name
}

resource "aws_iam_policy" "eks_kasten" {
  name        = "${var.creator_tag}-${terraform.workspace}-kasten-policy"
  description = "IAM policy for Kasten K10 for S3 backups and EBS snapshot operations"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:CopySnapshot",
          "ec2:CreateSnapshot",
          "ec2:CreateTags",
          "ec2:CreateVolume",
          "ec2:DeleteTags",
          "ec2:DeleteVolume",
          "ec2:DescribeSnapshotAttribute",
          "ec2:ModifySnapshotAttribute",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeRegions",
          "ec2:DescribeSnapshots",
          "ec2:DescribeTags",
          "ec2:DescribeVolumeAttribute",
          "ec2:DescribeVolumesModifications",
          "ec2:DescribeVolumeStatus",
          "ec2:DescribeVolumes",
          "ebs:ListSnapshotBlocks",
          "ebs:ListChangedBlocks",
          "ebs:GetSnapshotBlock"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : "ec2:DeleteSnapshot",
        "Resource" : "*",
        "Condition" : {
          "StringLike" : {
            "ec2:ResourceTag/name" : "kasten__snapshot*"
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : "ec2:DeleteSnapshot",
        "Resource" : "*",
        "Condition" : {
          "StringLike" : {
            "ec2:ResourceTag/Name" : "Kasten: Snapshot*"
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:GetBucketPolicy"
        ],
        "Resource" : aws_s3_bucket.backup_target.arn
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ],
        "Resource" : "${aws_s3_bucket.backup_target.arn}/*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "secretsmanager:GetSecretValue"
        ],
        "Resource" : aws_secretsmanager_secret.kasten_dr_passphrase.arn
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "KastenPolicyAttachment" {
  policy_arn = aws_iam_policy.eks_kasten.arn
  user       = aws_iam_user.eks_kasten.name
}
