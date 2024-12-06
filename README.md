# Terraform AWS

A Terraform module collection to provision infrastructure for deploying on AWS.

- [1. Usage](#1-usage)
  - [1.1. Details](#11-details)
  - [1.2. Modules](#12-modules)
  - [1.3. Identity and Access](#13-identity-and-access)
  - [1.4. Instructions](#14-instructions)
- [2. Requirements](#2-requirements)
- [3. Providers](#3-providers)
- [4. Modules](#4-modules)
- [5. Resources](#5-resources)
- [6. Inputs](#6-inputs)
- [7. Outputs](#7-outputs)
- [8. License](#8-license)

## 1. Usage

### 1.1. Details

1. Module Sources using Local Paths

    - `modules/aws-ec2`
      > AWS EC2 module focuses on setting up network infrastructure (VPC) and EC2 instances. The module handles a complete stack, including instances, VPC, key pairs, and security groups.

### 1.2. Modules

- Dependency-Track
  > [OWAS Dependency-Track](https://docs.dependencytrack.org/) is an intelligent Component Analysis platform to identify and reduce risk in the software supply chain. Dependency-Track leverages the capabilities of the Software Bill of Materials (SBOM) for Software Composition Analysis (SCA) solutions.

  ```hcl
  module "dependency_track" {
    source = "./modules/aws-ec2"

    # AWS configuration
    name   = var.dtrack_name
    aws_region = var.aws_region
    key_path   = var.key_path

    tags = var.tags
  }
  ```

### 1.3. Identity and Access

1. SSH Authentication
    > Connecting to AWS with Secure Shell (SSH) protocol provides a secure channel over an unsecured network.

    - Private Key
      > Private Key must be kept secret and secure on the local machine. The `~/.ssh/config` file is a user-specific configuration file for SSH (Secure Shell) clients. The `IdentityFile` keyword specifies the private key file to use for that specific connection. An SSH connection to a server can be made by issuing the command `ssh aws` which corresponds to a host entry in the `~/.ssh/config` file.

      ```plaintext
      Host aws
        User ec2-user
        HostName <public_ip/public_dns>
        IdentityFile ~/.ssh/aws
      ```

    - Public Key
      > An SSH public key is part of a key pair. Share the public key with the server to be connected by configuring `key_path`.

      ```hcl
      variable "key_path" {
        description = "Path to the public key for SSH access."
        type        = string
        default     = "~/.ssh/aws.pub"
      }
      ```

### 1.4. Instructions

1. Tasks

    - [Makefile](Makefile)
      > Refer to the Makefile as the central task file. Use the command line `make help` in the terminal to list the tasks used for the project.

      ```plaintext
      $ make help

      TASK
              A centralized collection of commands and operations used in this project.

      USAGE
              make [target]

              setup                 Setup the Software Development environment
              terraform-deploy      Provision of the Terraform infrastructure configuration
              terraform-destroy     Safely tear down Terraform managed infrastructure resources
      ```

## 2. Requirements

| Name                                                                      | Version   |
| ------------------------------------------------------------------------- | --------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0  |
| <a name="requirement_aws"></a> [aws](#requirement\_aws)                   | >= 5.38.0 |

## 3. Providers

No providers.

## 4. Modules

| Name                                                                                   | Source            | Version |
| -------------------------------------------------------------------------------------- | ----------------- | ------- |
| <a name="module_dependency_track"></a> [dependency\_track](#module\_dependency\_track) | ./modules/aws-ec2 | n/a     |
| <a name="module_tmp"></a> [tmp](#module\_tmp)                                          | ./modules/aws-ec2 | n/a     |

## 5. Resources

No resources.

## 6. Inputs

| Name                                                                                                                                               | Description                                                                                              | Type                                                                                                                                                                          | Default                                                                                                                                                                                                                                                                                                                                                                                                                           | Required |
| -------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :------: |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region)                                                                                 | The AWS region where resources will be deployed.                                                         | `string`                                                                                                                                                                      | `"eu-central-1"`                                                                                                                                                                                                                                                                                                                                                                                                                  |    no    |
| <a name="input_dtrack_ebs_data_create"></a> [dtrack\_ebs\_data\_create](#input\_dtrack\_ebs\_data\_create)                                         | Whether to create and attach an data EBS volume.                                                         | `bool`                                                                                                                                                                        | `true`                                                                                                                                                                                                                                                                                                                                                                                                                            |    no    |
| <a name="input_dtrack_eip_create"></a> [dtrack\_eip\_create](#input\_dtrack\_eip\_create)                                                          | Specifies whether a public EIP will be created and associated with the instance.                         | `bool`                                                                                                                                                                        | `true`                                                                                                                                                                                                                                                                                                                                                                                                                            |    no    |
| <a name="input_dtrack_name"></a> [dtrack\_name](#input\_dtrack\_name)                                                                              | The name for resources.                                                                                  | `string`                                                                                                                                                                      | `"dependency-track"`                                                                                                                                                                                                                                                                                                                                                                                                              |    no    |
| <a name="input_dtrack_sg_egress_rules"></a> [dtrack\_sg\_egress\_rules](#input\_dtrack\_sg\_egress\_rules)                                         | List of egress rules for the security group.                                                             | `list(string)`                                                                                                                                                                | <pre>[<br>  "all-all"<br>]</pre>                                                                                                                                                                                                                                                                                                                                                                                                  |    no    |
| <a name="input_dtrack_sg_ingress_cidr_blocks"></a> [dtrack\_sg\_ingress\_cidr\_blocks](#input\_dtrack\_sg\_ingress\_cidr\_blocks)                  | List of IPv4 CIDR blocks allowed for ingress, e.g., `0.0.0.0/0` refers to the entire IPv4 address space. | `list(string)`                                                                                                                                                                | <pre>[<br>  "0.0.0.0/0"<br>]</pre>                                                                                                                                                                                                                                                                                                                                                                                                |    no    |
| <a name="input_dtrack_sg_ingress_ipv6_cidr_blocks"></a> [dtrack\_sg\_ingress\_ipv6\_cidr\_blocks](#input\_dtrack\_sg\_ingress\_ipv6\_cidr\_blocks) | List of IPv6 CIDR blocks allowed for ingress, e.g., `::/0` refers to the entire IPv6 address space.      | `list(string)`                                                                                                                                                                | <pre>[<br>  "::/0"<br>]</pre>                                                                                                                                                                                                                                                                                                                                                                                                     |    no    |
| <a name="input_dtrack_sg_ingress_rules"></a> [dtrack\_sg\_ingress\_rules](#input\_dtrack\_sg\_ingress\_rules)                                      | List of ingress rules for the security group.                                                            | `list(string)`                                                                                                                                                                | <pre>[<br>  "http-80-tcp",<br>  "https-443-tcp",<br>  "ssh-tcp",<br>  "all-icmp"<br>]</pre>                                                                                                                                                                                                                                                                                                                                       |    no    |
| <a name="input_dtrack_sg_ingress_with_cidr_blocks"></a> [dtrack\_sg\_ingress\_with\_cidr\_blocks](#input\_dtrack\_sg\_ingress\_with\_cidr\_blocks) | List of ingress rules with specific CIDR blocks.                                                         | <pre>list(object({<br>    cidr_blocks = string<br>    from_port   = number<br>    to_port     = number<br>    protocol    = string<br>    description = string<br>  }))</pre> | <pre>[<br>  {<br>    "cidr_blocks": "0.0.0.0/0",<br>    "description": "Inbound traffic for dtrack-frontend on port 8080.",<br>    "from_port": 8080,<br>    "protocol": "tcp",<br>    "to_port": 8080<br>  },<br>  {<br>    "cidr_blocks": "0.0.0.0/0",<br>    "description": "Inbound traffic for dtrack-apiserver on port 8081.",<br>    "from_port": 8081,<br>    "protocol": "tcp",<br>    "to_port": 8081<br>  }<br>]</pre> |    no    |
| <a name="input_key_path"></a> [key\_path](#input\_key\_path)                                                                                       | Path to the public key for SSH access.                                                                   | `string`                                                                                                                                                                      | `"~/.ssh/aws.pub"`                                                                                                                                                                                                                                                                                                                                                                                                                |    no    |
| <a name="input_tags"></a> [tags](#input\_tags)                                                                                                     | Tags to be applied to all resources.                                                                     | `map(string)`                                                                                                                                                                 | <pre>{<br>  "Environment": "Staging",<br>  "Owner": "DevOps",<br>  "Project": "Internal Developer Platform (IDP)",<br>  "Terraform": "true"<br>}</pre>                                                                                                                                                                                                                                                                            |    no    |
| <a name="input_tmp_ebs_root_volume_size"></a> [tmp\_ebs\_root\_volume\_size](#input\_tmp\_ebs\_root\_volume\_size)                                 | The root volume size in GB.                                                                              | `number`                                                                                                                                                                      | `10`                                                                                                                                                                                                                                                                                                                                                                                                                              |    no    |
| <a name="input_tmp_ec2_instance_type"></a> [tmp\_ec2\_instance\_type](#input\_tmp\_ec2\_instance\_type)                                            | The type to provide an EC2 instance resource.                                                            | `string`                                                                                                                                                                      | `"t2.nano"`                                                                                                                                                                                                                                                                                                                                                                                                                       |    no    |
| <a name="input_tmp_name"></a> [tmp\_name](#input\_tmp\_name)                                                                                       | The name for resources.                                                                                  | `string`                                                                                                                                                                      | `"temporary"`                                                                                                                                                                                                                                                                                                                                                                                                                     |    no    |

## 7. Outputs

| Name                                                                                                         | Description                                                            |
| ------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------- |
| <a name="output_dtrack_ec2_instance_id"></a> [dtrack\_ec2\_instance\_id](#output\_dtrack\_ec2\_instance\_id) | The ID of the EC2 instance for OWASP Dependency Track.                 |
| <a name="output_dtrack_ec2_private_ip"></a> [dtrack\_ec2\_private\_ip](#output\_dtrack\_ec2\_private\_ip)    | The private IP address of the EC2 instance for OWASP Dependency Track. |
| <a name="output_dtrack_ec2_public_dns"></a> [dtrack\_ec2\_public\_dns](#output\_dtrack\_ec2\_public\_dns)    | The public DNS of the EC2 instance for OWASP Dependency Track.         |
| <a name="output_dtrack_ec2_public_ip"></a> [dtrack\_ec2\_public\_ip](#output\_dtrack\_ec2\_public\_ip)       | The public IP address of the EC2 instance for OWASP Dependency Track.  |
| <a name="output_tmp_ec2_instance_id"></a> [tmp\_ec2\_instance\_id](#output\_tmp\_ec2\_instance\_id)          | The ID of the EC2 instance for Temporary.                              |
| <a name="output_tmp_ec2_private_ip"></a> [tmp\_ec2\_private\_ip](#output\_tmp\_ec2\_private\_ip)             | The private IP address of the EC2 instance for Temporary.              |
| <a name="output_tmp_ec2_public_dns"></a> [tmp\_ec2\_public\_dns](#output\_tmp\_ec2\_public\_dns)             | The public DNS of the EC2 instance for Temporary.                      |
| <a name="output_tmp_ec2_public_ip"></a> [tmp\_ec2\_public\_ip](#output\_tmp\_ec2\_public\_ip)                | The public IP address of the EC2 instance for Temporary.               |

## 8. License

`Apache-2.0` Licensed. See the [LICENSE](LICENSE) file for details.
