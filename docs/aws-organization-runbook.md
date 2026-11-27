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
- A payment method is ready. AWS Organizations needs a Paid plan account, so the Free plan credits do not apply and spend limits no longer cap the bill. The budget in step 8 only alerts, it does not block spending.
- A hardware key or an authenticator app is ready for MFA. Register at least two MFA devices for the root user of the management account.

Private values the maintainer stores (never published):

| Role | Used in |
|---|---|
| Management account root e-mail and password | Step 1 |
| Management account root MFA devices and recovery data | Step 4 |
| `certlab-stage` account e-mail alias | Step 5 |
| AWS access portal URL | Steps 3 and 7 |
| Identity Center e-mails for `certlab-owner` and `joselucas` | Step 3 |
| Budget alert recipient e-mail | Step 8 |

## Steps

Do the steps in order. After each one, record only "done" and the date in the pull request or issue, never an identifier.

### 1. Management account

1. Create a new AWS account controlled by Certlab, or designate one created for it. It must not be the maintainer's personal AWS account, which stays outside the Organization.
2. Use a dedicated e-mail address that the maintainer controls long term. It receives root and billing notices.
3. Set a long unique root password in the password manager.
4. Name the account `certlab-admin` in the account settings (root user), so it is clearly the governance account in the access portal.

Done when: the account exists, is named `certlab-admin` and no workload will run in it.

### 2. Organization and `Workloads` OU

1. In AWS Organizations, create the Organization with all features enabled.
2. Create the organizational unit `Workloads` under the root.

Done when: the Organization shows one account (management) and one OU, `Workloads`.

### 3. IAM Identity Center

1. Switch the console to `us-east-1` and check that the page shows `US East (N. Virginia)` before you continue. The AWS onboarding may suggest another region (for example `us-east-2`). The primary region of the instance cannot be changed later. Enable IAM Identity Center as a **single-Region instance** tied to the Organization, with the default settings and permission sets enabled.
2. Create two users and two groups in the Identity Center directory:
   - User `certlab-owner`, with the Certlab project e-mail, in group `Owners`.
   - User `joselucas`, the tech lead, with the maintainer's personal e-mail, in group `TechLeads`.
3. Require MFA at sign-in for all users (always-on, not context-aware), with an authenticator app or security key. Register a separate MFA device entry for each user.
4. Create the permission sets:
   - `CertlabReadOnly`: AWS managed policy `ReadOnlyAccess`. Everyday inspection.
   - `CertlabTechLead`: AWS managed policy `PowerUserAccess`. Operating stage resources, without IAM, Organizations or account management.
   - `CertlabAdministrator`: AWS managed policy `AdministratorAccess`. Bootstrap and administrative changes only.
5. Keep the session duration short: 1 hour for `CertlabAdministrator`, 4 hours for `CertlabTechLead` and up to 8 hours for `CertlabReadOnly`.

6. Assign group `Owners` to `certlab-admin` with `CertlabAdministrator` and `CertlabReadOnly`. Sign in to the AWS access portal as `certlab-owner` (the portal URL is in the Identity Center dashboard). From here on, use this session for every step except step 4, because the root user cannot use features such as root sessions.

Done when: both users and both groups exist, MFA is required, the three permission sets exist and `certlab-owner` can open `certlab-admin` from the portal.

### 4. Management account root

