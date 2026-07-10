# AWS EC2 module

This module provisions an EC2 instance with an optional key pair, optional VPC, dedicated security group, encrypted EBS volumes, and optional Elastic IP.

## Requirements

| Component | Version |
| --- | --- |
| Terraform | `~> 1.10.0` |
| AWS provider | `>= 6.0, < 7.0` |

## Child modules

| Module | Source | Version |
| --- | --- | --- |
| Key pair | `terraform-aws-modules/key-pair/aws` | `3.0.0` |
| VPC | `terraform-aws-modules/vpc/aws` | `6.6.1` |
| Security group | `terraform-aws-modules/security-group/aws` | `6.0.0` |
| EC2 instance | `terraform-aws-modules/ec2-instance/aws` | `6.4.0` |

## Usage

```hcl
module "application" {
  source = "../../modules/aws-ec2"

  name              = "application"
  ec2_instance_type = "t3.large"

  vpc_create    = false
  vpc_id        = data.aws_vpc.existing.id
  ec2_subnet_id = data.aws_subnet.private.id

  security_group_ingress_cidr_blocks = ["10.0.0.0/16"]
  security_group_ingress_rules       = ["https-443-tcp"]
  security_group_egress_rules        = ["https-443-tcp"]

  ebs_root_encrypted = true
  ebs_data_create    = true
  eip_create         = false

  tags = {
    Name        = "Application"
    Environment = "Stage"
    Terraform   = "true"
    Owner       = "Platform"
  }
}
```

## Security-group contract

The named rule inputs support these presets:

- `http-80-tcp`
- `https-443-tcp`
- `ssh-tcp`

Unsupported preset names fail during variable validation.

`security_group_ingress_with_cidr_blocks` accepts comma-separated IPv4 or IPv6 CIDRs for an explicit port range. Each CIDR is validated independently. Public ingress from `0.0.0.0/0` and `::/0` is rejected, including when either value appears inside a comma-separated list.

Example:

```hcl
security_group_ingress_with_cidr_blocks = [{
  cidr_blocks = "10.20.0.0/16,2001:db8:20::/64"
  from_port   = 8443
  to_port     = 8443
  protocol    = "tcp"
  description = "Trusted application clients"
}]
```

## Important inputs

| Name | Description | Default |
| --- | --- | --- |
| `name` | Prefix for resource names | `aws-ec2` |
| `vpc_create` | Create a VPC inside the module | `false` |
| `vpc_id` | Existing VPC ID when `vpc_create = false` | `null` |
| `ec2_subnet_id` | Existing subnet ID when `vpc_create = false` | `null` |
| `ec2_instance_type` | EC2 instance type | required |
| `key_pair_create` | Create and register an SSH public key | `false` |
| `security_group_ingress_cidr_blocks` | Trusted IPv4 ingress ranges | `[]` |
| `security_group_ingress_ipv6_cidr_blocks` | Trusted IPv6 ingress ranges | `[]` |
| `security_group_ingress_rules` | Named ingress presets | `["https-443-tcp"]` |
| `security_group_egress_rules` | Named egress presets | `["https-443-tcp"]` |
| `ebs_root_encrypted` | Encrypt the root volume | `true` |
| `ebs_data_create` | Create an additional data volume | `false` |
| `eip_create` | Associate a public Elastic IP | `false` |

The complete typed contract is defined in [`variables.tf`](./variables.tf).

## Outputs

| Name | Description |
| --- | --- |
| `ec2_instance_id` | EC2 instance ID |
| `ec2_private_ip` | Private IP address |
| `ec2_public_ip` | Public IP address, when assigned |
| `ec2_public_dns` | Public DNS name, when assigned |

## Validation

```bash
terraform fmt -check -diff -recursive
terraform -chdir=modules/aws-ec2 init -backend=false
terraform -chdir=modules/aws-ec2 validate
terraform -chdir=modules/aws-ec2 test
```

Before applying changes to an existing environment, create and review a saved state-backed plan. Security-group rule address changes can cause rule replacement even when the parent security-group address remains stable.
