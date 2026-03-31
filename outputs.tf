output "cluster_arn" {
  description = "ARN of ECS cluster."
  value       = aws_ecs_cluster.this.arn
}

output "cluster_name" {
  description = "Name of ECS cluster."
  value       = aws_ecs_cluster.this.name
}

output "service_arn" {
  description = "ARN of ECS service."
  value       = aws_ecs_service.this.id
}

output "service_name" {
  description = "Name of ECS service."
  value       = aws_ecs_service.this.name
}

output "task_definition_arn" {
  description = "Task definition ARN used by ECS service."
  value       = aws_ecs_task_definition.this.arn
}

output "task_definition_family" {
  description = "Task definition family."
  value       = aws_ecs_task_definition.this.family
}

output "security_group_id" {
  description = "Created service security group ID when create_security_group is enabled."
  value       = var.create_security_group ? aws_security_group.service[0].id : null
}

output "load_balancer_arn" {
  description = "ALB ARN when load balancer is enabled."
  value       = local.effective_create_load_balancer ? aws_lb.this[0].arn : null
}

output "alb_dns_name" {
  description = "ALB DNS name when load balancer is enabled."
  value       = local.effective_create_load_balancer ? aws_lb.this[0].dns_name : null
}

output "target_group_arn" {
  description = "Target group ARN used by the ECS service (module-created TG or external target_group_arn)."
  value = local.attach_to_load_balancer ? (
    local.has_external_target_group ? trimspace(var.target_group_arn) : aws_lb_target_group.this[0].arn
  ) : null
}

output "log_group_name" {
  description = "CloudWatch log group name for ECS container logs."
  value       = aws_cloudwatch_log_group.this.name
}

output "effective_create_load_balancer" {
  description = "Effective flag for load balancer creation based on deployment mode."
  value       = local.effective_create_load_balancer
}

output "effective_create_service_autoscaling" {
  description = "Effective flag for autoscaling enablement based on deployment mode."
  value       = local.effective_create_service_scaling
}

output "effective_attach_to_load_balancer" {
  description = "True when the service registers targets in a load balancer (internal ALB or external target group)."
  value       = local.attach_to_load_balancer
}

output "effective_external_target_group" {
  description = "True when target_group_arn is set and the service uses an external target group."
  value       = local.has_external_target_group
}
