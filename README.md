# Terraform AWS

A Terraform module collection to provision infrastructure for deploying on AWS.

- [1. Details](#1-details)
  - [1.1. Modules](#11-modules)
- [2. Usage](#2-usage)
  - [2.1. Authentication](#21-authentication)
    - [2.1.1. AWS Credential Chain](#211-aws-credential-chain)
    - [2.1.2. SSH Key Pair](#212-ssh-key-pair)
  - [2.2. CI/CD](#22-cicd)
- [3. Contribution](#3-contribution)
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

#### 2.1.1. AWS Credential Chain

Terraform uses the standard AWS SDK credential chain rather than hard-coding a shared-credentials profile in provider or backend configuration. The same roots therefore work with short-lived local credentials and GitHub Actions OIDC.

For local development, prefer AWS IAM Identity Center/SSO and select the intended account outside HCL:

```bash
AWS_PROFILE=stage make tf-ec2-deploy TF_ENV=stage
AWS_PROFILE=prod make tf-ec2-deploy TF_ENV=prod
```

Do not use broad administrator access as the default Terraform identity. Grant only the permissions required by the target stack and state backend.

For GitHub Actions, the optional manual plan workflow uses GitHub OIDC to assume an environment-specific AWS IAM role. No AWS access key ID or secret access key is stored in GitHub. Configure the `stage` and/or `prod` GitHub Environments with:

- `AWS_ROLE_ARN` — environment-specific IAM role ARN trusted for this repository/environment.
- `AWS_REGION` — AWS region for STS/API operations (the included stacks use `eu-central-1`).

The AWS role trust policy should require `aud=sts.amazonaws.com` and an environment-specific `sub`, for example `repo:sentenz/template-terraform:environment:stage`. Production should use a distinct role and required reviewers on the `prod` GitHub Environment.

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

## 2.2. CI/CD

This repository is a reusable Terraform template/module collection, so it does not automatically apply infrastructure. Pull requests run fast, non-privileged validation; cloud-authenticated planning is an explicit manual operation.

```text
Terraform-relevant PR/push
        |
        +-- format + TFLint
        +-- native mocked unit tests
        +-- Sentinel policy tests
        +-- Trivy Terraform configuration scan
        |
        +-- discover roots from main.tf + versions.tf
                 |
                 +-- init -backend=false + validate (matrix)

workflow_dispatch: Terraform Plan
        |
        +-- validate deployable root
        +-- protected GitHub Environment
        +-- GitHub OIDC -> environment AWS role
        +-- remote-backend init + plan
        +-- sanitized change counts only
```

Runnable Terraform roots are discovered from repository structure; `.gitkeep` placeholders are ignored. Shared-module changes therefore validate all active roots rather than relying on a brittle stack list.

The manual plan workflow accepts a deployable path such as `environments/stage/ec2`. Full plan output and binary plan files remain runner-local because this repository is public. No workflow performs `terraform apply`. Consumers that add deployment automation should apply only a reviewed plan behind a protected GitHub Environment and stack-specific non-canceling concurrency.

Fast local equivalents:

```bash
make tf-format-check
make tf-lint-infra
make tf-test-unit
make tf-test-policy
make tf-discover-roots
make tf-validate-root TF_ROOT=environments/stage/ec2
```

Real-cloud integration tests are excluded from ordinary PR CI. They require a dedicated non-production AWS identity and explicit opt-in:

```bash
TF_INTEGRATION_CONFIRM=1 make tf-test-integration
```

The S3 backends retain `encrypt = true` and Terraform native `use_lockfile = true`. Backend bootstrap is a separate lifecycle and is not created by the roots that consume it.

## 3. Contribution

[CONTRIBUTING.md](CONTRIBUTING.md) provides guidance and instructions for contributing to the project.

- [AI Agents](CONTRIBUTING.md#1-ai-agents)
  > Automated tools that assist in various development tasks such as code generation, testing, and documentation.

- [Skills Manager](CONTRIBUTING.md#2-skills-manager)
  > CLI tool for managing AI agent skills in development projects.

- [Task Runner](CONTRIBUTING.md#3-task-runner)
  > Make automation tool that defines and manages tasks to streamline development workflows.

- [Bootstrap](CONTRIBUTING.md#4-bootstrap)
  > Scripts to bootstrap, setup, and teardown a software development workspace with requisites.

- [Dev Containers](CONTRIBUTING.md#6-dev-containers)
  > Consistent development environments using Docker containers.

- [Release Manager](CONTRIBUTING.md#7-release-manager)
  > Semantic-Release automates the release process by analyzing commit messages.

- [Update Manager](CONTRIBUTING.md#8-update-manager)
  > Renovate and Dependabot automate dependency updates by creating pull requests.

- [Secrets Manager](CONTRIBUTING.md#9-secrets-manager)
  > SOPS for managing and encrypting sensitive data such as passwords, API keys, and other secrets.

- [Container Manager](CONTRIBUTING.md#10-container-manager)
  > Docker containerization tool to run applications in isolated container environments.

- [Policy Manager](CONTRIBUTING.md#112-hashicorp-sentinel)
  > Conftest for policy-as-code enforcement.

- [Supply Chain Manager](CONTRIBUTING.md#13-supply-chain-manager)
  > Trivy for security scanning of vulnerabilities, misconfigurations, and compliance issues.

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

1. Preserve a Recovery Point

    The included stacks use remote S3 state. Prefer S3 bucket versioning as the durable recovery mechanism. If a temporary local snapshot is required, pull it explicitly, restrict its permissions, never commit or upload it, and remove it after the migration is verified.

    ```bash
    cd environments/<env>/<component>
    umask 077
    terraform state pull > "/tmp/terraform-state-backup-$(date +%s).json"
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
- Sentenz [Manager Tools](https://sentenz.github.io/convention/articles/manager-tools/) article.
