---
title: "Repository Quickstart"
summary: "Quickstart for the Electric Mind Super Day Challenge monorepo: pick one track (frontend, backend, mobile), read its START-HERE and REQUIREMENTS, run the matching mock via npm scripts (node >=24), and build your solution in that track's solution/ folder. Includes entrypoints, setup commands, and where to look next."
generated_by: ax-wiki
symbols:
  - "README.md"
  - "backend/REQUIREMENTS.md"
  - "backend/START-HERE.md"
  - "backend/mock-crm.mjs"
  - "engines.node"
  - "frontend/REQUIREMENTS.md"
  - "frontend/START-HERE.md"
  - "frontend/mock-server.mjs"
  - "mobile/REQUIREMENTS.md"
  - "mobile/START-HERE.md"
  - "mobile/mock-server.mjs"
  - "package.json"
  - "scripts.backend"
  - "scripts.frontend"
  - "scripts.mobile"
  - "scripts.test"
  - "support/*.test.mjs"
  - "type: module"
symbol_summaries: [{"name":"package.json","summary":"Root private ESM package requiring Node >= 24; defines the frontend/backend/mobile mock scripts and the support test script, and carries no dependencies."},{"name":"README.md","summary":"Challenge overview: pick one of three tracks, read its start-here and requirements, build in that track's solution/ folder, and submit short run/test notes."},{"name":"frontend/START-HERE.md","summary":"Setup guide for the Frontend track, referenced from the README track table."},{"name":"frontend/REQUIREMENTS.md","summary":"Tasks and acceptance requirements for the Frontend track."},{"name":"backend/START-HERE.md","summary":"Setup guide for the Backend track."},{"name":"backend/REQUIREMENTS.md","summary":"Tasks and acceptance requirements for the Backend track."},{"name":"mobile/START-HERE.md","summary":"Setup guide for the Mobile track."},{"name":"mobile/REQUIREMENTS.md","summary":"Tasks and acceptance requirements for the Mobile track."},{"name":"frontend/mock-server.mjs","summary":"Mock service launched by npm run frontend, providing Frontend track starting data."},{"name":"backend/mock-crm.mjs","summary":"Mock CRM service launched by npm run backend, providing Backend track starting data."},{"name":"mobile/mock-server.mjs","summary":"Mock service launched by npm run mobile, providing Mobile track starting data."},{"name":"support/*.test.mjs","summary":"Shared tests executed by the root npm test script via node --test."}]
sources:
  - "README.md"
  - "package.json"
---

# Repository Quickstart

This is the **Electric Mind Super Day Challenge**: a monorepo of three independent tracks for building an investments dashboard (what someone owns, its total worth, and how it changed over time). Per `README.md`, you choose **one** assigned track — Frontend, Backend, or Mobile — and build inside that track's `solution/` folder. You do not need to complete the other tracks.

You may choose your language and framework within your track's requirements, and AI assistance is allowed.

### Track entrypoints

| Track | Setup | Requirements |
| --- | --- | --- |
| Frontend | `frontend/START-HERE.md` | `frontend/REQUIREMENTS.md` |
| Backend | `backend/START-HERE.md` | `backend/REQUIREMENTS.md` |
| Mobile | `mobile/START-HERE.md` | `mobile/REQUIREMENTS.md` |

Read the requirements **before** coding — they define what to build and how it is checked. The supplied mocks are starting materials, not the deliverable.

## Stack and runtime

The root `package.json` is private, ESM (`"type": "module"`), and requires **Node.js >= 24** (`engines.node`). There is no dependency list and no build tooling at the root; the root only wires up npm scripts that run the mock services.

The repository is organized by track:

- `frontend/` — frontend track (setup, requirements, mock server, solution folder)
- `backend/` — backend track (setup, requirements, mock CRM, solution folder)
- `mobile/` — mobile track (setup, requirements, mock server, solution folder)
- `support/` — shared support code and tests
- `_probe_flutter/` — a probe Flutter area, separate from the track deliverable workflow

See [Architecture Overview](architecture/overview.md) for how these pieces relate. Track-specific detail: [Frontend Module](modules/frontend.md), [Backend Module](modules/backend.md), [Mobile Module](modules/mobile.md), [Support Module](modules/support.md), and [Probe Flutter Module](modules/probe-flutter.md).

## Setup

1. Ensure you are on Node >= 24 (`node --version`), since the engines field enforces it.
2. From the repository root, install nothing extra at the monorepo level — the root has no dependencies to install beyond the Node runtime.
3. Open your assigned track's `START-HERE.md` and follow its track-specific setup steps.

## Run the mocks

The root `package.json` exposes one script per track that starts that track's mock service:

```bash
npm run frontend   # node frontend/mock-server.mjs
npm run backend    # node backend/mock-crm.mjs
npm run mobile     # node mobile/mock-server.mjs
```

Run only the mock for your track (e.g. `npm run frontend`). These are development aids that supply starting data or a mock service; the real app or backend is what you build in `solution/`.

## Run tests

```bash
npm test   # node --test support/*.test.mjs
```

The root test script runs Node's built-in test runner over `support/*.test.mjs`, so shared support code is exercised from the root. Track-specific test commands may be described in each track's `START-HERE.md` or `REQUIREMENTS.md`; verify there before assuming a root command covers your track.

## Shortest path to productive work

1. Read `README.md` (already summarized above) to pick your assigned track.
2. Read your track's `REQUIREMENTS.md` end to end — it is the spec.
3. Run your track's `START-HERE.md` setup, then launch the matching mock script.
4. Build in your track's `solution/` folder.
5. Write the required short notes with your solution per `README.md`: how to install and run it, how to run tests, and known assumptions or unfinished work.
6. If you touch shared code under `support/`, run `npm test`.

See [Development Workflows](development/workflows.md) for day-to-day commands and iteration loops.

## Boundaries and responsibilities

- **Track isolation:** each track is self-contained; the root does not coordinate a combined app or a shared build across tracks.
- **Mocks vs. solution:** `mock-server.mjs` / `mock-crm.mjs` are provided starting materials and live at the track root; your implementation belongs in `solution/`.
- **Shared layer:** `support/` holds cross-cutting code and the only tests wired into the root test script.
- **Data:** all supplied data is fictional (`README.md`).

## Uncertainties

- The exact contents of each track's `START-HERE.md` and `REQUIREMENTS.md` are not included in the supplied evidence; read those files directly for required languages, frameworks, and test commands.
- Whether any track expects additional local toolchains (e.g. a mobile SDK) is defined by those documents, not by the root `package.json`, which only governs Node.

## Sources

- `README.md`
- `package.json`
