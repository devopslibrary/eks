resource "aws_launch_template" "default" {
  name_prefix            = "eks-example-"
  description            = "Default Launch-Template"
  update_default_version = true

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = 100
      volume_type           = "gp2"
      delete_on_termination = true
      # encrypted             = true

      # Enable this if you want to encrypt your node root volumes with a KMS/CMK. encryption of PVCs is handled via k8s StorageClass tho
      # you also need to attach data.aws_iam_policy_document.ebs_decryption.json from the disk_encryption_policy.tf to the KMS/CMK key then !!
      # kms_key_id            = var.kms_key_arn
    }
  }


  monitoring {
    enabled = true
  }

  network_interfaces {
    associate_public_ip_address = false
    delete_on_termination       = true
    security_groups             = [module.eks.worker_security_group_id]
  }

  # Supplying custom tags to EKS instances is another use-case for LaunchTemplates
  tag_specifications {
    resource_type = "instance"

    tags = {
      CustomTag = "EKS example"
    }
  }

  # Supplying custom tags to EKS instances root volumes is another use-case for LaunchTemplates. (doesnt add tags to dynamically provisioned volumes via PVC tho)
  tag_specifications {
    resource_type = "volume"

    tags = {
      CustomTag = "EKS example"
    }
  }

  # Tag the LT itself
  tags = {
    CustomTag = "EKS example"
  }

  lifecycle {
    create_before_destroy = true
  }
}
