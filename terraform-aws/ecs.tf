resource "aws_ecs_cluster" "main" {
  name = "node-ecs-cluster"
}
resource "aws_ecs_task_definition" "app" {
  family                   = "node-app-2"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = data.aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name  = "node-app-2"
      image = "082634139648.dkr.ecr.ap-south-1.amazonaws.com/node-app-2:latest"
      portMappings = [{
        containerPort = 3000
      }]
      environment = [
        { name = "DB_HOST", value = aws_db_instance.postgres.address },
        { name = "DB_USER", value = "appuser" },
        { name = "DB_PASS", value = "password123" },
        { name = "DB_NAME", value = "appdb" }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/node-app"
          awslogs-region        = "ap-south-1"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}
resource "aws_ecs_service" "app" {
  name            = "node-app-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.public[*].id
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.app_tg.arn
    container_name   = "node-app-2"
    container_port   = 3000
  }

  depends_on = [aws_lb_listener.http]
}
