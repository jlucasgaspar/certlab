# Stage bootstrap conventions

This page records the approved decisions for bootstrapping the stage environment (roadmap phase 1.2). The implementation issues that follow (AWS Organization, Terraform foundation, OIDC, Neon) apply these decisions and must not choose alternatives. A change to any decision needs new evidence and an explicit maintainer decision, recorded here. See [ADR-0006](adr/0006-infrastructure-aws-terraform.md) for the underlying choices and [design.md](design.md) section 6 for the architecture.

The repository is public. This page contains no account IDs, aliases, e-mail addresses, project IDs, ARNs, credentials or connection strings. See [Private identifiers](#private-identifiers).

## AWS accounts

- A Certlab-controlled AWS Organization holds the accounts.
- The **management account**, named `certlab-admin`, is used only for AWS Organizations, billing, AWS Budgets and IAM Identity Center. No Certlab workload runs in it.
- The organizational unit `Workloads` contains the member account `certlab-stage`.
- `certlab-prod` is deferred to phase 3. Security Tooling, Log Archive, Control Tower and a corporate landing zone are out of scope.
- The maintainer's personal AWS account stays outside the Organization. Human access never relies on it.

## Human access and root

- Humans sign in through IAM Identity Center with temporary sessions and MFA. No long-lived access keys exist for people or workloads.
- The project owner and the tech lead are separate Identity Center identities. Permission sets are assigned to groups, never to individual users, so a future team member only needs to join a group:
  - Group `Owners` holds `certlab-owner`, backed by the Certlab project e-mail. It has `CertlabAdministrator` and `CertlabReadOnly` on `certlab-admin` and on `certlab-stage`, uses the read-only set for everyday inspection and verification, and makes every IAM, Organizations, billing and permission change.
  - Group `TechLeads` holds the maintainer's tech lead user (`joselucas`), backed by the maintainer's personal e-mail. It has `CertlabTechLead` and `CertlabReadOnly` on `certlab-stage`, and no access to `certlab-admin`. It cannot change IAM, Organizations or billing.
  - Groups for other roles, such as a read-only developer group, are created when a person needs them.
- Humans do not create resources as the normal flow. Terraform creates them through CI (see [Terraform state and CI identity](#terraform-state-and-ci-identity)). Console changes by the tech lead in stage are allowed for exploration, and anything created by hand is either imported into Terraform or removed. Production is read-only for humans.
- Three permission sets are defined:
  - `CertlabReadOnly` for everyday inspection (`ReadOnlyAccess`).
  - `CertlabTechLead` for operating stage resources (`PowerUserAccess`: everything except IAM, Organizations and account management).
  - `CertlabAdministrator` for administrative changes and bootstrap (`AdministratorAccess`).
- The owner must be able to open Billing and Budgets in a temporary session. If it cannot, enable billing access for IAM and Identity Center roles in the management account settings.
- Access to `certlab-prod` is decided in phase 3 with the same model: `Owners` keep `CertlabAdministrator` for emergencies, the tech lead gets `CertlabReadOnly`, and no human gets write access without a recorded decision.
- The management account root user has MFA and no access keys. It is reserved for recovery and for tasks that only root can do. Its e-mail is the Certlab project e-mail, never a personal one.
- The Terraform steps that create IAM roles and policies (state backend, OIDC) run in an owner session. The tech lead identity cannot create them.
- Centralized root access is enabled for member accounts, and persistent root credentials are removed from them.

## Manual governance

The Organization, Identity Center, the OU, the member account, assignments, centralized root access and the budget are created manually in the console. They are not managed by the public application Terraform. Workloads in `certlab-stage` are managed by Terraform.

Agents do not create, change or delete external resources. The maintainer runs the manual steps, and agents verify read-only. The ordered procedure, the read-only checks, recovery and the periodic review are in [aws-organization-runbook.md](aws-organization-runbook.md).

## Budget

A monthly AWS Cost Budget of USD 10 (`certlab-stage-monthly`) applies to the whole Organization, with no account filter. The management account runs no workloads, so the cost is the stage cost. It alerts and does not block spending. The alerts are:

- actual spend at 50%, 80% and 100%;
- forecasted spend at 100%.

Notifications go to private recipients (the project e-mail and the maintainer). The maintainer confirms receipt of a test or first alert and records only that confirmation (date and outcome) in the pull request or issue, never the address.

## Region and database parameters

| Parameter | Value | Rationale |
|---|---|---|
| AWS primary region (stage) | `us-east-1` | Lowest cost, broadest and earliest service availability for the phase 1 services (Lambda, HTTP API, S3, CloudFront, SSM). CloudFront certificates (ACM) must live in `us-east-1` regardless. |
| Neon cloud and region | AWS `aws-us-east-1` | Same region as the stage Lambda, so runtime queries stay inside one region and the network distance is minimal. Available on the free plan. |
| PostgreSQL major (stage) | 17 | Stable and available on Neon and RDS, which keeps stage and the phase 3 production database on the same major. |

The latency from a phone in Brazil to `us-east-1` is higher than to `sa-east-1`. This is accepted for stage because the environment is used by one person and cost matters more. Revisit the region for production in phase 3 with its own decision.

### PostgreSQL compatibility

- Stay on plain PostgreSQL features. Do not depend on Neon-only behavior in schema, queries or migrations.
- Run migration tests in CI against vanilla PostgreSQL 17, the same major as stage. Upgrade stage, CI and production together when the major changes.
- Runtime connections use the Neon pooled endpoint. Migrations and operations that need a continuous session use the direct endpoint.

## Naming and tags

- Resource names follow `certlab-<environment>-<purpose>`, lowercase and hyphen-separated, for example `certlab-stage-tfstate`. Where AWS requires a globally unique name, add a suffix supplied privately (see below) instead of publishing the unique value.
- Every taggable resource carries these tags:

| Tag | Value |
|---|---|
| `project` | `certlab` |
| `environment` | `stage` |
| `managed-by` | `terraform` for Terraform resources, `manual` for console-created governance resources |
| `owner` | `certlab-maintainer` (a role name, not a person's e-mail) |

Terraform sets these through the provider's default tags.

## Terraform state and CI identity

- The remote state backend lives in `certlab-stage`: an S3 bucket with versioning and native state locking. No state or credentials are committed.
- The first `terraform apply` that creates the backend uses a temporary IAM Identity Center session with `CertlabAdministrator`. After that, the stage environment uses the remote backend, and CI reaches AWS by OIDC.
- GitHub Actions uses the GitHub Environment `stage`. The role trust policy is limited to the exact subject `repo:jlucasgaspar/certlab:environment:stage`.
- Pull request workflows and forks never receive AWS credentials. A stage deploy runs from reviewed code on `main`.

## Neon and secrets

- The Neon project is created manually in the console. The official `neondatabase/neon` Terraform provider is outside phase 1.2 because it is still beta and needs an extra API key.
- The initial Neon credentials stay in the maintainer's private storage, never in the repository or in GitHub.
- In phase 1.4, create separate runtime and migration roles and store their connection URLs in SSM Parameter Store as `SecureString`. They do not go in GitHub secrets.
- Secrets Manager is reserved for when automatic rotation, production controls or cross-account access justify its cost and complexity.
- If Terraform provisions secret values in the future, use write-only arguments such as `value_wo` (Terraform 1.11 or later) fed by an `ephemeral` input variable or ephemeral resource. A write-only argument alone keeps the value out of state, but a non-ephemeral input can still be stored in a saved plan.

## Private identifiers

The following values are never published in this repository, in issues or in pull requests:

- AWS account IDs and aliases, root and notification e-mail addresses, Neon project IDs, real ARNs, credentials, connection strings and privately chosen globally unique names.

The maintainer keeps them in private storage (a password manager). Implementation steps refer to them by role, for example "the stage account e-mail alias". Terraform receives any needed identifier from untracked local variable files or the environment at apply time. A pull request records only that a step was done and verified, not the value.

## Cost rules for stage

Stage stays close to zero cost. Avoid NAT Gateway, ALB, unnecessary public IPv4 addresses, RDS and any paid service without a justification and a monthly estimate in the pull request.
