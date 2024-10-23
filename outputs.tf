output "vpc_id" {
  value = var.vpc_id
}

output "subnet_ids" {
  value = var.private_subnet_ids
}

output "github_instance_ids" {
  description = "IDs of the GitHub Enterprise instances"
  value       = { for k, v in aws_instance.github_instance : k => v.id }
}

output "nlb_arns" {
  description = "ARNs of the Network Load Balancers"
  value       = { for k, v in aws_lb.nlb : k => v.arn }
}

output "backup_host_id" {
  value = aws_instance.backup_host.id
}

output "route53_zone_id" {
  value = length(var.route53_zone_name) > 0 ? data.aws_route53_zone.selected["selected"].zone_id : "Zone not managed by Terraform"
}