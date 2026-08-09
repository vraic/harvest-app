---
sessionId: session-260809-123003-xg4e
---

# Requirements

### Overview & Goals
Create a docs content structure that is easy for non-technical users to browse, while covering all implemented app features with clear grouping and cross-links.

### Scope
#### In Scope
- Reorganize `doc/docs` into section folders with predictable ordering.
- Define article templates/conventions for plain-English, task-first docs.
- Update docs navigation/search plumbing so grouped content is easy to discover.
- Add a cross-link strategy (`related` links + contextual links in content).
- Build out coverage for current feature areas visible in routes/navigation.

#### Out of Scope
- Rewriting every UI flow in one pass beyond agreed initial article set.
- Adding external docs tooling (keep embedded Rails docs engine).

### Functional Requirements
- Docs remain public at `/docs` with no authentication.
- Sidebar shows grouped sections (not just a flat list).
- Users can move through docs via section landing pages + previous/next + related links.
- Search returns useful results for plain-English terms and feature names.
- Every major app capability has at least one discoverable doc page.

# Technical Design

### Current Implementation
- Content lives in `doc/docs/*.md` and is currently mostly flat.
- `Docs::Repository` (`app/services/docs/repository.rb`) loads markdown recursively, builds slugs from paths, parses front matter (`title`, `description`, `position`), and powers search.
- Sidebar (`app/views/docs/_sidebar.html.erb`) renders a single-level list.
- `DocsHelper` (`app/helpers/docs_helper.rb`) breadcrumbs are currently two-level (`Docs > Page`) and prev/next is based on flat ordering.
- `DocsController` (`app/controllers/docs_controller.rb`) already supports `/docs/*slug` and search query handling.

### Key Decisions
1. **Use filesystem-first grouping**: section folders with numeric prefixes (consistent with current `position`/prefix convention).
2. **Add section-aware metadata in front matter**: lightweight fields like `section`, `summary`, `related` to improve navigation/search relevance.
3. **Keep the existing embedded docs engine** and extend repository/view helpers rather than introducing a new docs platform.

### Proposed Changes
- Reorganize `doc/docs` into section directories, e.g.:
  - `doc/docs/01-getting-started/`
  - `doc/docs/02-daily-operations/`
  - `doc/docs/03-commerce-and-orders/`
  - `doc/docs/04-customers-and-suppliers/`
  - `doc/docs/05-data-protection-and-retention/`
  - `doc/docs/06-store-admin-and-security/`
  - `doc/docs/07-integrations-and-deployment/`
- Add section landing articles (`01-overview.md`) plus focused feature pages (`02-tasks.md`, `03-orders.md`, etc.).
- Extend `Docs::Repository` to produce a grouped navigation structure (sections + pages) and expose related-article references from front matter.
- Update `app/views/docs/_sidebar.html.erb` to render grouped sections with active-state behavior matching existing nav conventions.
- Enhance breadcrumbs in `DocsHelper` to include section level (`Docs > Section > Article`).
- Add “Related articles” block on `app/views/docs/show.html.erb` sourced from front matter and validated slugs.
- Expand search indexing in `Docs::Repository` to include section labels/keywords from front matter for better non-technical queries.

### Feature Coverage Map (content plan)
- **Getting started**: hosted vs self-hosted, local dev, first-run path.
- **Daily operations**: dashboard, tasks, notifications, reports.
- **Commerce**: shop, cart, checkout, orders, order notes/statuses.
- **People & relationships**: customers, suppliers, newsletters, loyalty cards.
- **Data governance**: DSAR, retention policies, retention events, holds/anonymisation.
- **Administration**: accounts, memberships, support requests, store settings.
- **Security**: sessions, password, 2FA, account/offboarding semantics.

### File Structure
- **Content**: `doc/docs/**` (migrated to grouped folders and expanded article set).
- **Docs domain logic**: `app/services/docs/repository.rb`.
- **Rendering/navigation**: `app/views/docs/index.html.erb`, `app/views/docs/show.html.erb`, `app/views/docs/_sidebar.html.erb`, `app/helpers/docs_helper.rb`.
- **Regression tests**: `test/services/docs/repository_test.rb`, `test/controllers/docs_controller_test.rb`.

# Testing

### Validation Approach
Use existing docs controller/service tests as the primary safety net and add assertions for grouped navigation, section-aware breadcrumbs, and related-link behavior.

### Key Scenarios
- Section folders and page ordering render correctly on `/docs`.
- Sidebar shows grouped sections and highlights current page.
- Breadcrumbs show `Docs > Section > Article`.
- Related links render only for valid internal doc slugs.
- Search finds pages by plain-English terms and section keywords.

### Edge Cases
- Missing or malformed front matter should not break page rendering.
- Section with one page still renders cleanly.
- Invalid `related` slug is ignored safely.
- Nested folder slugs continue resolving via `/docs/*slug`.

### Test Changes
- Extend `test/services/docs/repository_test.rb` for grouped docs structure + related parsing + keyword indexing.
- Extend `test/controllers/docs_controller_test.rb` for grouped sidebar/breadcrumb/related links rendering.

# Delivery Steps

### ✓ Step 1: Define docs information architecture and content taxonomy
A complete section-based docs map exists for all current app capabilities.
- Inventory implemented features using existing app structure references (`config/routes.rb`, `app/views/layouts/_navigation.html.erb`).
- Define final section taxonomy and naming for non-technical users (plain-English, task-first).
- Specify article-level coverage matrix so each major feature has an assigned doc page.
- Define writing conventions (title pattern, intro style, action-oriented headings, cross-link expectations).

