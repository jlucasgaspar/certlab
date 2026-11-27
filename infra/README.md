# Infrastructure

Terraform for Certlab. Everything in AWS is declared here, except the governance resources described in [docs/aws-organization-runbook.md](../docs/aws-organization-runbook.md). The decisions behind this layout are in [ADR-0006](../docs/adr/0006-infrastructure-aws-terraform.md), [docs/design.md](../docs/design.md) section 6 and [docs/stage-bootstrap.md](../docs/stage-bootstrap.md).

The repository is public. It contains no account IDs, bucket names, state or credentials. Private values live in local files that Git ignores (see [Private values](#private-values)).

## Layout

| Path | Purpose |
|---|---|
| `modules/state-backend/` | Private, versioned, encrypted S3 bucket for Terraform state, with native lock files. |
| `bootstrap/stage/` | Creates the stage state bucket. First applied with local state, then migrated into the bucket. |
| `envs/stage/` | The stage environment. It stores state in the bucket from `bootstrap/stage`. It has no workload yet. |

`envs/prod/` arrives in phase 3.

## Versions

- Terraform `1.17.2`, pinned in `.terraform-version`. The roots accept `~> 1.17`, and `scripts/validate-terraform.sh` fails when the installed version differs from the pinned one.
- AWS provider `~> 6.74`. Each root commits its `.terraform.lock.hcl` with hashes for `darwin_arm64` and `linux_amd64`. Update it with `terraform providers lock -platform=darwin_arm64 -platform=linux_amd64` in the root.
- State locking uses `use_lockfile = true`, so there is no DynamoDB table. This needs Terraform 1.10 or later.

## Validate (no AWS access)

```sh
scripts/validate-terraform.sh
```

It runs `terraform fmt -check`, then `init -backend=false -lockfile=readonly` and `validate` for every root. It never contacts AWS and CI runs the same script in the `Terraform` job.

## Private values

These files are ignored by Git. Copy each `*.example` file and replace the placeholders.

| File | Where | Content |
|---|---|---|
| `stage.local.tfvars` | `bootstrap/stage/` and `envs/stage/` | The `certlab-stage` account ID and, for the bootstrap, the private bucket suffix. |
| `backend.local.hcl` | `bootstrap/stage/` and `envs/stage/` | The full bucket name: `certlab-stage-tfstate-` followed by the private suffix. |
| `backend.tf` | `bootstrap/stage/` | Copy of `backend.tf.example`, used only for the state migration. |

The provider refuses to run when the credentials belong to another account (`allowed_account_ids`). This blocks an apply in the management account by mistake.

## Bootstrap the stage state backend (maintainer, once)

The maintainer runs this. Agents never run `apply`. Use a temporary IAM Identity Center session for `certlab-stage` with `CertlabAdministrator`, as the `certlab-owner` user. Do not use the root user or access keys.

1. Configure an AWS CLI profile for `certlab-stage` and the `CertlabAdministrator` role with `aws configure sso`, then `aws sso login --profile <profile>` and `export AWS_PROFILE=<profile>`. The profile name stays private.
2. `cd infra/bootstrap/stage`, create `stage.local.tfvars` and `backend.local.hcl` from the examples.
3. `terraform init`, then `terraform plan -var-file=stage.local.tfvars -out=tfplan`. The plan must contain exactly these 6 resources and nothing else: the bucket, its public access block, ownership controls, versioning, encryption configuration and bucket policy.
4. `terraform apply tfplan`.
5. Migrate the bootstrap state into the new bucket:
   ```sh
   cp backend.tf.example backend.tf
   terraform init -migrate-state -backend-config=backend.local.hcl
   ```
   Answer `yes`. Then `terraform plan -var-file=stage.local.tfvars` must show no changes.
6. Confirm the state object exists in the bucket. Only then delete the local `terraform.tfstate*` files in `bootstrap/stage/`, and the `tfplan` file.
7. Initialize the stage environment against the bucket:
   ```sh
   cd ../../envs/stage
   terraform init -backend-config=backend.local.hcl
   terraform apply -var-file=stage.local.tfvars
   ```
   There is nothing to create. The apply writes an empty state and takes and releases the lock, which proves the backend works.
8. Share only a sanitized result in the pull request or issue: which steps ran, the date and that the plan had no unexpected change. Never share the bucket name, account ID, state or plan files.

An agent can then verify the bucket read-only with the `certlab-owner` `CertlabReadOnly` session on `certlab-stage`: versioning, encryption, public access block, ownership controls, the TLS-only policy and the tags.

## Recovery

- **Lost bootstrap state before the migration (step 5).** Nothing else depends on it yet. Import the six resources into a fresh `bootstrap/stage` with `terraform import`, using the bucket name for all of them, then continue from step 5. If the bucket does not exist, apply again.
- **Lost or damaged remote state.** The bucket is versioned. List the versions of the state object with `aws s3api list-object-versions`, restore the last good one by copying it over the current key, then run `terraform plan` and check it shows no unexpected change.
- **Stuck lock.** A crashed run can leave `<key>.tflock` in the bucket. Make sure nobody is running Terraform, then `terraform force-unlock <lock-id>` with the ID from the error message.
- **Destroying the bucket.** `prevent_destroy` blocks it. Removing that protection and emptying the versions needs a recorded maintainer decision, because it deletes the state of every environment that uses the bucket.

## Cost

The state bucket holds a few kilobytes of state and versions. S3 storage and requests cost far less than USD 0.01 per month, and SSE-S3 encryption, versioning, public access block and bucket policy add no charge. There is no KMS key, no DynamoDB table and no replication.
