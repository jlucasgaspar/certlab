# AWS Organization runbook

This runbook is the ordered, manual procedure that creates the AWS Organization, IAM Identity Center access, root protection and cost budget for stage (roadmap phase 1.2, LAB-21). It applies the decisions in [stage-bootstrap.md](stage-bootstrap.md) and must not choose alternatives. A change to a decision is recorded there first.

The repository is public. This page contains no account IDs, aliases, e-mail addresses, phone numbers, ARNs, QR codes or recovery data. Refer to private values by role (for example "the stage account e-mail alias") and keep them in the maintainer's password manager. See [Private identifiers](stage-bootstrap.md#private-identifiers).

## Responsibilities

- The **maintainer** runs every step that creates or changes an AWS resource or setting, in the console. Agents never do.
- **Agents** prepare this runbook, follow the maintainer through the steps, and verify the result with read-only calls (see [Read-only verification](#read-only-verification)).
- Nothing here is managed by the application Terraform. Organizations, Identity Center, accounts, assignments, root settings and the budget stay manual.

## Prerequisites

- LAB-20 is done and [stage-bootstrap.md](stage-bootstrap.md) is merged.
- A password manager holds the private values listed below. Create the entries before the steps that need them.
- A hardware key or an authenticator app is ready for MFA. Register at least two MFA devices for the root user of the management account.

Private values the maintainer stores (never published):

| Role | Used in |
|---|---|
| Management account root e-mail and password | Step 1 |
| Management account root MFA devices and recovery data | Step 7 |
| `certlab-stage` account e-mail alias | Step 5 |
| Identity Center e-mails for `certlab-owner` and `joselucas` | Step 3 |
| Budget alert recipient e-mail | Step 8 |

## Steps

Do the steps in order. After each one, record only "done" and the date in the pull request or issue, never an identifier.

### 1. Management account

1. Create a new AWS account controlled by Certlab, or designate one created for it. It must not be the maintainer's personal AWS account, which stays outside the Organization.
2. Use a dedicated e-mail address that the maintainer controls long term. It receives root and billing notices.
3. Set a long unique root password in the password manager.

Done when: the account exists and no workload will run in it.

### 2. Organization and `Workloads` OU

1. In AWS Organizations, create the Organization with all features enabled.
2. Create the organizational unit `Workloads` under the root.

Done when: the Organization shows one account (management) and one OU, `Workloads`.

### 3. IAM Identity Center

1. In `us-east-1`, enable IAM Identity Center with an **organization instance**.
2. Create two users in the Identity Center directory:
   - `certlab-owner`, with the Certlab project e-mail.
   - `joselucas`, the tech lead, with the maintainer's personal e-mail.
3. Require MFA at sign-in for all users (always-on, not context-aware), with an authenticator app or security key. Register a separate MFA device entry for each user.
4. Create the permission sets:
   - `CertlabReadOnly`: AWS managed policy `ReadOnlyAccess`. Everyday inspection.
   - `CertlabTechLead`: AWS managed policy `PowerUserAccess`. Operating stage resources, without IAM, Organizations or account management.
   - `CertlabAdministrator`: AWS managed policy `AdministratorAccess`. Bootstrap and administrative changes only.
5. Keep the session duration short: 1 hour for `CertlabAdministrator`, 4 hours for `CertlabTechLead` and up to 8 hours for `CertlabReadOnly`.

Done when: both users exist, MFA is required, and the three permission sets exist.

### 4. Management account root

1. Sign in as root once and enable MFA. Register two devices.
2. Confirm the root user has no access keys. Delete any that exist.
3. Sign out and test a second root sign-in with MFA so recovery is proven before it is needed.
4. From now on use root only for tasks that require it (see [Exceptional root use](#exceptional-root-use)).

Done when: root MFA is tested and there are zero root access keys.

### 5. Member account `certlab-stage`

1. In Organizations, create the member account named `certlab-stage` with a private, exclusive e-mail alias that is not used by any other AWS account.
2. Move it to the `Workloads` OU.
3. Do not create `certlab-prod`, Security Tooling, Log Archive or other accounts.

Done when: `certlab-stage` is `ACTIVE` inside `Workloads` and is the only member account.

### 6. Centralized root access

1. In IAM, under Root access management, enable **root credentials management** and **privileged root actions in member accounts** for the Organization.
2. Delete the persistent root credentials of `certlab-stage` (password, access keys, MFA, signing certificates) through centralized root access.
3. Confirm `certlab-stage` has no persistent root credentials.

Done when: centralized root access is enabled and `certlab-stage` has no persistent root credentials.

### 7. Assign access and test sign-in

1. Assign `certlab-owner` to the management account and to `certlab-stage` with `CertlabAdministrator`.
2. Assign `joselucas` to `certlab-stage` with `CertlabTechLead` and `CertlabReadOnly`, and to the management account with `CertlabReadOnly` only.
3. In the management account's account settings, enable **IAM user and role access to Billing information**. Without it, Identity Center sessions cannot open Billing or Budgets.
4. Sign in to the AWS access portal with MFA as `certlab-owner`. Open the management account and confirm it can open Organizations and Billing.
5. Sign in as `joselucas`. Open `certlab-stage` with `CertlabTechLead` and confirm it can create a resource but cannot change IAM.
6. As `joselucas`, open `certlab-stage` and the management account with `CertlabReadOnly` and confirm they can read but not change a resource.
7. Share only the sanitized result ("each permission set issued temporary credentials and the separation held"), never screenshots with IDs.

Done when: every assignment in the table in [Read-only verification](#read-only-verification) works and shows the documented separation.

### 8. Cost budget

In the management account, under Billing and Cost Management:

1. Create a **monthly cost budget** of exactly **USD 10**, filtered to the stage account when the filter applies.
2. Add alerts on actual spend at 50%, 80% and 100%, and on forecasted spend at 100%.
3. Add the private recipient e-mail to every alert.
4. Complete the recipient confirmation until the recipient is active. A pending or inactive recipient does not satisfy the acceptance criteria.
5. Record only the date and the outcome of the first alert or test notification (received or not received).

Done when: the budget shows the four alerts and the recipient is active.

## Read-only verification

The agent runs only read-only calls. Use an untracked local AWS profile that signs in through Identity Center with `CertlabReadOnly`, or a read-only session in the management account. Do not commit or paste profile names, account IDs or raw output. Reduce each result to a pass or fail line before reporting it.

```sh
# Organization exists, all features enabled (do not paste the raw output: it contains IDs and e-mail).
aws organizations describe-organization --query 'Organization.FeatureSet'

# One OU named Workloads under the root.
aws organizations list-organizational-units-for-parent \
  --parent-id "$(aws organizations list-roots --query 'Roots[0].Id' --output text)" \
  --query 'OrganizationalUnits[].Name'

# Accounts: names and status only.
aws organizations list-accounts --query 'Accounts[].[Name,Status]' --output text

# Identity Center: one organization instance.
aws sso-admin list-instances --query 'length(Instances)'

# Permission sets exist (names only).
INSTANCE="$(aws sso-admin list-instances --query 'Instances[0].InstanceArn' --output text)"
for arn in $(aws sso-admin list-permission-sets --instance-arn "$INSTANCE" --query 'PermissionSets[]' --output text); do
  aws sso-admin describe-permission-set --instance-arn "$INSTANCE" --permission-set-arn "$arn" \
    --query 'PermissionSet.[Name,SessionDuration]' --output text
done

# Root posture of the management account: MFA on, zero access keys.
aws iam get-account-summary --query 'SummaryMap.[AccountMFAEnabled,AccountAccessKeysPresent]' --output text

# Centralized root access is enabled for the Organization.
aws iam list-organizations-features

# Budget: type, period, limit and the four alerts (do not print subscribers).
aws budgets describe-budgets --account-id "$(aws sts get-caller-identity --query Account --output text)" \
  --query 'Budgets[].[BudgetName,TimeUnit,BudgetLimit.Amount,BudgetLimit.Unit]' --output text
```

Expected result:

| Check | Expected |
|---|---|
| Organization feature set | `ALL` |
| OUs under root | `Workloads` only |
| Accounts | the management account and `certlab-stage` (`ACTIVE`), nothing else |
| Identity Center instances | 1 |
| Permission sets | `CertlabReadOnly`, `CertlabTechLead`, `CertlabAdministrator`, with the session durations above |
| Assignments | `certlab-owner`: `CertlabAdministrator` on the management account and `certlab-stage`. `joselucas`: `CertlabTechLead` and `CertlabReadOnly` on `certlab-stage`, `CertlabReadOnly` on the management account |
| Root MFA / access keys | MFA enabled, 0 keys |
| Organizations features | root credentials management and root sessions enabled |
| Budget | monthly, 10 USD, alerts 50/80/100% actual and 100% forecasted |

The calls cannot prove everything. The maintainer confirms by console or by a received alert: the active state of the budget recipient, the tested root MFA sign-in, the absence of persistent root credentials in `certlab-stage` and the sign-in with both permission sets. Any divergence blocks closing the issue.

## Recovery

- **Lost Identity Center MFA:** sign in as the management account root user, then reset the MFA device of the Identity Center user. Register a new device immediately.
- **Lost root MFA:** use the second registered device. If both are lost, use the AWS account recovery process with the root e-mail and the phone number on the account, then register two new devices.
- **Lost access to the root e-mail:** this blocks recovery. Keep the e-mail on an account the maintainer controls with its own MFA, and review it at each periodic review.
- **Compromise suspected:** rotate the root password, delete any access key, review CloudTrail event history for the management account, and remove unknown Identity Center assignments.

Recovery data (backup codes, device serials, recovery e-mail, phone number) stays in the password manager only.

## Exceptional root use

Use the root user of the management account only for tasks that require it, such as changing the account's support plan or closing the account, and for recovery. Member accounts do not have a persistent root user; use centralized privileged root actions instead. Record each use in the pull request or issue by date and reason, never by credential.

## Periodic review

Review quarterly and after any access change:

- Identity Center users and assignments match the people who need access, and `CertlabAdministrator` is assigned only to `certlab-owner`, and `CertlabTechLead` only to the tech lead on `certlab-stage`.
- Root MFA devices work, and there are still zero root access keys.
- `certlab-stage` has no persistent root credentials.
- The budget exists with the approved values and the recipient is active.
- No account other than the management account and `certlab-stage` exists, until a later decision adds `certlab-prod`.
- The private values in the password manager are current.

Record the date and the outcome of each review here or in the issue that performs it.

## Verification record

| Date | Result |
|---|---|
| _pending_ | The maintainer ran the steps and the read-only verification passed. |
