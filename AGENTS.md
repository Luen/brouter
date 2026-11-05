# AGENTS.md

Agent-focused guidance for this repository ([AGENTS.md format](https://agents.md/)). Human-facing docs live in `README.md` / `docs/`.

## Living document

Treat this file as **living documentation**. Update it in the same PR when the stack, scripts, branch model, deploy path, or other project facts change.

## Project overview

Configurable OSM offline router with elevation awareness (Java + Android). This fork adds Docker packaging for the server.

## Branch model

| Branch | Role |
| --- | --- |
| `master` | Default branch (upstream-aligned). Features and Docker/CI land here |
| profile branches | Optional routing-profile work (`car-4wd-profile`, `moto-adv-profile`, …) |

- Prefer PRs against **`master`** unless working on a dedicated profile branch.
- Upstream sync: `sync-upstream` / merge from abrensch/brouter as needed.
- Do not invent a parallel `main`/`dev` model unless this fork fully detaches from upstream.

## Dependency and deploy notes

### Tier B - Docker image (GHCR)

- Image: `ghcr.io/luen/brouter` (via `.github/workflows/docker-publish.yml`).
- Tags follow Docker metadata action (branch / semver / sha).
- Auth for Actions: `GITHUB_TOKEN` with `packages: write`.
- Servers should pull from GHCR (Watchtower/cron) with a PAT that has `read:packages`.
- Prefer `docker compose up -d --no-build` after `docker compose pull` on servers.
- Local: `docker compose up --build` still builds from the Dockerfile.

## Pull requests

Before merging any pull request:

1. Read all PR comments (conversation, review, and bot) and address or acknowledge them.
2. Wait for required CI checks to pass before merging.

## Major-version dependency updates & migration checks

When reviewing or merging **major-version** Dependabot or package updates:

1. **Read the upstream migration guide / changelog** before merging. Do not rely solely on a passing container build (`docker build` only verifies `install`, not runtime execution paths).
2. **Verify exports and constructors at runtime:**
   - Check whether default exports moved to named exports (e.g., `pbf` v5 exporting `{ PbfReader, PbfWriter }` instead of a default constructor) or factory functions became ES classes requiring `new` (e.g., `geojson-vt` v5).
   - Check framework route syntax and middleware compatibility (e.g., Express 5 path-to-regexp rules, React peer dependency alignment across `@types/react` and `@types/react-dom`).
   - For Python lockfile repos (`uv pip compile`), always recompile `requirements.lock` and `requirements-dev.lock` when `requirements.txt` ranges change so `uv pip sync` and nightly constrained upgrades stay consistent.
3. **Regenerate lockfiles with the repo's pinned package manager** (e.g., `pnpm@10.33.0`, `pnpm@12.15.0`, `npm`, or `uv==0.13.7`) when rebasing or combining multiple dependency PRs.
4. **Run a runtime smoke test** (lint, unit tests, module import check, and endpoint/container health check) before promoting to `main` and publishing a release.
