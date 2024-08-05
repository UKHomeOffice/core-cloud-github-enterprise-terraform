variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC"
  type        = string
}

variable "key_name" {
  description = "CIDR block of the VPC"
  type        = string
}

variable "allowed_cidr_ingress" {
  description = "CIDR blocks allowed for ingress"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs"
  type        = list(string)
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

variable "ami_id" {
  description = "AMI ID for GitHub Enterprise instances"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for GitHub Enterprise instances"
  type        = string
  default     = "r5.2xlarge"
}

variable "backup_host_ami_id" {
  description = "AMI ID for the backup host"
  type        = string
}

variable "backup_host_instance_type" {
  description = "EC2 instance type for the backup host"
  type        = string
  default     = "m5.2xlarge"
}

variable "port_to_name_map" {
  description = "Map of ports corresponding to target group names to enable key:value reference"
  type        = map(string)
  default = {
    "80"   = "github-http",
    "443"  = "github-https",
    "22"   = "github-ssh",
    "8080" = "github-management-http",
    "25"   = "github-smtp",
    "8443" = "github-management-https",
  }
}

variable "github_backup_image" {
  description = "Docker image for GitHub backup"
  type        = string
}

variable "quay_username" {
  description = "Quay username"
  type        = string
  sensitive   = true
}

variable "quay_password" {
  description = "Quay password"
  type        = string
  sensitive   = true
}

variable "ghe_hostname" {
  description = "GitHub Enterprise hostname"
  type        = string
}

variable "aws_access_key_id" {
  description = "AWS access key ID"
  type        = string
  sensitive   = true
}

variable "aws_secret_access_key" {
  description = "AWS secret access key"
  type        = string
  sensitive   = true
}

variable "s3_bucket" {
  description = "S3 bucket for backup"
  type        = string
}

variable "route53_zone_name" {
  description = "Route53 zone name"
  type        = string
}

variable "route53_record_name" {
  description = "Route53 record name"
  type        = string
}

variable "primary_weight" {
  description = "Weight for the primary instance"
  type        = number
  default     = 100
}

variable "secondary_weight" {
  description = "Weight for the secondary instance"
  type        = number
  default     = 0
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
}

variable "ebs_volume_size" {
  description = "EBS volume size in GB"
  type        = number
}

variable "backup_root_volume_size" {
  description = "Backup host root volume size in GB"
  type        = number
}

variable "ssh_private_key" {
  description = "SSH private key for accessing GitHub Enterprise Server from the backup host"
  type        = string
  sensitive   = true
}