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
