# Terraform tests

Run commands from the repository root with Terraform 1.10 or newer. CI uses
the existing pinned Terraform 1.16.3 runtime. The repository root is a test
harness: each run block explicitly selects an environment or reusable module.

## Unit tests

```sh
make tf-test-unit
```

The target initializes the modules referenced by `tests/unit`, then runs
plan-mode contract tests without AWS credentials. AWS data sources are mocked
and upstream modules are overridden. Tests cover EC2 existing/created network
selection, optional SSH keys, output forwarding, trusted and invalid ingress
CIDRs, EKS naming and sizing validation, and staging/production EC2 inputs.

These tests check wrapper contracts, not AWS API behavior or the internals of
third-party modules. CI also validates both reusable modules and all three
configured environments against their installed dependencies.

To select a file, use its path (not a run-block name):

```sh
terraform init -backend=false -input=false -test-directory=tests/unit
terraform test -test-directory=tests/unit -filter=tests/unit/aws_ec2_unit_test.tftest.hcl
```

## Integration test (opt-in)

The integration suite provisions an EC2 instance and security group in an
existing test VPC in `eu-central-1`. It incurs AWS charges. Use a sandbox AWS
account with standard AWS credentials and supply a subnet belonging to the
specified VPC. No production backend or named production profile is used.

```sh
export TF_VAR_vpc_id=vpc-REPLACE
export TF_VAR_ec2_subnet_id=subnet-REPLACE
make tf-test-integration
```

Terraform tests use their own state and attempt cleanup at completion. If
interrupted or cleanup fails, inspect the reported remaining test resources
and remove them through the normal reviewed cleanup process. Integration tests
are deliberately excluded from the pull-request workflow.

## Static validation

```sh
terraform fmt -check -diff -recursive
terraform -chdir=modules/aws-ec2 init -backend=false -input=false
terraform -chdir=modules/aws-ec2 validate
terraform -chdir=modules/aws-eks init -backend=false -input=false
terraform -chdir=modules/aws-eks validate
tflint --init
tflint --recursive
```

Initialize and validate each environment separately before planning deployment.
Cloud-backed plans and integration tests require the appropriate AWS access;
mocked unit-test success does not establish that an infrastructure plan is safe.
