# AWS Secrets Manager secrets for External Secrets Operator (ESO) integration

# S3 bucket name
resource "aws_secretsmanager_secret" "s3_bucket_name" {
  name                    = "${var.creator_tag}-${terraform.workspace}-s3-bucket-name"
  recovery_window_in_days = 0

  tags = {
    Env     = "${var.creator_tag}-${terraform.workspace}"
    Name    = "${var.creator_tag}-${terraform.workspace}-s3-bucket-name"
    Creator = "${var.creator_tag}"
  }
}

resource "aws_secretsmanager_secret_version" "s3_bucket_name" {
  secret_id     = aws_secretsmanager_secret.s3_bucket_name.id
  secret_string = aws_s3_bucket.backup_target.bucket
}

# S3 bucket region (equivalent to Azure's azure-storage-environment)
resource "aws_secretsmanager_secret" "s3_bucket_region" {
  name                    = "${var.creator_tag}-${terraform.workspace}-s3-bucket-region"
  recovery_window_in_days = 0

  tags = {
    Env     = "${var.creator_tag}-${terraform.workspace}"
    Name    = "${var.creator_tag}-${terraform.workspace}-s3-bucket-region"
    Creator = "${var.creator_tag}"
  }
}

resource "aws_secretsmanager_secret_version" "s3_bucket_region" {
  secret_id     = aws_secretsmanager_secret.s3_bucket_region.id
  secret_string = var.aws_region
}

# Kasten DR passphrase (equivalent to Azure's kasten-dr-passphrase)
resource "random_password" "kasten_dr_passphrase" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "kasten_dr_passphrase" {
  name                    = "${var.creator_tag}-${terraform.workspace}-kasten-dr-passphrase"
  recovery_window_in_days = 0

  tags = {
    Env     = "${var.creator_tag}-${terraform.workspace}"
    Name    = "${var.creator_tag}-${terraform.workspace}-kasten-dr-passphrase"
    Creator = "${var.creator_tag}"
  }
}

resource "aws_secretsmanager_secret_version" "kasten_dr_passphrase" {
  secret_id     = aws_secretsmanager_secret.kasten_dr_passphrase.id
  secret_string = random_password.kasten_dr_passphrase.result
}

# Kasten DR source identifier (equivalent to Azure's kasten-dr-source)
resource "aws_secretsmanager_secret" "kasten_dr_source" {
  name                    = "${var.creator_tag}-${terraform.workspace}-kasten-dr-source"
  recovery_window_in_days = 0

  tags = {
    Env     = "${var.creator_tag}-${terraform.workspace}"
    Name    = "${var.creator_tag}-${terraform.workspace}-kasten-dr-source"
    Creator = "${var.creator_tag}"
  }
}

resource "aws_secretsmanager_secret_version" "kasten_dr_source" {
  secret_id     = aws_secretsmanager_secret.kasten_dr_source.id
  secret_string = "aws"
}

# Kasten IAM access keys
resource "aws_secretsmanager_secret" "kasten_access_key_id" {
  name                    = "${var.creator_tag}-${terraform.workspace}-kasten-access-key-id"
  recovery_window_in_days = 0

  tags = {
    Env     = "${var.creator_tag}-${terraform.workspace}"
    Name    = "${var.creator_tag}-${terraform.workspace}-kasten-access-key-id"
    Creator = "${var.creator_tag}"
  }
}

resource "aws_secretsmanager_secret_version" "kasten_access_key_id" {
  secret_id     = aws_secretsmanager_secret.kasten_access_key_id.id
  secret_string = aws_iam_access_key.eks_kasten.id
}

resource "aws_secretsmanager_secret" "kasten_secret_access_key" {
  name                    = "${var.creator_tag}-${terraform.workspace}-kasten-secret-access-key"
  recovery_window_in_days = 0

  tags = {
    Env     = "${var.creator_tag}-${terraform.workspace}"
    Name    = "${var.creator_tag}-${terraform.workspace}-kasten-secret-access-key"
    Creator = "${var.creator_tag}"
  }
}

resource "aws_secretsmanager_secret_version" "kasten_secret_access_key" {
  secret_id     = aws_secretsmanager_secret.kasten_secret_access_key.id
  secret_string = aws_iam_access_key.eks_kasten.secret
}

# ESO IAM Role (IRSA) for reading from Secrets Manager
resource "aws_iam_role" "eks_eso" {
  name = "${var.creator_tag}-${terraform.workspace}-eso-role"

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
            format("oidc.eks.${var.aws_region}.amazonaws.com/id/%s:sub", split("/", aws_iam_openid_connect_provider.cluster.arn)[3]) : "system:serviceaccount:external-secrets:external-secrets"
          }
        }
      }
    ]
  })

  tags = {
    Env     = "${var.creator_tag}-${terraform.workspace}"
    Name    = "${var.creator_tag}-${terraform.workspace}-eso-role"
    Creator = "${var.creator_tag}"
  }
}

resource "aws_iam_policy" "eks_eso" {
  name        = "${var.creator_tag}-${terraform.workspace}-eso-policy"
  description = "IAM policy for External Secrets Operator to read from Secrets Manager"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        "Resource" : [
          aws_secretsmanager_secret.s3_bucket_name.arn,
          aws_secretsmanager_secret.s3_bucket_region.arn,
          aws_secretsmanager_secret.kasten_dr_passphrase.arn,
          aws_secretsmanager_secret.kasten_dr_source.arn,
          aws_secretsmanager_secret.kasten_access_key_id.arn,
          aws_secretsmanager_secret.kasten_secret_access_key.arn
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : "secretsmanager:ListSecrets",
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ESOSecretsManagerAttachment" {
  policy_arn = aws_iam_policy.eks_eso.arn
  role       = aws_iam_role.eks_eso.name
}
