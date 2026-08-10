---
title: Self-hosted with Kamal
description: Technical guide for self-hosting Harvest with Kamal on your own infrastructure.
position: 3
section: Getting started
summary: Use Kamal for self-hosting when your team has technical operators or a trusted technician.
keywords:
  - self-hosted
  - kamal
  - deployment
related:
  - getting-started/overview
  - integrations-and-deployment/deploy-with-kamal
---

# Self-hosted with Kamal

If you want full control over hosting, self-hosting is a good fit for technical teams.

This page is for developers, DevOps engineers, or technical IT partners. If you are a farmer or operator and this is outside your skillset, work with your technician or choose [Hosted with harvest.je](/guides/getting-started/hosted-harvest-je).

## Recommended approach

Use **Kamal** to deploy Harvest to your own server.

Follow both:

- Harvest deployment docs: [Deploy with Kamal](/guides/integrations-and-deployment/deploy-with-kamal)
- Official Kamal docs: [kamal-deploy.org](https://kamal-deploy.org/docs/)

You should be comfortable with Linux servers, SSH access, DNS, Docker, TLS/HTTPS, backups, and production monitoring.

## Typical steps

1. Provision a production server (or cluster) with a supported Linux distribution.
2. Configure DNS, firewall rules, SSH access, Docker, and required secrets.
3. Prepare database, storage, and environment variables for Harvest.
4. Deploy and manage releases with Kamal.
5. Configure domain, TLS/HTTPS, monitoring, backups, and rollback procedures.

## Continue reading

- [Deploy with Kamal](/guides/integrations-and-deployment/deploy-with-kamal)
- [Monitoring, backups, and upgrades](/guides/integrations-and-deployment/monitoring-backups-and-upgrades)
- [Kamal documentation](https://kamal-deploy.org/docs/)
