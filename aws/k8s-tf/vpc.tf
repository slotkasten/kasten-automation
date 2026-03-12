# VPC Configuration
resource "aws_vpc" "eks_vpc" {
  cidr_block = var.eks_vpc_cidr

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Env     = "${var.creator_tag}-${terraform.workspace}",
    Name    = "${var.creator_tag}-${terraform.workspace}-vpc",
    Creator = "${var.creator_tag}"

    "kubernetes.io/cluster/${var.creator_tag}-${terraform.workspace}-cluster" = "shared"
  }
}

# Public subnets
resource "aws_subnet" "eks_public" {
  count = var.availability_zones_count

  vpc_id            = aws_vpc.eks_vpc.id
  cidr_block        = var.eks_public_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Region                   = var.aws_region,
    Env                      = "${var.creator_tag}-${terraform.workspace}",
    Name                     = "${var.creator_tag}-${terraform.workspace}-public-subnet",
    Creator                  = "${var.creator_tag}"
    "kubernetes.io/role/elb" = 1

    "kubernetes.io/cluster/${var.creator_tag}-${terraform.workspace}-cluster" = "shared",
  }

  map_public_ip_on_launch = true
}

# Private subnets
resource "aws_subnet" "eks_private" {
  count = var.availability_zones_count

  vpc_id            = aws_vpc.eks_vpc.id
  cidr_block        = var.eks_private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Env                               = "${var.creator_tag}-${terraform.workspace}",
    Name                              = "${var.creator_tag}-${terraform.workspace}-private-subnet",
    Creator                           = "${var.creator_tag}"
    "kubernetes.io/role/internal-elb" = 1

    "kubernetes.io/cluster/${var.creator_tag}-${terraform.workspace}-cluster" = "shared",
  }
}

# Internet Gateway
resource "aws_internet_gateway" "eks_igw" {
  vpc_id = aws_vpc.eks_vpc.id

  tags = {
    Env     = "${var.creator_tag}-${terraform.workspace}",
    Name    = "${var.creator_tag}-${terraform.workspace}-igw"
    Creator = "${var.creator_tag}"
  }

  depends_on = [aws_vpc.eks_vpc]
}

# Route table to route public subnet traffic through the IGW
resource "aws_route_table" "eks_public_rt" {
  vpc_id = aws_vpc.eks_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eks_igw.id
  }

  tags = {
    Env     = "${var.creator_tag}-${terraform.workspace}",
    Name    = "${var.creator_tag}-${terraform.workspace}-default-rt"
    Creator = "${var.creator_tag}"
  }
}

# Route table and subnet association
resource "aws_route_table_association" "eks_internet_access" {
  count = var.availability_zones_count

  subnet_id      = aws_subnet.eks_public[count.index].id
  route_table_id = aws_route_table.eks_public_rt.id
}

# NAT Elastic IP
resource "aws_eip" "eks_nat_eip" {
  domain = "vpc"

  tags = {
    Env     = "${var.creator_tag}-${terraform.workspace}",
    Name    = "${var.creator_tag}-${terraform.workspace}-ngw-ip"
    Creator = "${var.creator_tag}"
  }
}

# NAT Gateway
resource "aws_nat_gateway" "eks_nat_gw" {
  allocation_id = aws_eip.eks_nat_eip.id
  subnet_id     = aws_subnet.eks_public[0].id

  tags = {
    Env     = "${var.creator_tag}-${terraform.workspace}",
    Name    = "${var.creator_tag}-${terraform.workspace}-nat-gw"
    Creator = "${var.creator_tag}"
  }
}

# Add default route in the route table to the NGW
resource "aws_route" "eks_route" {
  route_table_id         = aws_vpc.eks_vpc.default_route_table_id
  nat_gateway_id         = aws_nat_gateway.eks_nat_gw.id
  destination_cidr_block = "0.0.0.0/0"
}

# VPC Endpoint for S3 (gateway type, no cost)
resource "aws_vpc_endpoint" "s3" {
  vpc_id          = aws_vpc.eks_vpc.id
  service_name    = "com.amazonaws.${var.aws_region}.s3"
  route_table_ids = [aws_route_table.eks_public_rt.id, aws_vpc.eks_vpc.default_route_table_id]

  tags = {
    Env     = "${var.creator_tag}-${terraform.workspace}",
    Name    = "${var.creator_tag}-${terraform.workspace}-s3-vpce"
    Creator = "${var.creator_tag}"
  }
}

