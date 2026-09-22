# HashiCorp Terraform skills review

Reviewed against `hashicorp/agent-skills` commit
`c2d65dfe492f74d360d35b859b88932222470bd8`, starting from project commit
`879015f288abd1d7637f6d7601f08ee183b2d755`.

## Skill selection

All 16 Terraform skill descriptions were scanned. Guidance was applied to the
project rather than installing another copy of the skill catalog.

| Skill | Application |
| --- | --- |
| `terraform-style-guide` | Module argument ordering, descriptive outputs, validation and formatting gates. Existing `versions.tf` layout and pinned dependencies retained. |
| `terraform-test` | Explicit module selection, mock AWS providers, plan-mode positive/negative tests, opt-in integration suite, PR test job. CLI examples were checked for file-path filtering; unit tests do not assert unknown computed values. |
| `refactor-module` | Typed interface review, upstream input compatibility, documented contracts, preserving managed-resource addresses. No module extraction or state migration. |
| `terraform-policy` | Not activated: existing policies use Sentinel; no Terraform Policy migration requested. |
| `terraform-stacks`, `terraform-search-import` | Not applicable to this conventional module repository; no Stacks or import scope. |
| `azure-verified-modules` | Not applicable to AWS. |
| Provider development skills (9) | Not applicable: this repository consumes providers and does not implement one. Includes scaffolding, actions, configuration, documentation, ephemeral resources, framework migration, resources, test patterns and acceptance tests. |

Sources: [HashiCorp Terraform skills](https://github.com/hashicorp/agent-skills/tree/c2d65dfe492f74d360d35b859b88932222470bd8/plugins/terraform/skills)
and the existing `.agents/skills/terraform` project guidance.

## Findings addressed

- EKS referenced an undefined `local.vpc_name`. The name now derives from the module input.
- EC2 still called the security-group v5 interface despite pinning v6. Restored the v6 rule-map adapter from project history (`8c29b21`) and its `id` output, retaining historical rule keys and splitting comma-separated custom CIDRs. Named presets are explicitly validated as HTTP, HTTPS or SSH; other ingress ports use custom tuples.
- EKS passed list-shaped taints to the pinned EKS module's map-shaped input. The wrapper now converts its existing public list interface to a map keyed by taint key/effect.
- EC2 key loading now expands `~` and only evaluates the file when key-pair creation is enabled.
- EC2 network selection now follows `vpc_create` explicitly instead of falling through `coalesce`; created-network mode requires a public subnet.
- IPv4/IPv6 ingress validation now parses CIDRs and rejects any zero-length prefix, including noncanonical representations. Every comma-separated IPv4 tuple entry is checked.
- EKS default node-group scaling requires integer sizes and a desired size within minimum/maximum bounds.
- Tests previously had no selected module and used a real AWS profile. Contract suites now select modules explicitly, mock dependencies and run in CI.
- CI previously failed TFLint on unused declarations, preventing validation. Unused staging subnet lookups and the unused EC2 naming local were removed; the staging subnet override is now honored and EKS environment connection values are exposed as outputs.
- The unrelated EKS AMI lookup was removed. Its legacy `ami_*` inputs remain as documented no-ops for caller compatibility, with narrowly scoped lint suppressions.
- CI watches lock-file changes and validates reusable modules as well as environments.

## Execution context and limits

Terraform runtime floor remains 1.10; CI remains pinned to 1.16.3. AWS stays
within major version 6. Existing provider/module pins and per-environment S3
backends with encryption and lock files are retained. No backend initialization,
production plan, apply, destroy or state migration was performed during review.

The changes address testing blind spots, CI drift and input-contract gaps.
Top-level module addresses remain stable. The restored v6 adapter retains the
historical single-CIDR rule keys, but installations with older v5 security-group
state need a reviewed rule migration plan. Stricter validation may reject
previously accepted invalid input; the staging subnet override now takes effect
when explicitly supplied. Review an environment plan before rollout.

Exact validation commands and the distinction between mocked and live testing
are documented in [tests/README.md](../tests/README.md).

## Follow-up requiring deployment context

The existing Pod Identity wrapper passes `role_name`, `policy_arns` and
`policies_json` inside association objects, but upstream version 2.9.0 accepts
role names and policies at module scope. Those per-association fields are not
honored. Correct per-service-account roles require splitting the singleton module
into named instances and reviewing existing IAM/association state. This is
recorded rather than guessing a migration or broadening shared role permissions.

The existing environment-specific account/profile, backend, AMI and snapshot
choices also require deployment-owner review. A provider upgrade, Sentinel
migration, IAM redesign and backend migration are separate changes.