1. Sign in as root once and enable MFA. Register two devices.
2. Confirm the root user has no access keys. Delete any that exist.
3. Sign out and test a second root sign-in with MFA so recovery is proven before it is needed.
4. From now on use root only for tasks that require it (see [Exceptional root use](#exceptional-root-use)).

Done when: root MFA is tested and there are zero root access keys.

### 5. Member account `certlab-stage`

1. In Organizations, create the member account named `certlab-stage` with a private, exclusive e-mail alias that is not used by any other AWS account. A plus alias of the project e-mail works, and the mail arrives in the same inbox.
2. Move it to the `Workloads` OU.
3. Do not create `certlab-prod`, Security Tooling, Log Archive or other accounts.

Done when: `certlab-stage` is `ACTIVE` inside `Workloads` and is the only member account.

### 6. Centralized root access

Do this as `certlab-owner` with `CertlabAdministrator`. The root user of the management account gets "RootSession may not be assumed by root accounts".

1. In IAM, under Root access management, enable **root credentials management** and **privileged root actions in member accounts** for the Organization.
2. Delete the persistent root credentials of `certlab-stage` (password, access keys, MFA, signing certificates) through centralized root access.
3. Confirm `certlab-stage` has no persistent root credentials.

Done when: centralized root access is enabled and `certlab-stage` has no persistent root credentials.

### 7. Assign access and test sign-in

1. Assign group `Owners` to `certlab-stage` with `CertlabAdministrator` and `CertlabReadOnly`. The read-only set is for everyday inspection and for the verification below. The assignment to `certlab-admin` was made in step 3.
2. Assign group `TechLeads` to `certlab-stage` with `CertlabTechLead` and `CertlabReadOnly`. Do not assign it to `certlab-admin`.
3. Sign in to the AWS access portal with MFA as `certlab-owner`. Confirm it lists `certlab-admin` and `certlab-stage`, and that `certlab-admin` opens Organizations, Billing and Budgets. If Billing or Budgets does not open in an Identity Center session, sign in as root and enable **IAM user and role access to Billing information** in the account settings, then sign in again.
4. Confirm the portal shows both permission sets for each account the group has.
5. Sign in as `joselucas`. Confirm the portal lists only `certlab-stage`.
6. As `joselucas`, open `certlab-stage` with `CertlabTechLead` and confirm it can create a resource but cannot change IAM.
7. As `joselucas`, open `certlab-stage` with `CertlabReadOnly` and confirm it can read but not change a resource.
8. Share only the sanitized result ("each permission set issued temporary credentials and the separation held"), never screenshots with IDs.

Done when: every assignment in the table in [Read-only verification](#read-only-verification) works and shows the documented separation.

### 8. Cost budget

Do this as `certlab-owner` in `certlab-admin`, under Billing and Cost Management, Budgets:

1. Create a **monthly cost budget** named `certlab-stage-monthly` of exactly **USD 10**, recurring, fixed, for all AWS services. Do not add an account filter: the budget covers the whole Organization, and the management account runs no workloads, so the cost is the stage cost.
2. Add four alerts: actual spend at 50%, 80% and 100%, and forecasted spend at 100%.
3. Add the private recipient e-mails to every alert. The field takes a comma-separated list of up to 10 addresses. Leave SNS and Chatbot off.
4. Complete any recipient confirmation the console shows until the recipient is active. A pending or inactive recipient does not satisfy the acceptance criteria. The chart preview may show a data error on a new account. It does not block creation.
5. Record only the date and the outcome of the first alert or test notification (received or not received).

Done when: the budget shows the four alerts and the recipient is active.

## Read-only verification

The agent runs only read-only calls. Use an untracked local AWS profile that signs in through Identity Center as `certlab-owner` with `CertlabReadOnly` on `certlab-admin`, which is the only identity that can read the Organization. Do not commit or paste profile names, account IDs or raw output. Reduce each result to a pass or fail line before reporting it.

```sh
# Identity Center lives in us-east-1. Without this, sso-admin calls return no instances.
export AWS_REGION=us-east-1

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

# Budget: type, period and limit (do not print subscribers).
ACCOUNT="$(aws sts get-caller-identity --query Account --output text)"
aws budgets describe-budgets --account-id "$ACCOUNT" \
  --query 'Budgets[].[BudgetName,TimeUnit,BudgetLimit.Amount,BudgetLimit.Unit]' --output text

# Budget alerts: four notifications (actual 50/80/100 and forecasted 100).
aws budgets describe-notifications-for-budget --account-id "$ACCOUNT" --budget-name certlab-stage-monthly \
  --query 'Notifications[].[NotificationType,Threshold]' --output text
```

Expected result:

| Check | Expected |
|---|---|
| Organization feature set | `ALL` |
| OUs under root | `Workloads` only |
| Accounts | `certlab-admin` (management) and `certlab-stage` (`ACTIVE`), nothing else |
| Identity Center instances | 1 |
| Permission sets | `CertlabReadOnly`, `CertlabTechLead`, `CertlabAdministrator`, with the session durations above |
| Assignments | Group `Owners`: `CertlabAdministrator` and `CertlabReadOnly` on `certlab-admin` and `certlab-stage`. Group `TechLeads`: `CertlabTechLead` and `CertlabReadOnly` on `certlab-stage`, nothing on `certlab-admin` |
| Root MFA / access keys | MFA enabled, 0 keys |
| Organizations features | `RootCredentialsManagement` and `RootSessions` |
| Budget | `certlab-stage-monthly`, monthly, 10 USD |
| Budget alerts | `ACTUAL` 50, 80 and 100; `FORECASTED` 100 |

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

- Identity Center users and assignments match the people who need access, and `CertlabAdministrator` is assigned only to group `Owners`, and `CertlabTechLead` only to group `TechLeads` on `certlab-stage`.
- Root MFA devices work, and there are still zero root access keys.
- `certlab-stage` has no persistent root credentials.
- The budget exists with the approved values and the recipient is active.
- No account other than the management account and `certlab-stage` exists, until a later decision adds `certlab-prod`.
- The private values in the password manager are current.

Record the date and the outcome of each review here or in the issue that performs it.

## Verification record

| Date | Result |
|---|---|
| 2026-11-27 | The maintainer ran steps 1 to 8. The read-only verification passed: Organization, OU, accounts, Identity Center, permission sets, root MFA and access keys, centralized root access, and the budget with its four alerts. The maintainer confirmed in the console that `certlab-stage` has no root credentials and that both users sign in with the expected access. The budget recipient state is not exposed by the API and awaits the maintainer's confirmation. |
