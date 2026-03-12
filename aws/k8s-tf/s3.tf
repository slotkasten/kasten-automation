resource "aws_s3_bucket" "backup_target" {
  bucket        = "${var.creator_tag}-${terraform.workspace}-k10"
  force_destroy = true

  tags = {
    Env     = "${var.creator_tag}-${terraform.workspace}"
    Name    = "${var.creator_tag}-${terraform.workspace}-k10"
    Creator = "${var.creator_tag}"
  }
}

resource "aws_s3_bucket_public_access_block" "backup_target" {
  bucket = aws_s3_bucket.backup_target.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "backup_target" {
  bucket     = aws_s3_bucket.backup_target.id
  depends_on = [aws_s3_bucket_public_access_block.backup_target]

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "DenyAccessOutsideVpcAndAuthorizedNetworks",
        "Effect" : "Deny",
        "Principal" : "*",
        "Action" : "s3:*",
        "Resource" : [
          aws_s3_bucket.backup_target.arn,
          "${aws_s3_bucket.backup_target.arn}/*"
        ],
        "Condition" : {
          "StringNotEquals" : {
            "aws:sourceVpc" : aws_vpc.eks_vpc.id
          },
          "NotIpAddress" : {
            "aws:SourceIp" : var.authorized_networks[*].cidr_block
          },
          "Bool" : {
            "aws:ViaAWSService" : "false"
          }
        }
      }
    ]
  })
}
