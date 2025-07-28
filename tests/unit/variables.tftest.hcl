# Test Fixtures
variables {
  instance_type    = "t3.small"
  root_volume_size = 10
  data_volume_size = 20
  tags = {
    Name        = "Component Analysis"
    Terraform   = "true"
    Environment = "Test"
    Owner       = "DevOps"
  }
}

run "invalid_instance_type" {
  command = plan

  # Arrange
  variables {
    dtrack_ec2_instance_type    = "m5.large"
    dtrack_ebs_root_volume_size = var.root_volume_size
    dtrack_ebs_data_volume_size = var.data_volume_size
    tags                        = var.tags
  }

  # Assert
  expect_failures = [
    var.dtrack_ec2_instance_type
  ]
}

run "invalid_root_volume_size" {
  command = plan

  # Arrange
  variables {
    dtrack_ec2_instance_type    = var.instance_type
    dtrack_ebs_root_volume_size = 4000 # Invalid size
    dtrack_ebs_data_volume_size = var.data_volume_size
    tags                        = var.tags
  }

  # Assert
  expect_failures = [
    var.dtrack_ebs_root_volume_size
  ]
}

run "invalid_data_volume_size" {
  command = plan

  # Arrange
  variables {
    dtrack_ec2_instance_type    = var.instance_type
    dtrack_ebs_root_volume_size = var.root_volume_size
    dtrack_ebs_data_volume_size = 5000 # Invalid size
    tags                        = var.tags
  }

  # Assert
  expect_failures = [
    var.dtrack_ebs_data_volume_size
  ]
}

run "invalid_tags" {
  command = plan

  # Arrange
  variables {
    dtrack_ec2_instance_type    = var.instance_type
    dtrack_ebs_root_volume_size = var.root_volume_size
    dtrack_ebs_data_volume_size = var.data_volume_size
    tags                        = {} # Missing tags
  }

  # Assert
  expect_failures = [
    var.tags
  ]
}
