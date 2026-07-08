# Changelog

## [1.0.2](https://github.com/sentenz/template-terraform/compare/1.0.1...1.0.2) (2026-07-08)


### Bug Fixes

* **terraform:** add prod ec2 network data sources ([662ce7c](https://github.com/sentenz/template-terraform/commit/662ce7cceb0a48824fb5088c35d01010438d1f08))
* **terraform:** align prod ec2 version constraints ([8fcaf62](https://github.com/sentenz/template-terraform/commit/8fcaf6292d37b990ea73526851b61b9398e71890))
* **terraform:** align stage ec2 version constraints ([f323e9a](https://github.com/sentenz/template-terraform/commit/f323e9a3a1919ea8dc57b77b9242b809384d1f85))
* **terraform:** align stage eks version constraints ([fc50e89](https://github.com/sentenz/template-terraform/commit/fc50e897ab0d934b3c3b2ff0521b4bcf14e310a4))
* **terraform:** complete eks variable contract ([b299610](https://github.com/sentenz/template-terraform/commit/b2996103fc967f84e2275ef69c12d07c98c82619))
* **terraform:** complete prod ec2 variable contract ([7e709bf](https://github.com/sentenz/template-terraform/commit/7e709bf5ea13178b161b01e5e1585b0d95333046))
* **terraform:** harden ec2 module inputs ([05e7eb3](https://github.com/sentenz/template-terraform/commit/05e7eb3c2dfcf7d09b934e0657a49e3890d00031))
* **terraform:** harden stage ec2 defaults ([42ad92a](https://github.com/sentenz/template-terraform/commit/42ad92a75337ccaadbba2f78651b08aa02fbc3a2))
* **terraform:** keep stage eks composition single-purpose ([794580c](https://github.com/sentenz/template-terraform/commit/794580c0852164754a000f7559121ec5c2d45f44))
* **terraform:** normalize stage eks variables ([9b65969](https://github.com/sentenz/template-terraform/commit/9b65969c54f31e8494f3660d14a568b59db2ba1d))
* **terraform:** pin ec2 provider major versions ([3b62ab0](https://github.com/sentenz/template-terraform/commit/3b62ab00c9d2ac12b5c947dc5384fb93229be5e8))
* **terraform:** pin eks provider major versions ([75445e5](https://github.com/sentenz/template-terraform/commit/75445e595c92025e7d10a7881bed54804a901876))
* **terraform:** point prod ec2 at ec2 module ([5ce416b](https://github.com/sentenz/template-terraform/commit/5ce416b4fd286bd1feb0f009d41b3e89e38584b9))
* **terraform:** remove eager eks auth data sources ([3dcce4b](https://github.com/sentenz/template-terraform/commit/3dcce4b866885d456fbd2dad0f9e0b9191bd2ad1))
* **terraform:** remove unused stage eks providers ([86d94ab](https://github.com/sentenz/template-terraform/commit/86d94ab7b9748b036d23a344e97c92b4420735f6))
* **terraform:** wire eks module inputs ([c021b62](https://github.com/sentenz/template-terraform/commit/c021b626d9ada404438a3a0d4f94cf717b8abb47))

## [1.0.1](https://github.com/sentenz/template-terraform/compare/1.0.0...1.0.1) (2026-04-16)


### Bug Fixes

* update dependabot.yml to scan Terraform module/environment directories ([1c58cf5](https://github.com/sentenz/template-terraform/commit/1c58cf50c21dd9c4c6f3d82745944ba9c78fc19b))
* use /*/** as unified glob pattern for Terraform directories ([a2a9dd4](https://github.com/sentenz/template-terraform/commit/a2a9dd43b9357839ad3a370a9bcec55cd0186251))
* use glob patterns in dependabot directories for Terraform ([0ffc847](https://github.com/sentenz/template-terraform/commit/0ffc84750a34ae6d10e5c6a5b62dd6d277a8cfd2))

# 1.0.0 (2026-01-05)


### Bug Fixes

* bump terraform major version to `v6` ([1596de5](https://github.com/sentenz/template-terraform/commit/1596de5d85dbb2e7010d3e611ffd1f5479b5eafb))
