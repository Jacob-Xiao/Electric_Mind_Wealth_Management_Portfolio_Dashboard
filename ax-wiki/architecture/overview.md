---
title: "Architecture Overview"
summary: "The repository is a multi-track challenge scaffold rather than a single application: `frontend/`, `backend/`, and `mobile/` each hold their own START-HERE/REQUIREMENTS docs plus a Node mock service, `_probe_flutter/` is a Flutter probe environment, and `support/` holds shared Node tests run via the root `npm test`. The root `package.json` is the only shared runtime contract, exposing one script per mock service."
generated_by: ax-wiki
symbols:
  - "README.md"
  - "backend/REQUIREMENTS.md"
  - "backend/START-HERE.md"
  - "backend/mock-crm.mjs"
  - "frontend/REQUIREMENTS.md"
  - "frontend/START-HERE.md"
  - "frontend/mock-server.mjs"
  - "mobile/REQUIREMENTS.md"
  - "mobile/START-HERE.md"
  - "mobile/mock-server.mjs"
  - "package.json"
  - "support/*.test.mjs"
symbol_summaries: [{"name":"package.json","summary":"Root private ESM manifest requiring Node >=24; the only shared build/runtime contract, defining the frontend, backend, mobile, and test scripts."},{"name":"frontend/mock-server.mjs","summary":"Node ESM mock server for the frontend track, launched by `npm run frontend`; serves as the frontend solution's starting data source."},{"name":"backend/mock-crm.mjs","summary":"Node ESM mock CRM for the backend track, launched by `npm run backend`; stands in for the upstream system a backend solution would integrate with."},{"name":"mobile/mock-server.mjs","summary":"Node ESM mock server for the mobile track, launched by `npm run mobile`; the mobile solution's starting data source."},{"name":"support/*.test.mjs","summary":"Glob of Node test files run by `npm test` via `node --test`; represents the repository's shared support test suite."},{"name":"README.md","summary":"Challenge entry point: defines the three tracks, points at each track's START-HERE and REQUIREMENTS, and specifies building inside each track's solution/ folder with short run/assumption notes."}]
sources:
  - "README.md"
  - "package.json"
---

# Architecture Overview

This repository is a *challenge scaffold*, not a deployed product. `README.md` frames it as the "Electric Mind Super Day Challenge": a dashboard that explains what someone owns, what it is worth, and how that value changed over time. Candidates pick one track, read that track's requirements, and build their solution inside the track's `solution/` folder.

Architecturally that means the top-level modules are **independent, parallel workspaces** that share conventions and tooling but not code. There is no cross-track import graph visible in the evidence.

## System boundaries

| Module | Files | Role in the evidence |
| --- | --- | --- |
| `frontend/` | 3 | Browser-facing track; `frontend/mock-server.mjs` is its data source |
| `backend/` | 7 | Server-side track; `backend/mock-crm.mjs` stands in for an upstream CRM |
| `mobile/` | 17 | Client-app track; `mobile/mock-server.mjs` is its data source |
| `_probe_flutter/` | 14 | Flutter probe workspace, not referenced by the root scripts |
| `support/` | 7 | Shared Node test suite (`support/*.test.mjs`) |

Each track directory carries a `START-HERE.md` (setup) and a `REQUIREMENTS.md` (tasks), per the table in `README.md`. Those two documents are the authoritative contract for each track; the mocks are explicitly described as "starting materials" that the candidate may replace.

## Runtime flow

The only repository-wide runtime contract is the root `package.json`, which declares `"engines": { "node": ">=24" }` and `"type": "module"` and exposes four scripts:

- `npm run frontend` → `node frontend/mock-server.mjs`
- `npm run backend` → `node backend/mock-crm.mjs`
- `npm run mobile` → `node mobile/mock-server.mjs`
- `npm test` → `node --test support/*.test.mjs`

So the mock services are launched directly as Node ESM entrypoints; there is no bundler, task runner, or orchestration layer in the root manifest. Because the frontend and mobile mocks are servers while the backend mock impersonates a CRM, each track's flow is self-contained:

the candidate app under `<track>/solution/` talks to that track's mock entrypoint, while `support/` tests run against the shared support module rather than any single track.

There are no declared dependencies in `package.json`, which implies the mocks rely on Node's standard library only. Verify per file, since the manifest alone does not prove it.

## Data flow

Data is fictional and originates from the mocks. The evidence does not include the mock sources, so the concrete endpoint shapes, payload schemas, and persistence model are **uncertain**. To confirm, read `frontend/mock-server.mjs`, `backend/mock-crm.mjs`, and `mobile/mock-server.mjs` directly and cross-check against the corresponding `REQUIREMENTS.md`.

## Important architectural decisions

- **Track isolation.** `README.md` states candidates "do not need to complete the other tracks," which is why each module carries a duplicate START-HERE/REQUIREMENTS pair instead of a shared spec package.
- **Mocks as replaceable seams.** Requirements describe what to build and how to check it; mocks are starting materials. The mock boundary is therefore the intended integration point, and a candidate solution may substitute its own data source.
- **Solution-in-track convention.** Output goes to `<track>/solution/` with short notes covering install/run, tests, and assumptions — a documentation obligation bundled with the code deliverable.
- **Shared support suite.** `support/` is the one module with tests wired into the root manifest, suggesting cross-track or harness-level helpers live there rather than inside any track.

## Where to go next

Start with [Repository Quickstart](../quickstart.md) for setup, then [Development Workflows](../development/workflows.md) for the script and test loop. Track-specific detail lives in [Frontend Module](../modules/frontend.md), [Backend Module](../modules/backend.md), [Mobile Module](../modules/mobile.md), [Probe Flutter Module](../modules/probe-flutter.md), and [Support Module](../modules/support.md).

## Sources

- `README.md`
- `package.json`
