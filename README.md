# Vraic

Vraic (pronounced *wrak*) is the Jèrriais word for seaweed. For centuries, Jersey farmers gathered vraic from the shoreline and spread it on their fields - a shared, communal resource that sustained the island's agriculture. Nobody owned it. Nobody patented the practice. It worked because the community did it together.

This project takes that ethic and applies it to software.

## What Is Vraic?

Vraic is an open source technology platform built for Jersey's agricultural community. It's designed to provide practical digital tools for local farmers shaped by their direct input, be respectful of everyone's data and deployed on island-based infrastructure.

We're at **proof-of-concept stage** (pre-alpha). The codebase is live, the CI pipeline is green and development is active. We're now looking for funding to move to production.

### Core Principles

- **Open source, MIT license.** No vendor lock-in. No proprietary black boxes. Everything auditable.
- **Privacy by design.** Farmers data stays theirs.
- **People-first technology.** Technology serves the people working the land and not the other way around.
- **On-island deployment.** Built to run on Jersey-based servers, keeping data local and reducing dependence on off-island infrastructure.
- **Community-shaped.** Feature priorities come from direct engagement with local farmers and agricultural stakeholders.
- **Built to teach.** The project doubles as a teaching resource, creating opportunities for on-island skills development in modern software engineering.

## Technologies

* [Ruby on Rails](https://rubyonrails.org) and a wide-range of open source gems
* [Rubocop](https://github.com/rubocop/rubocop), [Brakeman](https://brakemanscanner.org)
* [Tailwind](https://tailwindcss.com)
* [Github](https://github.com)
* [Kamal](https://kamal-deploy.org)

Vraic is built on [Rails](https://rubyonrails.org) following the [Rails Doctrine](https://rubyonrails.org/doctrine) where programmer happiness is front and centre. Convention over configuration fuels sustainable development.

## Current Status

**Pre-alpha / proof-of-concept.** 200+ commits and counting.

**Completed:**

* Core application scaffold (Rails, Docker, CI/CD pipeline)
* Tailwind design system baseline
* Test suite, RuboCop, linter all passing
* DevContainer for contributor onboarding
* Kamal deployment configuration
* Authentication and user management
* Customer and supplier profiles
* Task management
* Inventory management
* Multi-store/location support
* Loyalty programmes
* Newsletters and mailing lists
* Basic reports

**Next:**

* Workshops with local farmers to provide further insights into needs
* On-island server deployment for production POC
* Infrastrucutre, servers, networking, security tooling & web application firewalls, CI/CD pipelines
* Launch into production
* Documentation
* Education

## Why Vraic?

Jersey's farming sector faces converging pressures: rising input costs, environmental compliance demands, labour shortages and generational knowledge loss. Technology can help, but the dominant models being pushed onto the sector carry significant trade-offs.

Many agri-tech platforms harvest granular farm-level data and monetise it through third parties. Funding priorities tend to reward AI-driven solutions regardless of whether they solve problems identified by the people actually working the land. Proprietary platforms create dependency on offshore providers with little understanding of island-specific needs.

Vraic takes a different stance: **minimal data, maximum utility.** Collect only what's needed to deliver the best possible service, locally. Build tools around the realities of farming in Jersey. Keep everything open, auditable and accountable.

Jersey's technology ecosystem can benefit from a diverse range of approaches. Right now, the balance is heavily weighted toward data-extractive, offshore models. Vraic represents an alternative that's rooted in the island's own traditions of communal, sustainable practice.

## Funding

We're seeking funds to move Vraic from proof-of-concept to production-ready deployment serving Jersey's farming community.

We propose an **unrestricted grant model**, not because we're resistant to accountability, but because open source projects don't fit neatly into equity, IP assignment or revenue-share frameworks. The MIT licence already guarantees the output remains a public good. The code is public: every commit and decision is visible to the world. There is no more transparent accountability mechanism than an open repository.

That said, we're pragmatic. If a funder's process requires lightweight reporting or milestone check-ins, we're happy to accommodate. What matters is that the administrative overhead doesn't consume time that should go to building the product with farmers.

## Contributing and Getting Started

1. Clone the repo
2. Open in an IDE of your choosing and use the devcontainer
3. Run `bin/dev` to start the dev server
4. See [CONTRIBUTING](CONTRIBUTING) for detailed guidelines

No contribution is too small. Whether it's a typo fix, a feature suggestion or a farmer telling us what they actually need, it all moves the project forward.

## License

This software is available under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## About the Name

> *Vraic* — n. (Jèrriais) Seaweed gathered from the shore, traditionally used as fertiliser on Jersey fields.

Every February for generations, Jersey farmers would descend to the foreshore with pitchforks and carts to cut vraic. It was hard, communal labour. The seaweed belonged to no one and therefore to everyone. It was spread on fields, dug into the soil and it grew the Jersey Royal.

We called this project Vraic. Shared, local and practical. Same as the real thing.

*Vraic*
*Built on Jersey, for Jersey.*
