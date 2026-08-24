variable "aws_region" {
  description = "AWS region for the hospital deployment"
  type        = string
  default     = "us-east-1"
}

variable "ami_id" {
  description = "AMI ID for the portal EC2 instance (Amazon Linux 2023 recommended)"
  type        = string
}

variable "key_name" {
  description = "EC2 key pair name for SSH access"
  type        = string
}

variable "env_suffix" {
  description = "Unique suffix for globally-named resources like S3 buckets"
  type        = string
  default     = "prod"
}

variable "db_username" {
  description = "Master username for the hospital database"
  type        = string
  default     = "willowcreek_admin"
  sensitive   = true
}

variable "db_password" {
  description = "Master password for the hospital database — set via TF_VAR_db_password env var, never commit"
  type        = string
  sensitive   = true
}
