resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = var.vpc_name
    Environment = "lesson-5"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.vpc_name}-igw"
  }
}

resource "aws_subnet" "public" {
  for_each = {
    for idx, cidr in var.public_subnets :
    idx => cidr
  }

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value
  availability_zone       = var.availability_zones[tonumber(each.key)]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.vpc_name}-public-${each.key}"
    Tier = "public"
  }
}

resource "aws_subnet" "private" {
  for_each = {
    for idx, cidr in var.private_subnets :
    idx => cidr
  }

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value
  availability_zone = var.availability_zones[tonumber(each.key)]

  tags = {
    Name = "${var.vpc_name}-private-${each.key}"
    Tier = "private"
  }
}
