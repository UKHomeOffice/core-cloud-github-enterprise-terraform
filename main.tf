# IAM Role and Policies for SSM
resource "aws_iam_role" "ssm_role" {
  name = "github-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_instance_profile" {
  name = "github-ssm-instance-profile"
  role = aws_iam_role.ssm_role.name
}

# Security Groups for NLBs
resource "aws_security_group" "nlb_sg" {
  for_each    = { "1" = "nlb1", "2" = "nlb2" }
  name        = "github-enterprise-nlb-sg-${each.key}"
  description = "Security group for Github Enterprise Server NLB ${each.value}"
  vpc_id      = var.vpc_id

  tags = {
    Name = "github-enterprise-nlb-sg-${each.key}"
  }
}

# Ingress rules for NLB security groups
resource "aws_vpc_security_group_ingress_rule" "nlb_ingress_rule" {
  for_each = {
    for pair in setproduct(keys(aws_security_group.nlb_sg), keys(var.port_to_name_map)) : 
    "${pair[0]}-${pair[1]}" => {
      sg_key = pair[0]
      port   = pair[1]
    }
  }

  security_group_id = aws_security_group.nlb_sg[each.value.sg_key].id
  from_port         = tonumber(each.value.port)
  to_port           = tonumber(each.value.port)
  ip_protocol       = "tcp"
  cidr_ipv4         = var.allowed_cidr_ingress
}

resource "aws_vpc_security_group_ingress_rule" "nlb_all_traffic_ingress" {
  for_each          = aws_security_group.nlb_sg
  security_group_id = each.value.id
  ip_protocol       = "-1"
  cidr_ipv4         = var.vpc_cidr
}

# Egress rules for NLB security groups
resource "aws_vpc_security_group_egress_rule" "nlb_sg_outbound" {
  for_each          = aws_security_group.nlb_sg
  security_group_id = each.value.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# Load Balancers
resource "aws_lb" "nlb" {
  for_each          = aws_security_group.nlb_sg
  name              = "github-enterprise-nlb-${each.key}"
  internal          = true
  load_balancer_type = "network"
  subnets           = var.subnet_ids
  security_groups   = [each.value.id]

  tags = {
    Name = "github-enterprise-nlb-${each.key}"
  }
}

# Target Groups
resource "aws_lb_target_group" "tg" {
  for_each = {
    for pair in setproduct(keys(aws_lb.nlb), keys(var.port_to_name_map)) : 
    "${pair[0]}-${pair[1]}" => {
      nlb_key = pair[0]
      port    = pair[1]
    }
  }

  name     = "tg-${each.value.nlb_key}-${var.port_to_name_map[each.value.port]}"
  port     = tonumber(each.value.port)
  protocol = "TCP"
  vpc_id   = var.vpc_id

  health_check {
    protocol = "TCP"
    port     = "traffic-port"
  }

  tags = {
    Name = "tg-${each.value.nlb_key}-${var.port_to_name_map[each.value.port]}"
  }
}

resource "aws_lb_listener" "nlb_listener" {
  for_each = {
    for pair in setproduct(keys(aws_lb.nlb), keys(var.port_to_name_map)) : 
    "${pair[0]}-${pair[1]}" => {
      nlb_key = pair[0]
      port    = pair[1]
    }
  }

  load_balancer_arn = aws_lb.nlb[each.value.nlb_key].arn
  protocol          = "TCP"
  port              = tonumber(each.value.port)

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg["${each.value.nlb_key}-${each.value.port}"].arn
  }
}

# Target Group Attachments
resource "aws_lb_target_group_attachment" "tg_attachment" {
  for_each = {
    for pair in setproduct(keys(aws_lb.nlb), keys(var.port_to_name_map)) : 
    "${pair[0]}-${pair[1]}" => {
      nlb_key = pair[0]
      port    = pair[1]
    }
  }

  target_group_arn = aws_lb_target_group.tg["${each.value.nlb_key}-${each.value.port}"].arn
  target_id        = aws_instance.github_instance[each.value.nlb_key].id
  port             = tonumber(each.value.port)
}

# Security Groups for GitHub Enterprise Servers
resource "aws_security_group" "github_sg" {
  for_each = { "1" = "primary", "2" = "secondary" }
  name        = "github-enterprise-server-sg-${each.key}"
  description = "Security group for GitHub Server ${each.value}"
  vpc_id      = var.vpc_id

  tags = {
    Name = "github-enterprise-server-sg-${each.key}"
  }
}

# Ingress rules for GitHub Enterprise Servers security groups
resource "aws_vpc_security_group_ingress_rule" "github_ingress_rules" {
  for_each = {
    for pair in setproduct(["1", "2"], keys(var.port_to_name_map)) : 
    "${pair[0]}-${pair[1]}" => {
      instance_num = pair[0]
      port         = pair[1]
    }
  }

  security_group_id            = aws_security_group.github_sg[each.value.instance_num].id
  from_port                    = tonumber(each.value.port)
  to_port                      = tonumber(each.value.port)
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.nlb_sg[each.value.instance_num].id
}

resource "aws_vpc_security_group_ingress_rule" "primary_allow_tcp_from_secondary_ha" {
  security_group_id            = aws_security_group.github_sg["1"].id
  from_port                    = 122
  to_port                      = 122
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.github_sg["2"].id
}

resource "aws_vpc_security_group_ingress_rule" "secondary_allow_tcp_from_primary_ha" {
  security_group_id            = aws_security_group.github_sg["2"].id
  from_port                    = 122
  to_port                      = 122
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.github_sg["1"].id
}

resource "aws_vpc_security_group_ingress_rule" "primary_allow_udp_from_secondary_ha" {
  security_group_id            = aws_security_group.github_sg["1"].id
  from_port                    = 1194
  to_port                      = 1194
  ip_protocol                  = "udp"
  referenced_security_group_id = aws_security_group.github_sg["2"].id
}

resource "aws_vpc_security_group_ingress_rule" "secondary_allow_udp_from_primary_ha" {
  security_group_id            = aws_security_group.github_sg["2"].id
  from_port                    = 1194
  to_port                      = 1194
  ip_protocol                  = "udp"
  referenced_security_group_id = aws_security_group.github_sg["1"].id
}

# Egress rules for GitHub Enterprise Servers security groups
resource "aws_vpc_security_group_egress_rule" "sg_outbound" {
  for_each          = aws_security_group.github_sg
  security_group_id = each.value.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# EC2 Instances
resource "aws_instance" "github_instance" {
  for_each              = aws_security_group.github_sg
  ami                   = var.ami_id
  instance_type         = var.instance_type
  key_name              = var.key_name 
  subnet_id             = element(var.subnet_ids, tonumber(each.key) - 1)
  vpc_security_group_ids = [each.value.id]

  iam_instance_profile = aws_iam_instance_profile.ssm_instance_profile.name

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    delete_on_termination = false
    encrypted             = true
  }

  ebs_block_device {
    device_name           = "/dev/sdb"
    volume_size           = var.ebs_volume_size
    volume_type           = "gp3"
    delete_on_termination = false
    encrypted             = true
  }

  tags = {
    Name = "github-enterprise-server-${each.key}"
  }
}

# Backup Host Security Group
resource "aws_security_group" "backup_host_sg" {
  name        = "github-backup-host-sg"
  description = "Security group for the backup host"
  vpc_id      = var.vpc_id

  tags = {
    Name = "github-backup-host-sg"
  }
}

# Outbound rules for Backup Host Security Group
resource "aws_vpc_security_group_egress_rule" "backup_host_egress_rule" {
  security_group_id = aws_security_group.backup_host_sg.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# Backup Host Instance
resource "aws_instance" "backup_host" {
  ami                    = var.backup_host_ami_id
  instance_type          = var.backup_host_instance_type
  subnet_id              = element(var.subnet_ids, 0)
  vpc_security_group_ids = [aws_security_group.backup_host_sg.id]
  key_name               = var.key_name

  iam_instance_profile = aws_iam_instance_profile.ssm_instance_profile.name

  root_block_device {
    volume_size = var.backup_root_volume_size
    volume_type = "gp3"
    encrypted   = true
  }

  user_data = templatefile("${path.module}/user_data.sh", {
    github_backup_image   = var.github_backup_image,
    quay_username         = var.quay_username,
    quay_password         = var.quay_password,
    ghe_hostname          = var.ghe_hostname,
    aws_access_key_id     = var.aws_access_key_id,
    aws_secret_access_key = var.aws_secret_access_key,
    s3_bucket             = var.s3_bucket,
    ssh_private_key       = var.ssh_private_key
  })

  tags = {
    Name = "github-backup-host"
  }
}

# Route53
data "aws_route53_zone" "selected" {
  name         = var.route53_zone_name
  private_zone = false
}

# Route53 A Records
resource "aws_route53_record" "github_a_record" {
  for_each = aws_lb.nlb

  zone_id = data.aws_route53_zone.selected.zone_id
  name    = var.route53_record_name
  type    = "A"

  weighted_routing_policy {
    weight = each.key == "1" ? var.primary_weight : var.secondary_weight
  }

  set_identifier = "github-server-${each.key}"

  alias {
    name                   = each.value.dns_name
    zone_id                = each.value.zone_id
    evaluate_target_health = false
  }
}

# Route53 Wildcard Records
resource "aws_route53_record" "github_wildcard_record" {
  for_each = aws_lb.nlb

  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "*.${var.route53_record_name}"
  type    = "A"

  weighted_routing_policy {
    weight = each.key == "1" ? var.primary_weight : var.secondary_weight
  }

  set_identifier = "github-wildcard-${each.key}"

  alias {
    name                   = each.value.dns_name
    zone_id                = each.value.zone_id
    evaluate_target_health = false
  }
}
