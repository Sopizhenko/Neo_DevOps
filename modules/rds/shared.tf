# DB Subnet Group (shared for both RDS and Aurora)
resource "aws_db_subnet_group" "this" {
  name       = "${var.identifier}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(
    var.tags,
    {
      Name = "${var.identifier}-subnet-group"
    }
  )
}

# Security Group (shared for both RDS and Aurora)
resource "aws_security_group" "this" {
  name        = "${var.identifier}-db-sg"
  description = "Security group for ${var.identifier} database"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.identifier}-db-sg"
    }
  )
}

# Ingress rule for CIDR blocks
resource "aws_vpc_security_group_ingress_rule" "cidr" {
  count = length(var.allowed_cidr_blocks) > 0 ? 1 : 0

  security_group_id = aws_security_group.this.id
  description       = "Database access from CIDR blocks"
  
  cidr_ipv4   = var.allowed_cidr_blocks[0]
  from_port   = var.port
  to_port     = var.port
  ip_protocol = "tcp"

  tags = merge(
    var.tags,
    {
      Name = "${var.identifier}-cidr-ingress"
    }
  )
}

# Ingress rule for security groups
resource "aws_vpc_security_group_ingress_rule" "sg" {
  for_each = toset(var.allowed_security_group_ids)

  security_group_id = aws_security_group.this.id
  description       = "Database access from security group ${each.value}"
  
  referenced_security_group_id = each.value
  from_port                    = var.port
  to_port                      = var.port
  ip_protocol                  = "tcp"

  tags = merge(
    var.tags,
    {
      Name = "${var.identifier}-sg-ingress-${substr(each.value, 0, 8)}"
    }
  )
}

# Egress rule (allow all outbound)
resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.this.id
  description       = "Allow all outbound traffic"
  
  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"

  tags = merge(
    var.tags,
    {
      Name = "${var.identifier}-egress"
    }
  )
}

# Parameter Group for standard RDS
resource "aws_db_parameter_group" "this" {
  count = var.use_aurora ? 0 : 1

  name   = "${var.identifier}-params"
  family = var.parameter_group_family

  dynamic "parameter" {
    for_each = var.parameters
    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.identifier}-parameter-group"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Cluster Parameter Group for Aurora
resource "aws_rds_cluster_parameter_group" "this" {
  count = var.use_aurora ? 1 : 0

  name   = "${var.identifier}-cluster-params"
  family = var.parameter_group_family

  dynamic "parameter" {
    for_each = var.parameters
    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.identifier}-cluster-parameter-group"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# DB Parameter Group for Aurora instances
resource "aws_db_parameter_group" "aurora_instance" {
  count = var.use_aurora ? 1 : 0

  name   = "${var.identifier}-aurora-instance-params"
  family = var.parameter_group_family

  tags = merge(
    var.tags,
    {
      Name = "${var.identifier}-aurora-instance-parameter-group"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}
