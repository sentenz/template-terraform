# Terraform AWS

A Terraform module collection to provision infrastructure for deploying on AWS.

- [1. Details](#1-details)
  - [1.1. Modules](#11-modules)
- [2. Usage](#2-usage)
  - [2.1. Authentication](#21-authentication)
    - [2.1.1. AWS Administrator Access](#211-aws-administrator-access)
    - [2.1.2. SSH Key Pair](#212-ssh-key-pair)
- [3. Contribute](#3-contribute)
  - [3.1. Task Runner](#31-task-runner)
    - [3.1.1. Make](#311-make)
  - [3.2. Bootstrap](#32-bootstrap)
    - [3.2.1. Scripts](#321-scripts)
  - [3.3. Release Manager](#33-release-manager)
    - [3.3.1. Semantic-Release](#331-semantic-release)
  - [3.4. Update Manager](#34-update-manager)
    - [3.4.1. Renovate](#341-renovate)
    - [3.4.2. Dependabot](#342-dependabot)
  - [3.5. Secrets Manager](#35-secrets-manager)
    - [3.5.1. SOPS](#351-sops)
  - [3.6. Policy Manager](#36-policy-manager)
    - [3.6.1. HashiCorp Sentinel](#361-hashicorp-sentinel)
  - [3.7. Supply Chain Manager](#37-supply-chain-manager)
    - [3.7.1. Trivy](#371-trivy)
- [4. Troubleshoot](#4-troubleshoot)
  - [4.1. Snapshot](#41-snapshot)
    - [4.1.1. Restore Snapshot](#411-restore-snapshot)
  - [4.2. Inspect Drifts](#42-inspect-drifts)
  - [4.3. Extend Volume](#43-extend-volume)
  - [4.4. State Migration](#44-state-migration)
- [5. References](#5-references)

## 1. Details

### 1.1. Modules

> [!NOTE]
> Module Source using `Local Path`

- `modules/aws-ec2`
  > AWS EC2 module focuses on setting up network infrastructure (VPC) and EC2 instances. The module provisions a complete stack, including instances, VPC, key pairs, and security groups.

- `modules/aws-eks`
  > AWS EKS module provisions a managed Kubernetes cluster on AWS Elastic Kubernetes Service. It configures the control plane, worker node groups, IAM roles, and associated networking resources. The module integrates with supporting components such as VPC, subnets, and security groups, enabling a production-ready Kubernetes environment.

## 2. Usage

### 2.1. Authentication

#### 2.1.1. AWS Administrator Access

AWS Administrator Access requires secure management of credentials. It is essential that sensitive information is protected, and that multiple access profiles are maintained in the local [AWS credentials file](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html).

1. AWS Credentials Configuration

    > [!NOTE]
    > The **shared credentials file** typically resides in the `~/.aws/credentials` directory on the local machine to interact with AWS programmatically, configure AWS over Terraform.

    - `~/.aws/credentials`
      > [!TIP]
      > Retrieve the AWS Access Key ID and Secret Access Key from the AWS IAM Identity Center.

      ```ini
      [default]
      aws_access_key_id = <YOUR_ACCESS_KEY>
      aws_secret_access_key = <YOUR_SECRET_KEY>
      aws_session_token = <YOUR_SESSION_TOKEN>

      [stage]
      aws_access_key_id = <STAGE_ACCESS_KEY>
      aws_secret_access_key = STAGE_SECRET_KEY>
      aws_session_token = <STAGE_SESSION_TOKEN>

      [prod]
      aws_access_key_id = <PROD_ACCESS_KEY>
      aws_secret_access_key = <PROD_SECRET_KEY>
      aws_session_token = <PROD_SESSION_TOKEN>
      ```

2. Terraform Integration

    - Reference the access profiles in the Terraform `provider.tf` configuration file.

      - `provider.tf`

        ```hcl
        provider "aws" {
          region  = var.region
          profile = "default"
        }
        ```

    - Define separate `provider.tf` files in each environment directory for environment-specific configurations and credentials.
      > [!IMPORTANT]
      > If the root directory has a `provider.tf`, delete it to avoid inheritance conflicts. Terraform modules inherit providers from the root by default, but environment-specific directories should manage their own providers.

      - `environments/stage/provider.tf`

        ```hcl
        provider "aws" {
          region  = var.region
          profile = "stage"
        }
        ```

      - `environments/prod/provider.tf`

        ```hcl
        provider "aws" {
          region  = var.region
          profile = "prod"
        }
        ```

#### 2.1.2. SSH Key Pair

SSH (Secure Shell) is used to securely access AWS instances to perform automatized tasks, such as software installation via Ansible or for maintenance purpose.

> [!NOTE]
> Set strict permissions for Private Key utilizing Linux command `chmod 600 ~/.ssh/<private-key>`.

> [!IMPORTANT]
> Store and retrieve the SSH Key Pair files from a Secrets Manager (Vaultwarden). Place the SSH Key Pair files in the `~/.ssh/` directory.

1. SSH Key Pair Generation

    - Generate an SSH Key Pair.

      ```bash
      ssh-keygen -t rsa -b 4096 -f ~/.ssh/aws
      ```

    - Alternative, generate dedicated SSH Key Pairs for `stage` and `prod` to enforce isolation.

      ```bash
      # For Staging
      ssh-keygen -t rsa -b 4096 -f ~/.ssh/aws-stage

      # For Production
      ssh-keygen -t rsa -b 4096 -f ~/.ssh/aws-prod
      ```

2. SSH Key Pair Distribution

    - SSH Public Key
      > The SSH public key is shared with any remote machines (e.g. AWS EC2 instances) to connect to.

    - SSH Private Key
      > Ansible uses SSH private keys to securely proof the identity of the remote machines, such as AWS EC2 instances. The private key must be kept secret and secure, either locally or in a Secrets Manager.

3. SSH Client Configuration

    Configure `~/.ssh/config` to simplify SSH connections.

    > [!NOTE]
    > SSH connection for accessing AWS EC2 instances is not required if Ansible is used for automation. However, it can be useful for troubleshoot or maintenance purpose.

    - `~/.ssh/config`

      ```plaintext
      Host aws-stage                     # Friendly name for the connection
        User         ec2-user            # Default user for Amazon Linux
        HostName     <PUBLIC_IP_OR_DNS>  # EC2 instance public IP/DNS after deployment
        IdentityFile ~/.ssh/aws-stage    # Path to private key
        Port         22                  # Optional: Specify the SSH port if not default (22)
        StrictHostKeyChecking no         # Optional: Disable host key prompts

      Host aws-prod                      # Friendly name for the connection
        User         ec2-user            # Default user for Amazon Linux
        HostName     <PUBLIC_IP_OR_DNS>  # EC2 instance public IP/DNS after deployment
        IdentityFile ~/.ssh/aws-prod     # Path to private key
        Port         22                  # Optional: Specify the SSH port if not default (22)
        StrictHostKeyChecking no         # Optional: Disable host key prompts
      ```

4. Terraform Integration

    - Reference the SSH public key in Terraform `variables.tf` configuration file.

      - `variables.tf`

        ```hcl
        variable "key_path" {
          description = "Path to the public key for SSH access."
          type        = string
          default     = "~/.ssh/aws.pub"
        }
        ```

    - For multi-environment organize `variables.tf` to separate `stage` and `prod` environments.

      - `environments/stage/variables.tf`

        ```hcl
        variable "key_path" {
          description = "Path to the public key for SSH access."
          type        = string
          default     = "~/.ssh/aws-stage.pub"
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

## 3. Contribute

Contribution guidelines and project management tools.

### 3.1. Task Runner

#### 3.1.1. Make

[Make](https://www.gnu.org/software/make/) is a automation tool that defines and manages tasks to streamline development workflows.

1. Insights and Details

    - [Makefile](Makefile)
      > Makefile defining tasks for building, testing, and managing the project.

2. Usage and Instructions

    - Tasks

      ```bash
      make help
      ```

      > [!NOTE]
      > - Each task description must begin with `##` to be included in the task list.

      ```plaintext
      $ make help

      Tasks
              A collection of tasks used in the current project.

      Usage
              make <task>

              bootstrap         Initialize a software development workspace with requisites
              setup             Install and configure all dependencies essential for development
              teardown          Remove development artifacts and restore the host to its pre-setup state
      ```

### 3.2. Bootstrap

#### 3.2.1. Scripts

[scripts/](scripts/README.md) provides scripts to bootstrap, setup, and teardown a software development workspace with requisites.

1. Insights and Details

    - [bootstrap.sh](scripts/bootstrap.sh)
      > Initializes a software development workspace with requisites.

    - [setup.sh](scripts/setup.sh)
      > Installs and configures all dependencies essential for development.

    - [teardown.sh](scripts/teardown.sh)
      > Removes development artifacts and restores the host to its pre-setup state.

2. Usage and Instructions

    - Tasks

      ```bash
      make bootstrap
      ```

      ```bash
      make setup
      ```

      ```bash
      make teardown
      ```

### 3.3. Release Manager

#### 3.3.1. Semantic-Release

[Semantic-Release](https://github.com/semantic-release/semantic-release) automates the release process by analyzing commit messages to determine the next version number, generating changelog and release notes, and publishing the release.

1. Insights and Details

    - [.releaserc.json](.releaserc.json)
      > Configuration file for Semantic-Release specifying release rules and plugins.

2. Usage and Instructions

    - CI/CD

      ```yaml
      uses: sentenz/actions/semantic-release@latest
      ```

### 3.4. Update Manager

#### 3.4.1. Renovate

[Renovate](https://github.com/renovatebot/renovate) automates dependency updates by creating merge requests for outdated dependencies, libraries and packages.

1. Insights and Details

    - [renovate.json](renovate.json)
      > Configuration file for Renovate specifying update rules and schedules.

2. Usage and Instructions

    - CI/CD

      ```yaml
      uses: sentenz/actions/renovate@latest
      ```

#### 3.4.2. Dependabot

[Dependabot](https://github.com/dependabot/dependabot-core) automates dependency updates by creating pull requests for outdated dependencies, libraries and packages.

1. Insights and Details

    - [.github/dependabot.yml](.github/dependabot.yml)
      > Configuration file for Dependabot specifying update rules and schedules.

### 3.5. Secrets Manager

#### 3.5.1. SOPS

[SOPS (Secrets OPerationS)](https://github.com/getsops/sops) is a tool for managing and encrypting sensitive data such as passwords, API keys, and other secrets.

1. Insights and Details

    - [.sops.yaml](.sops.yaml)
      > Configuration file for SOPS specifying encryption rules and key management.

2. Usage and Instructions

    - GPG Key Pair Generation

      - Tasks
        > Generate a new key pair to be used with SOPS.

        > [!NOTE]
        > The UID can be customized via the `SECRETS_SOPS_UID` variable (defaults to `sops-tf`).

        ```bash
        make secrets-gpg-generate SECRETS_SOPS_UID=<uid>
        ```

    - GPG Public Key Fingerprint

      - Tasks
        > Print the  GPG Public Key fingerprint associated with a given UID.

        ```bash
        make secrets-gpg-show SECRETS_SOPS_UID=<uid>
        ```

      - [.sops.yaml](.sops.yaml)
        > The GPG UID is required for populating in `.sops.yaml`.

        ```yaml
        creation_rules:
          - pgp: "<fingerprint>" # <uid>
        ```

    - SOPS Encrypt/Decrypt

      - Tasks
        > Encrypt/decrypt one or more files in place using SOPS.

        ```bash
        make secrets-sops-encrypt <files>
        ```

        ```bash
        make secrets-sops-decrypt <files>
        ```

### 3.6. Policy Manager

#### 3.6.1. HashiCorp Sentinel

[HashiCorp Sentinel](https://www.hashicorp.com/sentinel) is a **Policy as Code (PaC)** framework embedded in the HashiCorp Enterprise products to enable fine-grained, logic-based and conditional policy decisions.

1. Insights and Details

    - [sentinel.hcl](sentinel.hcl)
      > Configuration file for Sentinel specifying policy enforcement levels.

    - [tests/policy](tests/policy/)
      > Directory contains Sentinel policies to enforce best practices and compliance standards.

2. Usage and Instructions

    - Tasks

      ```bash
      make tf-test-policy
      ```


### 3.7. Supply Chain Manager

#### 3.7.1. Trivy

[Trivy](https://github.com/aquasecurity/trivy) is a comprehensive security scanner for vulnerabilities, misconfigurations, and compliance issues in container images, filesystems, and source code.

1. Insights and Details

    - [trivy.yaml](trivy.yaml)
      > Configuration file for Trivy specifying scan settings and options.

    - [.trivyignore](.trivyignore)
      > File specifying vulnerabilities to ignore during Trivy scans.

2. Usage and Instructions

    - CI/CD

      ```yaml
      uses: sentenz/actions/trivy@latest
      ```

    - Tasks

      ```bash
      make sast-trivy-fs <path>
      ```

      ```bash
      make sast-trivy-sbom-cyclonedx-fs <path>
      ```

      ```bash
      make sast-trivy-sbom-scan <sbom_path>
      ```

      ```bash
      make sast-trivy-sbom-license <sbom_path>
      ```

## 4. Troubleshoot

### 4.1. Snapshot

#### 4.1.1. Restore Snapshot

Restore an EBS volume from an [EBS snapshot](https://docs.aws.amazon.com/prescriptive-guidance/latest/backup-recovery/restore.html#restore-snapshot).

> [!NOTE]
> Ensure the snapshot is in the same region as the AWS EC2 instance. The restored volume must have the same size and data as the snapshot.

1. Identify Snapshot ID

    Find the ID of the snapshot to restore from.

    - AWS Management Console
      > Navigate to `EC2 > Snapshots` to locate the desired snapshot ID (e.g., `snap-xxxxxxxxxxxxxxxxx`).

    - AWS CLI
      > Run the the command to list snapshots owned by the account based the assigned role.

      ```bash
      aws ec2 describe-snapshots --owner-ids self
      ```

2. Terraform Resources

    Configure the `ebs_data_snapshot_id` variable to the desired **Snapshot ID**.

    - `variables.tf`
      > Define the Snapshot ID variable in variables.tf with the identified snapshot ID.

      ```hcl
      variable "ebs_data_snapshot_id" {
        description = "Snapshot ID to use for the data EBS volume."
        type        = string
        default     = "snap-xxxxxxxxxxxxxxxxx"
      }
      ```

3. Terraform Deployment

    Create a new EBS volume from the snapshot and attach it to the EC2 instance.

    - Terraform CLI
      > Run the standard Terraform workflow to apply the new configuration.

      ```bash
      terraform plan
      terraform apply
      ```

> [!TIP]
> If required, access after Terraform applies the changes the EC2 instance via SSH.
>
> - Verification of the new device (e.g., `/dev/sdf`) recognition can be done using commands like `lsblk`.
> - Reboot the EC2 instance after attaching the restored volume is initialized to ensure the device is properly recognized and mounted.

### 4.2. Inspect Drifts

Inspect the mappings of the instances to triage current state.

- Device Name Collision in EBS Volume
  > In Terraform, ensure each attachment has a unique `device_name` across all modules/instances. If a prior failed run left a pending attachment, detach or change the device name before re-applying.

  ```bash
  AWS_PROFILE=stage aws --region eu-central-1 ec2 describe-instances \
    --instance-ids i-09fde7f2773e81450 \
    --query 'Reservations[].Instances[].BlockDeviceMappings[].{DeviceName:DeviceName,VolumeId:Ebs.VolumeId}'
  ```

### 4.3. Extend Volume

- [Extend File System](https://docs.aws.amazon.com/ebs/latest/userguide/recognize-expanded-volume-linux.html)
  > After increasing the size of an EBS volume, extend the partition and filesystem to use the additional capacity.

  > [!TIP]
  > Perform the file system extension as soon as the volume enters the **optimizing** state.

### 4.4. State Migration

When a module or resource path is refactored but the actual infrastructure remains the same, migrate the Terraform state to the new addresses instead of recreating resources.

1. Backup State

    Backup the state file in the environment directory before any changes.

    ```bash
    cd environments/<env>/<component>
    cp terraform.tfstate terraform.tfstate.backup.$(date +%s)
    ```

2. Inspect State

    Inspect current state addresses to determine the exact source addresses to move.

    ```bash
    cd environments/<env>/<component>
    terraform state list
    ```

3. Migrate State

    For each affected resource, run `terraform state mv` to move state from the old address to the new one.

    > [!NOTE]
    > Use the exact addresses printed by `terraform state list` as the source and the resource addresses as defined in the refactored configuration as the destination.

    ```bash
    cd environments/<env>/<component>
    terraform state mv 'module.old.module.path.aws_instance.example[0]' 'module.new.module.path.aws_instance.example[0]'
    ```

4. Plan State

    Re-run `terraform plan` to verify there are no additions or destructions.

    ```bash
    terraform plan
    ```

    If `terraform plan` still shows changes, inspect the differences and either adjust the state mappings or the configuration.

    > [!IMPORTANT]
    > If unsure, restore the backup and ask for help.

    ```bash
    mv terraform.tfstate.backup.<timestamp> terraform.tfstate
    ```

## 5. References

- HashiCorp [Terraform Style Guide]([TODOs](https://developer.hashicorp.com/terraform/language/style)) page.
- Sentenz [Template DX](https://github.com/sentenz/template-dx) repository.
- Sentenz [Actions](https://github.com/sentenz/actions) repository.
- Sentenz [Manager Tools](https://github.com/sentenz/convention/issues/392) article.
