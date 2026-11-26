# 0006. AWS + Terraform, stage on free tiers

- **Status:** Accepted
- **Date:** 2026-11-26

## Context

Certlab is a cloud-certification product and a learning project for cloud architecture, so AWS is the natural home. Cost must stay minimal: stage should be close to free, production taken seriously but justified line by line.

## Decision

- **All AWS infrastructure in Terraform**: `infra/modules/*` reused by `infra/envs/stage` and `infra/envs/prod`. Remote state in S3 with native state locking.
- **Stage:** web on S3 + CloudFront; API on Lambda + HTTP API; database on **Neon free tier** (outside AWS).
- **Prod (phase 3):** web on S3 + CloudFront; database on **RDS PostgreSQL**, single-AZ, small Graviton instance; API runtime decided in its own ADR.
- **CI → AWS via GitHub OIDC** (short-lived role credentials; no access keys stored anywhere).
- **Secrets in SSM Parameter Store** (standard tier).
- **AWS Budgets** alerts configured before anything else is created.

Cost rules:
- Avoid NAT Gateway (use VPC endpoints or a small NAT instance if egress from a VPC is needed), avoid ALB unless required, avoid idle public IPv4 addresses, no Multi-AZ until justified.
- Short log retention in stage.
- Every new paid resource is mentioned in its PR with an estimated monthly cost.

## Consequences

- Stage costs ~$0; prod starts in the tens of dollars per month, not hundreds.
- Neon in stage and RDS in prod means two Postgres flavours; we stay on plain PostgreSQL features and test migrations in CI against vanilla Postgres.
- Terraform discipline from day one: no click-ops in the console except for read-only investigation.

## Alternatives considered

- **Fly.io / Railway / Render for everything** — simpler, but loses the AWS learning goal; free tiers sleep or have been reduced.
- **AWS CDK / Pulumi** — viable; Terraform chosen for its ubiquity and portability of knowledge.
- **RDS in stage** — a monthly cost for an environment used by one person.
