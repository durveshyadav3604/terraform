resource "aws_autoscaling_group" "ecs_asg" {
  name                = "ecs-asg"
  min_size            = 1
  max_size            = 4
  desired_capacity    = 2
  vpc_zone_identifier = aws_subnet.private[*].id

  launch_template {
    id      = aws_launch_template.ecs_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = "true"
    propagate_at_launch = true
  }
}
#ECS Capacity Provider
resource "aws_ecs_capacity_provider" "ecs_cp" {
  name = "node-capacity-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.ecs_asg.arn

    managed_scaling {
      status          = "ENABLED"
      target_capacity = 80
    }
  }
}
#Attach it to the cluster
resource "aws_ecs_cluster_capacity_providers" "ecs_cp_attach" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = [
    aws_ecs_capacity_provider.ecs_cp.name
  ]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ecs_cp.name
    weight            = 1
  }
}

