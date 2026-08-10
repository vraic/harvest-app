---
title: Deploy with Kamal
description: Technical deployment guide for running self-hosted Harvest in production with Kamal.
position: 2
section: Integrations and deployment
summary: Use Kamal to deploy, update, and roll back Harvest safely on your own infrastructure.
keywords:
  - kamal
  - deployment
  - production
  - self-hosted
  - docker
related:
  - getting-started/self-hosted-with-kamal
  - integrations-and-deployment/monitoring-backups-and-upgrades
---

# Deploy with Kamal

Kamal is the recommended way to run **self-hosted Harvest** in production.

This page gives a practical Harvest-focused deployment path. For Kamal command syntax and full configuration reference, use the official docs.

## Best for

- technical teams managing their own Linux infrastructure
- deployments that need repeatable releases and clear rollback
- operators who can own Docker, networking, secrets, and uptime

If that is not your team profile, use [Hosted with harvest.je](/guides/getting-started/hosted-harvest-je).

## Before you deploy

Make sure you have:

- a production Linux host (or hosts) with Docker installed
- DNS records ready for your Harvest domain
- secure SSH access for deploy operators
- TLS/HTTPS plan (direct or reverse proxy)
- production secrets and environment variables prepared
- backup and restore procedures tested

If you are still deciding on this route, review [Self-hosted with Kamal](/guides/getting-started/self-hosted-with-kamal) first.

## Recommended deployment flow

1. Prepare infrastructure (server hardening, firewall, SSH, Docker runtime).
2. Configure Kamal for your app, hosts, registry, env, and accessory services.
3. Run an initial setup/deploy and verify health checks.
4. Validate domain, TLS, login, and one full business workflow.
5. Put monitoring, backup, and rollback runbooks in place before go-live.

For command-level execution, follow:

- [Kamal documentation](https://kamal-deploy.org/docs/)
- [Kamal configuration reference](https://kamal-deploy.org/docs/configuration/overview/)

## Harvest production best practices

- keep deploy access limited to named operators with audited SSH keys
- pin image versions/tags and avoid unreviewed mutable release inputs
- separate staging and production environment values and secrets
- run database migrations as part of a controlled release process
- verify rollback steps during a planned window, not during first incident
- document who owns incident response during and after deployments

## Post-deploy validation checklist

After each release, confirm:

- app is reachable over HTTPS on the production domain
- authentication and team access work as expected
- core workflow succeeds (supplier -> stock -> order)
- background jobs and integrations are healthy
- metrics, logs, and alerts are visible to operators

## Continue reading

- [Self-hosted with Kamal](/guides/getting-started/self-hosted-with-kamal)
- [Monitoring, backups, and upgrades](/guides/integrations-and-deployment/monitoring-backups-and-upgrades)
- [Kamal documentation](https://kamal-deploy.org/docs/)
