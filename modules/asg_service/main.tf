resource "aws_launch_template" "this" {
  name_prefix   = "${var.name}-${var.environment}-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name
  user_data     = var.user_data == null ? null : base64encode(var.user_data)

  vpc_security_group_ids = var.security_group_ids

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      encrypted             = true
      volume_size           = var.root_volume_size
      volume_type           = var.root_volume_type
      delete_on_termination = true
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name        = var.name
      Environment = var.environment
    })
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(var.tags, {
      Name        = "${var.name}-root"
      Environment = var.environment
    })
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "this" {
  name                      = "${var.name}-${var.environment}"
  min_size                  = var.min_size
  desired_capacity          = var.desired_capacity
  max_size                  = var.max_size
  vpc_zone_identifier       = var.subnet_ids
  target_group_arns         = var.target_group_arns
  health_check_type         = length(var.target_group_arns) > 0 ? "ELB" : "EC2"
  health_check_grace_period = var.instance_warmup

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  termination_policies = [
    "OldestLaunchTemplate",
    "OldestInstance"
  ]

  dynamic "tag" {
    for_each = merge(var.tags, {
      Name        = var.name
      Environment = var.environment
    })

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  instance_refresh {
    strategy = "Rolling"

    preferences {
      min_healthy_percentage = 90
      instance_warmup        = var.instance_warmup
    }

    triggers = ["launch_template"]
  }
}

resource "aws_autoscaling_policy" "cpu_target_tracking" {
  name                      = "${var.name}-${var.environment}-cpu-target"
  autoscaling_group_name    = aws_autoscaling_group.this.name
  policy_type               = "TargetTrackingScaling"
  estimated_instance_warmup = var.instance_warmup

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = var.cpu_target_value
  }
}