### ✓ Step 2: Restructure docs content folders and migrate baseline articles
`doc/docs` is reorganized into section folders with consistent ordering and clear landing pages.
- Move current docs into section directories using numeric prefixes for stable ordering.
- Create section landing pages and split broad pages into focused feature articles.
- Add front matter conventions (`title`, `description`, `position`, section metadata, optional `related`/keywords fields).
- Ensure internal links between moved pages use canonical `/docs/...` slugs.

### ✓ Step 3: Implement section-aware navigation and cross-link plumbing
The docs UI presents grouped navigation, richer breadcrumbs, and related-article discovery.
- Extend `app/services/docs/repository.rb` to expose section/group structures and related-link metadata.
- Update `app/views/docs/_sidebar.html.erb` to render grouped sections while preserving current active-state styling conventions.
- Update `app/helpers/docs_helper.rb` and `app/views/docs/show.html.erb` for section-aware breadcrumbs and related-article blocks.
- Keep compatibility with current `/docs/*slug` behavior in `app/controllers/docs_controller.rb`.

### ✓ Step 4: Harden search relevance and validate user-facing docs UX
Search and navigation reliably surface useful articles for real user queries.
- Enrich search scope in `Docs::Repository` with section labels/keywords to improve plain-English discoverability.
- Add/extend regression coverage in `test/services/docs/repository_test.rb` and `test/controllers/docs_controller_test.rb` for grouping, breadcrumbs, related links, and search relevance.
- Validate final browse flow: section landing -> feature article -> related/next article with minimal clicks.

### ✓ Step 5: Rebrand public docs entrypoint from `/docs` to `/guides`
All public-facing docs URLs and navigation entry points use `/guides` while preserving section/article slug behavior.
- Update routes and public links to use `/guides` and `/guides/*slug`.
- Keep docs publicly accessible with no authentication changes.
- Preserve existing article slug paths after the base-path rename.

### ✓ Step 6: Align guides page layout with Rails Guides style cues
Guides index/show pages visually align more closely with `guides.rubyonrails.org` conventions while fitting existing app styling.
- Update index and article layouts to a cleaner document-focused structure.
- Adjust sidebar, headings, spacing, and metadata presentation toward Rails Guides UX.
- Keep existing search and navigation behavior intact.

### ✓ Step 7: Update internal guide links and content references
Markdown and UI links consistently point to canonical `/guides/...` paths.
- Replace stale `/docs/...` internal references across guide content and views.
- Preserve external-link behavior (`target="_blank"`) for non-internal links.

### ✓ Step 8: Validate renamed routes and guides UX with regression tests
Controller/service behavior remains stable under `/guides` and updated templates.
- Update/extend docs controller and repository tests for `/guides` paths and rendering assertions.
- Run targeted docs tests and the full suite to confirm no regressions.

### ✓ Step 9: Refactor internal docs module naming from docs to guides
Internal Rails structure uses `guides` naming consistently for controllers, helpers, services, views, and tests.
- Rename docs controller/helper/service namespaces and file locations to `guides` equivalents.
- Update routes, helpers, partial rendering, and references to use `guides` internal naming.
- Keep public URLs and behavior aligned with `/guides`.

### ✓ Step 10: Simplify guides show page navigation and heading UX
Guide article pages prioritize content with reduced redundant navigation affordances.
- Hide the left sidebar navigation on guide show pages.
- Remove heading self-link UX from article content rendering.
- Keep right-side in-page navigation behavior intact.

### ✓ Step 11: Validate renamed internals and updated guides UX
Regression coverage confirms behavior and routing remain stable after refactor.
- Update controller/service tests for renamed internals and show-page UX changes.
- Run targeted guides tests to confirm all new expectations pass.

### ✓ Step 12: Move markdown content root from `doc/docs` to `doc/guides`
Guides markdown files are stored under `doc/guides` and loaded from there by the guides repository.
- Move all guide markdown folders/files from `doc/docs` to `doc/guides`.
- Update repository content root and any remaining references that still point at `doc/docs`.
- Run guides controller/service tests to confirm loading, search, and navigation still work.

### ✓ Step 13: Refine guides show-page visual design to flow like Rails Guides
Guide article pages should use a cleaner, less boxed reading layout that feels closer to `guides.rubyonrails.org`.
- Update `app/views/guides/show.html.erb` structure/classes to remove the heavy white panel treatment and improve document flow.
- Keep right-side in-page navigation and existing guide content features intact.
- Validate with targeted guides controller tests for show-page rendering behavior.

### ✓ Step 14: Smooth guides index left navigation UX
Guides index left navigation should feel spacious, readable, and less visually heavy.
- Update `app/views/guides/index.html.erb` and related guides navigation markup/classes to improve sidebar width, spacing, and visual hierarchy.
- Keep existing grouped sections, active states, and search behavior intact.
- Validate with targeted guides controller tests for index rendering behavior.

### ✓ Step 15: Redesign guides left navigation aesthetics
Guides left navigation should have an elegant, low-chrome visual treatment without heavy white box framing.
- Refine `app/views/guides/index.html.erb` sidebar container styling to remove the bulky boxed appearance.
- Refine `app/views/guides/_sidebar.html.erb` nav hierarchy and link states to feel cleaner and more premium.
- Validate with targeted guides controller tests for index rendering behavior.