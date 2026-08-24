terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ---------------------------------------------------------
# VPC — isolated network for the hospital, spans 2 AZs for HA
# ---------------------------------------------------------
resource "aws_vpc" "hospital_vpc" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "willow-creek-vpc" }
}

# Public subnets — only the front-facing portal lives here
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.hospital_vpc.id
  cidr_block              = "10.20.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
  tags = { Name = "willow-creek-public-a" }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.hospital_vpc.id
  cidr_block              = "10.20.2.0/24"
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true
  tags = { Name = "willow-creek-public-b" }
}

# Private subnets — database, EHR systems, PHI storage. No public route.
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.hospital_vpc.id
  cidr_block        = "10.20.10.0/24"
  availability_zone = "${var.aws_region}a"
  tags = { Name = "willow-creek-private-a" }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.hospital_vpc.id
  cidr_block        = "10.20.11.0/24"
  availability_zone = "${var.aws_region}b"
  tags = { Name = "willow-creek-private-b" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.hospital_vpc.id
  tags = { Name = "willow-creek-igw" }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.hospital_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "willow-creek-public-rt" }
}

resource "aws_route_table_association" "public_a_assoc" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_b_assoc" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public_rt.id
}

# ---------------------------------------------------------
# Security groups — least privilege
# ---------------------------------------------------------
resource "aws_security_group" "portal_sg" {
  name        = "willow-creek-portal-sg"
  description = "Public-facing staff/department portal — HTTP/HTTPS + SSH only"
  vpc_id      = aws_vpc.hospital_vpc.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP (redirect to HTTPS)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH (restrict to admin IP in production)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "willow-creek-portal-sg" }
}

# Database security group — ONLY accepts traffic from the portal SG, nothing public
resource "aws_security_group" "db_sg" {
  name        = "willow-creek-db-sg"
  description = "Private database tier — PHI storage, no public access"
  vpc_id      = aws_vpc.hospital_vpc.id

  ingress {
    description     = "Postgres from portal app only"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.portal_sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "willow-creek-db-sg" }
}

# ---------------------------------------------------------
# KMS key — encrypts data at rest (RDS, EBS, S3)
# ---------------------------------------------------------
resource "aws_kms_key" "hospital_key" {
  description             = "Encryption key for Willow Creek PHI-adjacent data at rest"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  tags = { Name = "willow-creek-kms" }
}

# ---------------------------------------------------------
# S3 — encrypted document storage (policies, forms, NOT live patient records)
# ---------------------------------------------------------
resource "aws_s3_bucket" "hospital_docs" {
  bucket = "willow-creek-hospital-docs-${var.env_suffix}"
  tags = { Name = "willow-creek-docs" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "docs_encryption" {
  bucket = aws_s3_bucket.hospital_docs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.hospital_key.arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "docs_block" {
  bucket                  = aws_s3_bucket.hospital_docs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ---------------------------------------------------------
# EC2 — the portal application server (public subnet)
# ---------------------------------------------------------
resource "aws_instance" "portal_server" {
  ami                    = var.ami_id
  instance_type          = "t3.small"
  key_name               = var.key_name
  subnet_id              = aws_subnet.public_a.id
  vpc_security_group_ids = [aws_security_group.portal_sg.id]
  tags = { Name = "willow-creek-portal" }
}

# ---------------------------------------------------------
# RDS Postgres — private, encrypted, Multi-AZ for hospital uptime
# ---------------------------------------------------------
resource "aws_db_subnet_group" "hospital_db_subnets" {
  name       = "willow-creek-db-subnets"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]
}

resource "aws_db_instance" "hospital_db" {
  identifier             = "willow-creek-db"
  engine                 = "postgres"
  engine_version         = "16"
  instance_class         = "db.t3.medium"
  allocated_storage      = 50
  storage_encrypted      = true
  kms_key_id             = aws_kms_key.hospital_key.arn
  db_name                = "willowcreek"
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.hospital_db_subnets.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  multi_az               = true
  publicly_accessible    = false
  backup_retention_period = 14
  skip_final_snapshot    = false
  final_snapshot_identifier = "willow-creek-db-final"
  tags = { Name = "willow-creek-db" }
}

# ---------------------------------------------------------
# CloudTrail — audit logging (who accessed what, when — HIPAA requirement)
# ---------------------------------------------------------
resource "aws_cloudtrail" "hospital_audit_trail" {
  name                          = "willow-creek-audit-trail"
  s3_bucket_name                = aws_s3_bucket.hospital_docs.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
}