# VPC Endpoint for Secrets Manager (interface type)
resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = aws_vpc.eks_vpc.id
  service_name        = "com.amazonaws.${var.aws_region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.eks_private[*].id
  security_group_ids  = [aws_security_group.eks_vpce_sg.id]
  private_dns_enabled = true

  tags = {
    Env     = "${var.creator_tag}-${terraform.workspace}",
    Name    = "${var.creator_tag}-${terraform.workspace}-secretsmanager-vpce"
    Creator = "${var.creator_tag}"
  }
}

# Security group for VPC Endpoints
resource "aws_security_group" "eks_vpce_sg" {
  name        = "${var.creator_tag}-${terraform.workspace}-vpce-sg"
  description = "Security group for VPC Endpoints"
  vpc_id      = aws_vpc.eks_vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.eks_vpc_cidr]
  }

  tags = {
    Env     = "${var.creator_tag}-${terraform.workspace}",
    Name    = "${var.creator_tag}-${terraform.workspace}-vpce-sg"
    Creator = "${var.creator_tag}"
  }
}

# Security group for public subnet
resource "aws_security_group" "eks_public_sg" {
  name   = "${var.creator_tag}-${terraform.workspace}-public-sg"
  vpc_id = aws_vpc.eks_vpc.id

  tags = {
    Env     = "${var.creator_tag}-${terraform.workspace}",
    Name    = "${var.creator_tag}-${terraform.workspace}-public-sg"
    Creator = "${var.creator_tag}"
  }
}

# Security group rules for public subnet
resource "aws_security_group_rule" "eks_sg_ingress_public_443" {
  security_group_id = aws_security_group.eks_public_sg.id
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = var.authorized_networks[*].cidr_block
}

resource "aws_security_group_rule" "eks_sg_ingress_public_80" {
  security_group_id = aws_security_group.eks_public_sg.id
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = var.authorized_networks[*].cidr_block
}

resource "aws_security_group_rule" "eks_sg_egress_public" {
  security_group_id = aws_security_group.eks_public_sg.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

# Security group for the data plane
resource "aws_security_group" "eks_data_plane_sg" {
  name   = "${var.creator_tag}-${terraform.workspace}-data-plane-sg"
  vpc_id = aws_vpc.eks_vpc.id

  tags = {
    Env     = "${var.creator_tag}-${terraform.workspace}",
    Name    = "${var.creator_tag}-${terraform.workspace}-data-plane-sg"
    Creator = "${var.creator_tag}"
  }
}

# Security group rules for the data plane
resource "aws_security_group_rule" "eks_nodes" {
  description       = "Allow nodes to communicate with each other"
  security_group_id = aws_security_group.eks_data_plane_sg.id
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  cidr_blocks       = flatten([var.eks_public_subnet_cidrs, var.eks_private_subnet_cidrs])
}

resource "aws_security_group_rule" "eks_nodes_inbound" {
  description       = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  security_group_id = aws_security_group.eks_data_plane_sg.id
  type              = "ingress"
  from_port         = 1025
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = var.eks_private_subnet_cidrs
}

resource "aws_security_group_rule" "eks_node_outbound" {
  security_group_id = aws_security_group.eks_data_plane_sg.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

# Security group for the control plane
resource "aws_security_group" "eks_control_plane_sg" {
  name   = "${var.creator_tag}-${terraform.workspace}-control-plane-sg"
  vpc_id = aws_vpc.eks_vpc.id

  tags = {
    Env     = "${var.creator_tag}-${terraform.workspace}",
    Name    = "${var.creator_tag}-${terraform.workspace}-control-plane-sg"
    Creator = "${var.creator_tag}"
  }
}

# Security group rules for the control plane
resource "aws_security_group_rule" "eks_control_plane_inbound" {
  security_group_id = aws_security_group.eks_control_plane_sg.id
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = flatten([var.eks_public_subnet_cidrs, var.eks_private_subnet_cidrs])
}

resource "aws_security_group_rule" "eks_control_plane_outbound" {
  security_group_id = aws_security_group.eks_control_plane_sg.id
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}
