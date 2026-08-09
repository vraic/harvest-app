![CI](https://github.com/vraic/harvest-je/actions/workflows/ci.yml/badge.svg?branch=main)

# Harvest

Practical digital tools for the island farming community. Built on island, for islanders.

Harvest is open-source software: anyone can use this codebase and deploy it wherever they want, however they want. If you'd rather not self-host, check out the fully hosted and commercially supported version at [harvest.je](https://harvest.je).

## What Is Harvest?

Harvest is an open source technology platform designed for the island's agricultural sector. It provides practical digital tools shaped by farmers direct input, respects everyone's data, and is designed to run on island-based infrastructure.

We're currently at first deployment stage. The codebase is live, CI pipelines are green, development is active and we have staging environments running.

## Why Harvest?

Island farming communities face converging pressures around the world from rising input costs, environmental compliance demands, labour shortages and generational knowledge-loss. Technology can help, but dominant agri-tech models carry significant trade-offs.

Many commercial platforms harvest granular farm-level data and monetise it through third parties. Funding priorities often reward shiny-object-driven solutions regardless of whether they solve problems identified by people actually working the land. Proprietary platforms also create long-term dependency on offshore providers with little understanding of island-specific needs.

Harvest takes a different approach: build only what's needed to deliver the best possible service locally. Build tools around the realities of farming in our island commmunities. Keep everything open, auditable, and accountable.

Island technology ecosystems benefit from diverse approaches. Currently, the balance leans heavily toward data-extractive, offshore models. Harvest represents an alternative rooted in local traditions of community-based sustainable practice.


### Core Principles

- Community-first: Tools built from direct farmer input, not distant corporate roadmaps
- Data sovereignty: Your farm data stays under your control
- Open by default: Code and decision-making is auditable by anyone
- Deploy anywhere: Run and host Harvest in any environment that works for you
- Practical utility: Features that solve real-world problems, not shiny object syndrome
- Sustainable development: Built to last, maintained long-term, resilient to vendor lock-in

## Deployment Options

- Self-hosted: Deploy this repository however and wherever you want.
- Fully hosted: Get a managed service with commercial support at [harvest.je](https://harvest.je).

## Technologies

Harvest is built on [Rails](https://rubyonrails.org) following the [Rails Doctrine](https://rubyonrails.org/doctrine) where happiness enables sustainable development. Convention over configuration keeps us focused on delivering value.

## Current Status

- Development phase: Proof-of-concept
- Commits: 240+ and counting
- CI Pipeline: Green
- Next milestone: Production-ready deployment

### Completed

- Core architecture and CI pipeline
- Initial feature set

### Coming Next

- Production deployment preparation
- Expanded feature set based on farmer feedback

## Getting Started

1. Clone this repo to your local/dev environment
2. Change into the directory you've just cloned and start the web server:

   ```bash
   $ cd harvest-app
   $ bin/dev
   ```
   Run with `--help` or `-h` for options.

## Contributing

No contribution is too small. Whether it's a typo fix, a feature suggestion, or a farmer telling us what they actually need, it all moves the project forward.

## Licensing

This software is available under the terms of the [MIT License](https://opensource.org/license/mit).

