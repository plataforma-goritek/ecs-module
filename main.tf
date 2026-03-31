data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

locals {
  effective_create_load_balancer   = var.create_load_balancer || var.deployment_mode == "production"
  effective_create_service_scaling = var.create_service_autoscaling || var.deployment_mode == "production"

  has_external_target_group = var.target_group_arn != null && trimspace(var.target_group_arn) != ""
  attach_to_load_balancer   = local.effective_create_load_balancer || local.has_external_target_group

  common_tags = merge(
    {
      Name       = var.name
      Module     = "ecs-module"
      ManagedBy  = "terraform"
      Deployment = var.deployment_mode
    },
    var.tags
  )

  ingress_sg_rules = {
    for idx, sg_id in var.allowed_security_group_ids : "sg-${idx}" => {
      type                     = "sg"
      source_security_group_id = sg_id
      cidr_ipv4                = null
    }
  }

  ingress_cidr_rules = {
    for idx, cidr in var.allowed_cidr_blocks : "cidr-${idx}" => {
      type                     = "cidr"
      source_security_group_id = null
      cidr_ipv4                = cidr
    }
  }

  ingress_rules = merge(local.ingress_sg_rules, local.ingress_cidr_rules)

  task_security_group_ids = concat(
    var.security_group_ids,
    var.create_security_group ? [aws_security_group.service[0].id] : []
  )

  environment_list = [
    for k, v in var.environment : {
      name  = k
      value = v
    }
  ]

  secrets_list = [
    for k, v in var.secrets : {
      name      = k
      valueFrom = v
    }
  ]
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${var.name}"
  retention_in_days = var.log_retention_in_days
  kms_key_id        = var.log_kms_key_id
  tags              = local.common_tags
}

resource "aws_ecs_cluster" "this" {
  name = var.name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = local.common_tags
}

resource "aws_security_group" "service" {
  count       = var.create_security_group ? 1 : 0
  name        = "${var.name}-svc-sg"
  description = "Security group for ECS service ${var.name}"
  vpc_id      = var.vpc_id
  tags        = local.common_tags
}

resource "aws_vpc_security_group_egress_rule" "service_all" {
  count             = var.create_security_group ? 1 : 0
  security_group_id = aws_security_group.service[0].id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "service" {
  for_each = var.create_security_group ? local.ingress_rules : {}

  security_group_id            = aws_security_group.service[0].id
  from_port                    = var.container_port
  to_port                      = var.container_port
  ip_protocol                  = "tcp"
  cidr_ipv4                    = each.value.cidr_ipv4
  referenced_security_group_id = each.value.source_security_group_id
}

resource "aws_lb" "this" {
  count              = local.effective_create_load_balancer ? 1 : 0
  name               = substr("${var.name}-alb", 0, 32)
  internal           = var.alb_internal
  load_balancer_type = "application"
  subnets            = var.load_balancer_subnet_ids
  security_groups    = local.task_security_group_ids
  tags               = local.common_tags
}

resource "aws_lb_target_group" "this" {
  count                = local.effective_create_load_balancer ? 1 : 0
  name                 = substr("${var.name}-tg", 0, 32)
  port                 = var.container_port
  protocol             = "HTTP"
  target_type          = "ip"
  vpc_id               = var.vpc_id
  deregistration_delay = var.target_group_deregistration_delay

  health_check {
    enabled             = true
    path                = var.health_check_path
    protocol            = "HTTP"
    matcher             = var.health_check_matcher
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = local.common_tags
}

resource "aws_lb_listener" "this" {
  count             = local.effective_create_load_balancer ? 1 : 0
  load_balancer_arn = aws_lb.this[0].arn
  port              = var.listener_port
  protocol          = var.listener_protocol
  certificate_arn   = var.listener_protocol == "HTTPS" ? var.certificate_arn : null

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[0].arn
  }

  tags = local.common_tags
}

resource "aws_ecs_task_definition" "this" {
  family                   = var.name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = tostring(var.task_cpu)
  memory                   = tostring(var.task_memory)
  execution_role_arn       = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ecsTaskExecutionRole"
  container_definitions = jsonencode([
    {
      name      = var.container_name
      image     = var.container_image
      essential = true
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]
      environment = local.environment_list
      secrets     = local.secrets_list
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.this.name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = var.container_name
        }
      }
      readonlyRootFilesystem = true
    }
  ])

  dynamic "ephemeral_storage" {
    for_each = var.task_ephemeral_storage_gib == null ? [] : [1]

    content {
      size_in_gib = var.task_ephemeral_storage_gib
    }
  }

  tags = local.common_tags
}

resource "aws_ecs_service" "this" {
  name                               = var.name
  cluster                            = aws_ecs_cluster.this.id
  task_definition                    = aws_ecs_task_definition.this.arn
  desired_count                      = var.desired_count
  launch_type                        = "FARGATE"
  platform_version                   = var.platform_version
  enable_execute_command             = var.enable_execute_command
  health_check_grace_period_seconds  = local.attach_to_load_balancer ? var.health_check_grace_period_seconds : null
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  deployment_maximum_percent         = var.deployment_maximum_percent

  network_configuration {
    subnets          = var.subnet_ids
    assign_public_ip = var.assign_public_ip
    security_groups  = local.task_security_group_ids
  }

  dynamic "load_balancer" {
    for_each = local.attach_to_load_balancer ? [1] : []

    content {
      target_group_arn = local.has_external_target_group ? trimspace(var.target_group_arn) : aws_lb_target_group.this[0].arn
      container_name   = var.container_name
      container_port   = var.container_port
    }
  }

  # Listener tem count dinâmico; referenciar o recurso (sem índice) mantém dependência válida na configuração.
  depends_on = [aws_lb_listener.this]
  tags       = local.common_tags
}

resource "aws_appautoscaling_target" "ecs" {
  count              = local.effective_create_service_scaling ? 1 : 0
  max_capacity       = var.autoscaling_max_capacity
  min_capacity       = var.autoscaling_min_capacity
  resource_id        = "service/${aws_ecs_cluster.this.name}/${aws_ecs_service.this.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "cpu" {
  count              = local.effective_create_service_scaling ? 1 : 0
  name               = "${var.name}-cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = var.autoscaling_cpu_target
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}

resource "aws_appautoscaling_policy" "memory" {
  count              = local.effective_create_service_scaling ? 1 : 0
  name               = "${var.name}-memory"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = var.autoscaling_memory_target
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}
