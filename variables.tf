variable "name" {
  description = "Base name used to identify ECS resources."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]{1,30}$", var.name))
    error_message = "name must start with a letter and contain only letters, numbers and hyphens (2-31 chars)."
  }
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}

variable "deployment_mode" {
  description = "Deployment profile for effective defaults. Allowed values: simple, production."
  type        = string
  default     = "simple"

  validation {
    condition     = contains(["simple", "production"], var.deployment_mode)
    error_message = "deployment_mode must be one of: simple, production."
  }
}

variable "vpc_id" {
  description = "VPC ID used by security group and optional load balancer."
  type        = string

  validation {
    condition     = can(regex("^vpc-[a-z0-9]+$", var.vpc_id))
    error_message = "vpc_id must be a valid VPC ID (vpc-xxxx)."
  }
}

variable "subnet_ids" {
  description = "Subnets where ECS tasks run."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) > 0
    error_message = "subnet_ids must contain at least one subnet."
  }
}

variable "assign_public_ip" {
  description = "Assign public IP to tasks."
  type        = bool
  default     = false
}

variable "enable_execute_command" {
  description = "Enable ECS Exec in service."
  type        = bool
  default     = false
}

variable "container_name" {
  description = "Container name used in the task definition."
  type        = string
  default     = "app"
}

variable "container_image" {
  description = "Container image URI."
  type        = string
}

variable "container_port" {
  description = "Application container port."
  type        = number
  default     = 8080

  validation {
    condition     = var.container_port >= 1 && var.container_port <= 65535
    error_message = "container_port must be between 1 and 65535."
  }
}

variable "task_cpu" {
  description = "Task CPU units. Example: 256, 512, 1024."
  type        = number
  default     = 512

  validation {
    condition     = var.task_cpu >= 256
    error_message = "task_cpu must be >= 256 for Fargate."
  }
}

variable "task_memory" {
  description = "Task memory in MiB. Example: 512, 1024, 2048."
  type        = number
  default     = 1024

  validation {
    condition     = var.task_memory >= 512
    error_message = "task_memory must be >= 512 for Fargate."
  }
}

variable "task_ephemeral_storage_gib" {
  description = "Ephemeral storage size in GiB for task. Set null to use AWS default."
  type        = number
  default     = null

  validation {
    condition     = var.task_ephemeral_storage_gib == null ? true : (var.task_ephemeral_storage_gib >= 21 && var.task_ephemeral_storage_gib <= 200)
    error_message = "task_ephemeral_storage_gib must be null or between 21 and 200."
  }
}

variable "desired_count" {
  description = "Desired number of running tasks."
  type        = number
  default     = 1

  validation {
    condition     = var.desired_count >= 1
    error_message = "desired_count must be >= 1."
  }
}

variable "health_check_grace_period_seconds" {
  description = "Grace period for service health checks."
  type        = number
  default     = 60

  validation {
    condition     = var.health_check_grace_period_seconds >= 0 && var.health_check_grace_period_seconds <= 2147483647
    error_message = "health_check_grace_period_seconds must be between 0 and 2147483647."
  }
}

variable "deployment_minimum_healthy_percent" {
  description = "Lower limit (% of desired_count) of healthy tasks during deployment."
  type        = number
  default     = 50

  validation {
    condition     = var.deployment_minimum_healthy_percent >= 0 && var.deployment_minimum_healthy_percent <= 100
    error_message = "deployment_minimum_healthy_percent must be between 0 and 100."
  }
}

variable "deployment_maximum_percent" {
  description = "Upper limit (% of desired_count) of tasks during deployment."
  type        = number
  default     = 200

  validation {
    condition     = var.deployment_maximum_percent >= 100 && var.deployment_maximum_percent <= 200
    error_message = "deployment_maximum_percent must be between 100 and 200."
  }
}

variable "platform_version" {
  description = "Fargate platform version."
  type        = string
  default     = "LATEST"
}

variable "create_security_group" {
  description = "Whether to create a dedicated security group for ECS tasks."
  type        = bool
  default     = true
}

variable "fargate_sg_delete_delay_seconds" {
  description = "Seconds to wait on destroy before deleting the service security group, allowing Fargate ENIs to be released. Workaround for AWS provider DependencyViolation when SG is deleted while task ENIs are still attached."
  type        = number
  default     = 300

  validation {
    condition     = var.fargate_sg_delete_delay_seconds >= 0 && var.fargate_sg_delete_delay_seconds <= 1800
    error_message = "fargate_sg_delete_delay_seconds must be between 0 and 1800."
  }
}

