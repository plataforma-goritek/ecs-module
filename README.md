# Terraform AWS ECS Module (Full Stack Fargate)

Modulo Terraform para provisionar stack ECS completa em Fargate com foco em reuso, seguranca por padrao e interface clara para consumidores.

## O que este modulo cria

- `aws_ecs_cluster`
- `aws_ecs_task_definition`
- `aws_ecs_service`
- `aws_cloudwatch_log_group`
- `aws_security_group` (opcional)
- `aws_lb`, `aws_lb_listener`, `aws_lb_target_group` (opcionais)
- `aws_appautoscaling_target` e `aws_appautoscaling_policy` (opcionais)

## Requisitos

- Terraform `>= 1.5.0`
- Provider AWS `>= 5.0`

## Exemplo simples

```hcl
module "ecs" {
  source = "git::https://github.com/your-org/ecs-module.git?ref=v1.0.0"

  name            = "my-ecs-simple"
  deployment_mode = "simple"
  vpc_id          = "vpc-1234567890abcdef0"
  subnet_ids      = ["subnet-aaa", "subnet-bbb"]

  container_image = "nginx:1.27"
  container_port  = 8080

  create_security_group = true
  allowed_cidr_blocks   = ["10.0.0.0/16"]
}
```

Exemplo completo em `examples/simple/main.tf`.

## Exemplo de producao segura

```hcl
module "ecs" {
  source = "git::https://github.com/your-org/ecs-module.git?ref=v1.0.0"

  name            = "my-ecs-prod"
  deployment_mode = "production"
  vpc_id          = "vpc-1234567890abcdef0"
  subnet_ids      = ["subnet-aaa", "subnet-bbb"]

  container_image = "public.ecr.aws/nginx/nginx:stable"
  container_port  = 8080
  desired_count   = 2

  create_load_balancer     = true
  load_balancer_subnet_ids = ["subnet-ccc", "subnet-ddd"]

  create_service_autoscaling = true
  autoscaling_min_capacity   = 2
  autoscaling_max_capacity   = 8
}
```

Exemplo completo em `examples/production/main.tf`.

## Variaveis principais

| Variavel | Tipo | Default | Descricao |
| --- | --- | --- | --- |
| `name` | `string` | n/a | Nome base dos recursos ECS. |
| `deployment_mode` | `string` | `"simple"` | Perfil de deploy (`simple` ou `production`). |
| `vpc_id` | `string` | n/a | VPC do servico e do ALB opcional. |
| `subnet_ids` | `list(string)` | n/a | Subnets para tarefas ECS. |
| `container_image` | `string` | n/a | Imagem do container. |
| `container_port` | `number` | `8080` | Porta da aplicacao no container. |
| `task_cpu` | `number` | `512` | CPU da task Fargate. |
| `task_memory` | `number` | `1024` | Memoria da task Fargate (MiB). |
| `desired_count` | `number` | `1` | Quantidade inicial de tasks. |
| `create_security_group` | `bool` | `true` | Cria SG dedicado para o servico. |
| `allowed_security_group_ids` | `list(string)` | `[]` | SGs de origem permitidos para ingress. |
| `allowed_cidr_blocks` | `list(string)` | `[]` | CIDRs permitidos para ingress. |
| `create_load_balancer` | `bool` | `false` | Cria ALB e integra ao ECS service. |
| `load_balancer_subnet_ids` | `list(string)` | `[]` | Subnets do ALB quando habilitado. |
| `listener_protocol` | `string` | `"HTTP"` | Protocolo do listener ALB (`HTTP`/`HTTPS`). |
| `certificate_arn` | `string` | `null` | Certificado ACM para HTTPS. |
| `secrets` | `map(string)` | `{}` | Secrets por referencia ARN (sem plaintext). |
| `create_service_autoscaling` | `bool` | `false` | Habilita autoscaling da service. |
| `autoscaling_min_capacity` | `number` | `1` | Capacidade minima do autoscaling. |
| `autoscaling_max_capacity` | `number` | `4` | Capacidade maxima do autoscaling. |
| `tags` | `map(string)` | `{}` | Tags comuns aplicadas nos recursos. |

## Outputs

| Output | Descricao |
| --- | --- |
| `cluster_arn` | ARN do cluster ECS. |
| `cluster_name` | Nome do cluster ECS. |
| `service_arn` | ARN/ID da ECS service. |
| `service_name` | Nome da ECS service. |
| `task_definition_arn` | ARN da task definition em uso. |
| `task_definition_family` | Familia da task definition. |
| `security_group_id` | ID do SG criado, quando habilitado. |
| `load_balancer_arn` | ARN do ALB, quando habilitado. |
| `alb_dns_name` | DNS do ALB, quando habilitado. |
| `target_group_arn` | ARN do target group, quando habilitado. |
| `log_group_name` | Nome do log group do servico. |
| `effective_create_load_balancer` | Flag efetiva para criacao do ALB. |
| `effective_create_service_autoscaling` | Flag efetiva para autoscaling. |

## Validacao local

Na raiz do modulo:

```bash
terraform fmt -recursive
terraform init -backend=false
terraform validate
```

Nos exemplos:

```bash
cd examples/simple
terraform init -backend=false
terraform validate

cd ../production
terraform init -backend=false
terraform validate
```

## Versionamento

- Publique com tags semanticas, por exemplo `v1.0.0`, `v1.1.0`.
- Consumidores devem fixar versao com `?ref=vX.Y.Z`.
- Mudancas breaking exigem novo major.
