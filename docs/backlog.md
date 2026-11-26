# Agent Backlog

This file is the asynchronous handoff between implementation agents and the product management (PM) agent. Implementation agents record valuable, real, **non-blocking** findings that are outside the scope of the active issue. The PM agent later triages them into focused issues when the maintainer asks for a triage.

It does not replace Linear, [the roadmap](roadmap.md) or implementation issues. It only keeps findings from being lost, and keeps active issues from growing silently.

## Roles

| Role                                         | Responsibility                                                                                                                                                  |
| -------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Implementation agent (Claude Code, Codex...) | Adds entries with status `candidate`. Never changes the status of an entry, and never implements a candidate as part of an unrelated issue.                     |
| PM agent                                     | Triages `candidate` entries, checks for duplicates, and moves entries to `accepted`, `ticketed` or `dismissed`. Owns every status transition after the triage. |
| Maintainer                                   | Asks for a triage and authorizes any external write, such as creating or updating issues in the issue tracker.                                                  |

## What goes here, and what does not

Record an entry when a finding is **real, valuable, non-blocking and out of scope** for the active issue: a refactor opportunity, a missing test outside the touched code, a documentation gap, a follow-up improvement.

**Escalate immediately instead of recording** (stop and tell the maintainer in the current session):

- A blocker for the active issue.
- A security vulnerability or credential exposure.
- A data-loss risk.
- An urgent production problem.

These must never be deferred through this file. If in doubt about severity, escalate.

## Workflow

1. **Record.** The implementation agent adds an entry from the [template](#entry-template) under [Entries](#entries) with status `candidate`. Adding or updating backlog entries is the only change allowed outside the scope of the active issue; mention it in the pull request description.
2. **Triage.** Only when the maintainer asks for a triage, the PM agent reviews the `candidate` entries.
3. **Check for duplicates.** Before proposing or creating anything, search the existing backlog entries, the repository and the issue tracker. If a match exists, link it in the entry and dismiss the new one, or merge the context into the existing item.
4. **Decide.** Propose a decision for each entry to the maintainer: accept, dismiss, or ask for more evidence.
5. **Update the entry.** Record the decision in the entry. Never delete a processed entry:
   - `accepted`: approved, but not turned into a ticket yet.
   - `ticketed`: an issue was created. Record its identifier and link in the `Issue tracker` field.
   - `dismissed`: record a concise reason in the `Decision` field.

Creating or updating an issue in the issue tracker is an external action. It happens only during a triage requested or authorized by the maintainer. This file is not a standing authorization for external writes, and an entry never creates an issue by itself. Issues created from accepted entries are written in Brazilian Portuguese and follow the [issue writing standard](issue-writing-standard.md).

## Statuses

| Status      | Meaning                                                              | Set by              |
| ----------- | -------------------------------------------------------------------- | ------------------- |
| `candidate` | Recorded by an agent, not reviewed yet.                              | Implementation agent |
| `accepted`  | Reviewed and approved; no issue exists yet.                          | PM agent            |
| `ticketed`  | Converted into an issue; the issue identifier and link are recorded. | PM agent            |
| `dismissed` | Reviewed and rejected, or a duplicate; the reason is recorded.       | PM agent            |

## Safety rules

This repository is public. An entry must never contain credentials, tokens, webhook URLs, personal filesystem paths, private MCP or client configuration, private workspace identifiers, or sensitive user data. Describe the problem without pasting secrets or private output. The repository hygiene check (`scripts/check-public-repo-hygiene.sh`) runs on this file like any other.

Write entries in English.

## Entry template

Copy this block to the end of [Entries](#entries) and fill every field. Use the next free ID (`BL-0001`, `BL-0002`, ...). IDs are stable: never reuse or renumber them.

```markdown
### BL-0000 — Concise title

- **Status:** candidate
- **Discovered:** YYYY-MM-DD
- **Source:** issue, branch and pull request where it was found (for example `LAB-123`, `lab-123-short-description`, `#45`)
- **Context and evidence:** what was observed, and how to reproduce or verify it
- **Impact:** why it matters, and for whom
- **Suggested scope:** the smallest deliverable that would address it
- **Reason for deferral:** why it is out of scope for the source issue
- **Related files and docs:** paths, ADRs or documents
- **Dependencies:** other entries or issues that must come first, or `none`
- **Issue tracker:** `none` until ticketed; then the issue identifier and link
- **Decision:** `pending` until triaged; then the date, the decision and, for `dismissed`, the reason
```

## Entries

Entries are kept in the order they were added. Do not delete processed entries.

_No entries yet._