variable "execution_role_arn" {
  description = "IAM role ARN used by ECS to pull images and write logs. When null, falls back to arn:aws:iam::<current-account>:role/ecsTaskExecutionRole."
  type        = string
  default     = null
}

variable "task_role_arn" {
  description = "IAM role ARN assumed by the container (task role). Optional."
  type        = string
  default     = null
}

variable "security_group_ids" {
  description = "Additional security group IDs attached to ECS tasks."
  type        = list(string)
  default     = []
}

variable "allowed_security_group_ids" {
  description = "Security groups allowed ingress to the application port when create_security_group is true."
  type        = list(string)
  default     = []
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed ingress to the application port when create_security_group is true."
  type        = list(string)
  default     = []
}

variable "create_load_balancer" {
  description = "Create an Application Load Balancer and attach the service."
  type        = bool
  default     = false
}

variable "target_group_arn" {
  description = "ARN of an existing target group (ALB outside the module). Attaches the ECS service to this target group."
  type        = string
  default     = null
}

variable "load_balancer_subnet_ids" {
  description = "Subnets for ALB. Required when create_load_balancer is true."
  type        = list(string)
  default     = []
}

variable "alb_internal" {
  description = "Whether ALB is internal."
  type        = bool
  default     = true
}

variable "listener_port" {
  description = "ALB listener port."
  type        = number
  default     = 80

  validation {
    condition     = var.listener_port >= 1 && var.listener_port <= 65535
    error_message = "listener_port must be between 1 and 65535."
  }
}

variable "listener_protocol" {
  description = "ALB listener protocol. Allowed values: HTTP, HTTPS."
  type        = string
  default     = "HTTP"

  validation {
    condition     = contains(["HTTP", "HTTPS"], var.listener_protocol)
    error_message = "listener_protocol must be HTTP or HTTPS."
  }
}

variable "certificate_arn" {
  description = "ACM certificate ARN required when listener_protocol is HTTPS."
  type        = string
  default     = null
}

variable "health_check_path" {
  description = "Target group health check path."
  type        = string
  default     = "/health"
}

variable "health_check_matcher" {
  description = "HTTP codes considered healthy by target group."
  type        = string
  default     = "200-399"
}

variable "target_group_deregistration_delay" {
  description = "Target group deregistration delay in seconds."
  type        = number
  default     = 30

  validation {
    condition     = var.target_group_deregistration_delay >= 0 && var.target_group_deregistration_delay <= 3600
    error_message = "target_group_deregistration_delay must be between 0 and 3600."
  }
}

variable "log_retention_in_days" {
  description = "CloudWatch log retention in days."
  type        = number
  default     = 30

  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653
    ], var.log_retention_in_days)
    error_message = "log_retention_in_days must be a valid CloudWatch Logs retention value."
  }
}

variable "log_kms_key_id" {
  description = "KMS key ID/ARN for CloudWatch log group encryption."
  type        = string
  default     = null
}

variable "secrets" {
  description = "Map of environment variable name to Secrets Manager ARN/parameter reference."
  type        = map(string)
  default     = {}
}

variable "environment" {
  description = "Map of plain environment variables for container."
  type        = map(string)
  default     = {}
}

variable "create_service_autoscaling" {
  description = "Enable ECS service autoscaling policies."
  type        = bool
  default     = false
}

variable "autoscaling_min_capacity" {
  description = "Minimum number of tasks for autoscaling."
  type        = number
  default     = 1
}

variable "autoscaling_max_capacity" {
  description = "Maximum number of tasks for autoscaling."
  type        = number
  default     = 4
}

variable "autoscaling_cpu_target" {
  description = "Target CPU utilization percentage for autoscaling."
  type        = number
  default     = 70

  validation {
    condition     = var.autoscaling_cpu_target >= 10 && var.autoscaling_cpu_target <= 90
    error_message = "autoscaling_cpu_target must be between 10 and 90."
  }
}

variable "autoscaling_memory_target" {
  description = "Target memory utilization percentage for autoscaling."
  type        = number
  default     = 75

  validation {
    condition     = var.autoscaling_memory_target >= 10 && var.autoscaling_memory_target <= 90
    error_message = "autoscaling_memory_target must be between 10 and 90."
  }
}
