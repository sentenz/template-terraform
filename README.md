# Terraform AWS

A Terraform module collection to provision infrastructure for deploying on AWS.

- [1. Usage](#1-usage)
  - [1.1. Details](#11-details)
  - [1.2. Modules](#12-modules)
  - [1.3. Identity and Access](#13-identity-and-access)
    - [1.3.1. AWS Administrator Access](#131-aws-administrator-access)
    - [1.3.2. SSH Authentication](#132-ssh-authentication)
  - [1.4. Task Runner](#14-task-runner)
- [2. Requirements](#2-requirements)
- [3. Providers](#3-providers)
- [4. Modules](#4-modules)
- [5. Resources](#5-resources)
- [6. Inputs](#6-inputs)
- [7. Outputs](#7-outputs)

## 1. Usage

### 1.1. Details

1. Module Sources using Local Paths

    - `modules/aws-ec2`
      > AWS EC2 module focuses on setting up network infrastructure (VPC) and EC2 instances. The module handles a complete stack, including instances, VPC, key pairs, and security groups.

### 1.2. Modules

- Dependency-Track
  > [OWAS Dependency-Track](https://docs.dependencytrack.org/) is an intelligent Component Analysis platform to identify and reduce risk in the software supply chain. Dependency-Track leverages the capabilities of the Software Bill of Materials (SBOM) for Software Composition Analysis (SCA) solutions.

  ```hcl
  module "component_analysis" {
    source = "./modules/aws-ec2"

    # AWS configuration
    name       = var.dtrack_name
    region     = var.region
    key_path   = var.key_path

    tags = var.tags
  }
  ```

### 1.3. Identity and Access

#### 1.3.1. AWS Administrator Access

> [!NOTE]
> AWS Administrator Access requires secure management of credentials. It is essential that sensitive information is protected, and that multiple access profiles are maintained within the AWS credentials file.

1. Configure AWS

    To interact with AWS programmatically, configure AWS credentials for Terraform using the **shared credentials file** typically resides in the `~/.aws/credentials`.

    - `~/.aws/credentials`
      > The file includes individual profiles for general, development, and production access, e.g. access keys for different environments (dev, prod).

      ```ini
      [default]
      aws_access_key_id = <YOUR_ACCESS_KEY>
      aws_secret_access_key = <YOUR_SECRET_KEY>
      aws_session_token = <YOUR_SESSION_TOKEN>

      [dev]
      aws_access_key_id = <DEV_ACCESS_KEY>
      aws_secret_access_key = <DEV_SECRET_KEY>
      aws_session_token = <DEV_SESSION_TOKEN>

      [prod]
      aws_access_key_id = <PROD_ACCESS_KEY>
      aws_secret_access_key = <PROD_SECRET_KEY>
      aws_session_token = <PROD_SESSION_TOKEN>
      ```

2. Terraform Integration

    Reference the access profiles in Terraform `provider.tf` configuration file.

    - `provider.tf`

      ```hcl
      provider "aws" {
        region  = var.region
        profile = "default"
      }
      ```

    For multi-environment organize inventory to separate dev/prod `provider.tf` files.

    > [!NOTE]
    > If the root directory has a `provider.tf`, delete it to avoid inheritance conflicts. Terraform modules inherit providers from the root by default, but environment-specific directories should manage their own providers.

    - `environments/dev/provider.tf`

      ```hcl
      provider "aws" {
        region  = var.region
        profile = "dev"
      }
      ```

    - `environments/prod/provider.tf`

      ```hcl
      provider "aws" {
        region  = var.region
        profile = "prod"
      }
      ```

#### 1.3.2. SSH Authentication

SSH is employed for securely accessing AWS instances, particularly when provisioning infrastructure via automation tools such as Ansible. A well-defined SSH configuration enhances both security and ease of administration.

> [!NOTE]
> Terraform uses the public key to configure AWS, while the private key is stored locally for SSH access.

1. SSH Key Pair

    Generate an SSH Key Pair.

    ```bash
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/aws
    ```

    Create dedicated SSH Key Pairs for dev and prod to enforce isolation.

    ```bash
    # For Development
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/aws-dev

    # For Production
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/aws-prod
    ```

    - Private Key
      > SSH keys are used to securely connect to EC2 instances. Private Key must be kept secret and secure on the local machine.

      > [!NOTE]
      > Set strict permissions for Private Key security utilizing `chmod 600 ~/.ssh/aws-prod`.

    - Public Key
      > An SSH public key is part of a key pair. Share the public key with the server to be connected.

2. SSH Client

    Configure `~/.ssh/config` to simplify SSH connections.

    - `~/.ssh/config`

      ```plaintext
      Host aws-dev                       # Friendly name for the connection
        User         ec2-user            # Default user for Amazon Linux
        HostName     <PUBLIC_IP_OR_DNS>  # EC2 instance public IP/DNS after deployment
        IdentityFile ~/.ssh/aws-dev      # Path to private key
        StrictHostKeyChecking no         # Optional: Disable host key prompts

      Host aws-prod                      # Friendly name for the connection
        User         ec2-user            # Default user for Amazon Linux
        HostName     <PUBLIC_IP_OR_DNS>  # EC2 instance public IP/DNS after deployment
        IdentityFile ~/.ssh/aws-prod     # Path to private key
        StrictHostKeyChecking no         # Optional: Disable host key prompts
      ```

3. Terraform Integration

    Reference the public key in Terraform `variables.tf` configuration file.

    - `variables.tf`

      ```hcl
      variable "key_path" {
        description = "Path to the public key for SSH access."
        type        = string
        default     = "~/.ssh/aws.pub"
      }
      ```

    For multi-environment organize `variables.tf` to separate dev/prod environments.

    - `environments/dev/variables.tf`

      ```hcl
      variable "key_path" {
        description = "Path to the public key for SSH access."
        type        = string
        default     = "~/.ssh/aws-dev.pub"
      }
      ```

    - `environments/prod/variables.tf`

      ```hcl
      variable "key_path" {
        description = "Path to the public key for SSH access."
        type        = string
        default     = "~/.ssh/aws-prod.pub"
      }
      ```

### 1.4. Task Runner

- [Makefile](Makefile)
  > Refer to the Makefile as the Task Runner file.

  > [!NOTE]
  > Run the `make help` command in the terminal to list the tasks used for the project.

  ```plaintext
  $ make help

  TASK
          A collection of tasks used for the project.

  USAGE
          make [target]

  TARGET
          setup                  Setup the environment
          teardown               Clean up the environment
  ```

<!-- BEGIN_TF_DOCS -->
## 2. Requirements

| Name                                                                      | Version   |
| ------------------------------------------------------------------------- | --------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7    |
| <a name="requirement_aws"></a> [aws](#requirement\_aws)                   | >= 5.79.0 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls)                   | >= 3.4    |

## 3. Providers

| Name                                              | Version |
| ------------------------------------------------- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.94.1  |

## 4. Modules

| Name                                                                                         | Source            | Version |
| -------------------------------------------------------------------------------------------- | ----------------- | ------- |
| <a name="module_component_analysis"></a> [component\_analysis](#module\_component\_analysis) | ./modules/aws-ec2 | n/a     |

## 5. Resources

| Name                                                                                                                     | Type        |
| ------------------------------------------------------------------------------------------------------------------------ | ----------- |
| [aws_subnet.existing_private_az1](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |
| [aws_subnet.existing_private_az2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |
| [aws_subnet.existing_public_az1](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet)  | data source |
| [aws_subnet.existing_public_az2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet)  | data source |
| [aws_vpc.existing](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc)                   | data source |

## 6. Inputs

| Name                                                                                                                                               | Description                                                                                              | Type           | Default                                                                                          | Required |
| -------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------- | -------------- | ------------------------------------------------------------------------------------------------ | :------: |
| <a name="input_dtrack_ebs_data_create"></a> [dtrack\_ebs\_data\_create](#input\_dtrack\_ebs\_data\_create)                                         | Whether to create and attach a data EBS volume.                                                          | `bool`         | `true`                                                                                           |    no    |
| <a name="input_dtrack_ebs_data_volume_size"></a> [dtrack\_ebs\_data\_volume\_size](#input\_dtrack\_ebs\_data\_volume\_size)                        | Size of the data EBS volume in GB.                                                                       | `number`       | n/a                                                                                              |   yes    |
| <a name="input_dtrack_ebs_root_volume_size"></a> [dtrack\_ebs\_root\_volume\_size](#input\_dtrack\_ebs\_root\_volume\_size)                        | Size of the root EBS volume in GB.                                                                       | `number`       | n/a                                                                                              |   yes    |
| <a name="input_dtrack_ec2_instance_type"></a> [dtrack\_ec2\_instance\_type](#input\_dtrack\_ec2\_instance\_type)                                   | The type to provide an EC2 instance resource.                                                            | `string`       | n/a                                                                                              |   yes    |
| <a name="input_dtrack_eip_create"></a> [dtrack\_eip\_create](#input\_dtrack\_eip\_create)                                                          | Specifies whether a public EIP will be created and associated with the instance.                         | `bool`         | `false`                                                                                          |    no    |
| <a name="input_dtrack_name"></a> [dtrack\_name](#input\_dtrack\_name)                                                                              | The name for resources.                                                                                  | `string`       | `"component-analysis"`                                                                           |    no    |
| <a name="input_dtrack_sg_egress_rules"></a> [dtrack\_sg\_egress\_rules](#input\_dtrack\_sg\_egress\_rules)                                         | List of egress rules for the security group.                                                             | `list(string)` | <pre>[<br/>  "all-all"<br/>]</pre>                                                               |    no    |
| <a name="input_dtrack_sg_ingress_cidr_blocks"></a> [dtrack\_sg\_ingress\_cidr\_blocks](#input\_dtrack\_sg\_ingress\_cidr\_blocks)                  | List of IPv4 CIDR blocks allowed for ingress, e.g., `0.0.0.0/0` refers to the entire IPv4 address space. | `list(string)` | <pre>[<br/>  "0.0.0.0/0"<br/>]</pre>                                                             |    no    |
| <a name="input_dtrack_sg_ingress_ipv6_cidr_blocks"></a> [dtrack\_sg\_ingress\_ipv6\_cidr\_blocks](#input\_dtrack\_sg\_ingress\_ipv6\_cidr\_blocks) | List of IPv6 CIDR blocks allowed for ingress, e.g., `::/0` refers to the entire IPv6 address space.      | `list(string)` | <pre>[<br/>  "::/0"<br/>]</pre>                                                                  |    no    |
| <a name="input_dtrack_sg_ingress_rules"></a> [dtrack\_sg\_ingress\_rules](#input\_dtrack\_sg\_ingress\_rules)                                      | List of ingress rules for the security group.                                                            | `list(string)` | <pre>[<br/>  "http-80-tcp",<br/>  "https-443-tcp",<br/>  "ssh-tcp",<br/>  "all-icmp"<br/>]</pre> |    no    |
| <a name="input_ec2_subnet_id"></a> [ec2\_subnet\_id](#input\_ec2\_subnet\_id)                                                                      | The VPC Subnet ID to launch in.                                                                          | `string`       | `null`                                                                                           |    no    |
| <a name="input_key_pair_create"></a> [key\_pair\_create](#input\_key\_pair\_create)                                                                | Whether to create a new SSH key pair for EC2 access.                                                     | `bool`         | n/a                                                                                              |   yes    |
| <a name="input_key_path"></a> [key\_path](#input\_key\_path)                                                                                       | Path to the public key for SSH access, e.g. `~/.ssh/aws.pub`.                                            | `string`       | `null`                                                                                           |    no    |
| <a name="input_tags"></a> [tags](#input\_tags)                                                                                                     | A map of tags to add to all resources.                                                                   | `map(string)`  | n/a                                                                                              |   yes    |
| <a name="input_vpc_create"></a> [vpc\_create](#input\_vpc\_create)                                                                                 | Whether to create a new VPC.                                                                             | `bool`         | `false`                                                                                          |    no    |

## 7. Outputs

| Name                                                                                                         | Description                                                            |
| ------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------- |
| <a name="output_dtrack_ec2_instance_id"></a> [dtrack\_ec2\_instance\_id](#output\_dtrack\_ec2\_instance\_id) | The ID of the EC2 instance for OWASP Dependency Track.                 |
| <a name="output_dtrack_ec2_private_ip"></a> [dtrack\_ec2\_private\_ip](#output\_dtrack\_ec2\_private\_ip)    | The private IP address of the EC2 instance for OWASP Dependency Track. |
| <a name="output_dtrack_ec2_public_dns"></a> [dtrack\_ec2\_public\_dns](#output\_dtrack\_ec2\_public\_dns)    | The public DNS of the EC2 instance for OWASP Dependency Track.         |
| <a name="output_dtrack_ec2_public_ip"></a> [dtrack\_ec2\_public\_ip](#output\_dtrack\_ec2\_public\_ip)       | The public IP address of the EC2 instance for OWASP Dependency Track.  |
<!-- END_TF_DOCS -->
