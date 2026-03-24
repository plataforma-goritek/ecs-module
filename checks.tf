check "security_group_required" {
  assert {
    condition     = var.create_security_group || length(var.security_group_ids) > 0
    error_message = "When create_security_group is false, at least one security_group_ids must be provided."
  }
}

check "security_group_ingress_required" {
  assert {
    condition     = !var.create_security_group || length(var.allowed_security_group_ids) > 0 || length(var.allowed_cidr_blocks) > 0 || (var.create_load_balancer || var.deployment_mode == "production")
    error_message = "When create_security_group is true, provide allowed_security_group_ids or allowed_cidr_blocks, unless traffic comes from an ALB in this module."
  }
}

check "https_requires_certificate" {
  assert {
    condition     = var.listener_protocol != "HTTPS" || var.certificate_arn != null
    error_message = "certificate_arn is required when listener_protocol is HTTPS."
  }
}

check "alb_subnets_required" {
  assert {
    condition     = !(var.create_load_balancer || var.deployment_mode == "production") || length(var.load_balancer_subnet_ids) > 1
    error_message = "load_balancer_subnet_ids must contain at least two subnets when load balancer is enabled."
  }
}

check "autoscaling_limits" {
  assert {
    condition     = var.autoscaling_min_capacity >= 1 && var.autoscaling_max_capacity >= var.autoscaling_min_capacity
    error_message = "autoscaling_max_capacity must be >= autoscaling_min_capacity and autoscaling_min_capacity must be >= 1."
  }
}
