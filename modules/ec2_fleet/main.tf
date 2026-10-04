locals {
  sorted_instance_names = sort(keys(var.instances))

  protected_instances = {
    for name, instance in var.instances : name => instance
    if try(instance.protected, false)
  }

  standard_instances = {
    for name, instance in var.instances : name => instance
    if !try(instance.protected, false)
  }
}

resource "aws_instance" "standard" {
  for_each = local.standard_instances

  ami                         = coalesce(try(each.value.ami_id, null), var.default_ami_id)
  instance_type               = each.value.instance_type
  key_name                    = each.value.key_name
  subnet_id                   = try(each.value.subnet_id, null) != null ? each.value.subnet_id : element(var.default_subnet_ids, index(local.sorted_instance_names, each.key) % length(var.default_subnet_ids))
  vpc_security_group_ids      = length(try(each.value.security_group_ids, [])) > 0 ? each.value.security_group_ids : var.default_security_group_ids
  iam_instance_profile        = try(each.value.iam_instance_profile, null)
  associate_public_ip_address = try(each.value.associate_public_ip_address, false)
  disable_api_termination     = try(each.value.disable_api_termination, false)
  monitoring                  = var.enable_detailed_monitoring
  user_data                   = try(each.value.user_data, null)

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_type           = each.value.root_volume_type
    volume_size           = each.value.root_volume_size
    iops                  = try(each.value.root_iops, null)
    throughput            = lower(each.value.root_volume_type) == "gp3" ? try(each.value.root_throughput, null) : null
    encrypted             = var.encrypt_root_volumes
    delete_on_termination = true

    tags = merge(var.common_tags, try(each.value.tags, {}), {
      Name        = "${each.key}-root"
      Environment = var.environment
      Owner       = var.owner
    })
  }

  tags = merge(var.common_tags, try(each.value.tags, {}), {
    Name        = each.key
    Environment = var.environment
    Owner       = var.owner
  })
}

resource "aws_instance" "protected" {
  for_each = local.protected_instances

  ami                         = coalesce(try(each.value.ami_id, null), var.default_ami_id)
  instance_type               = each.value.instance_type
  key_name                    = each.value.key_name
  subnet_id                   = try(each.value.subnet_id, null) != null ? each.value.subnet_id : element(var.default_subnet_ids, index(local.sorted_instance_names, each.key) % length(var.default_subnet_ids))
  vpc_security_group_ids      = length(try(each.value.security_group_ids, [])) > 0 ? each.value.security_group_ids : var.default_security_group_ids
  iam_instance_profile        = try(each.value.iam_instance_profile, null)
  associate_public_ip_address = try(each.value.associate_public_ip_address, false)
  disable_api_termination     = true
  monitoring                  = var.enable_detailed_monitoring
  user_data                   = try(each.value.user_data, null)

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_type           = each.value.root_volume_type
    volume_size           = each.value.root_volume_size
    iops                  = try(each.value.root_iops, null)
    throughput            = lower(each.value.root_volume_type) == "gp3" ? try(each.value.root_throughput, null) : null
    encrypted             = var.encrypt_root_volumes
    delete_on_termination = true

    tags = merge(var.common_tags, try(each.value.tags, {}), {
      Name        = "${each.key}-root"
      Environment = var.environment
      Owner       = var.owner
    })
  }

  tags = merge(var.common_tags, try(each.value.tags, {}), {
    Name        = each.key
    Environment = var.environment
    Owner       = var.owner
  })

  lifecycle {
    prevent_destroy = true
  }
}

