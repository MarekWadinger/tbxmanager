# Contributing to tbxmanager

Want to improve the MATLAB package manager itself? This guide covers development setup, code conventions, and the contribution workflow.

!!! note "Looking to publish a package?"
    If you want to register your own MATLAB toolbox, see [Quick Start for Authors](quick-start-authors.md) instead.

## Development Setup

### Prerequisites

- **MATLAB R2022a+** (R2025b recommended)
- **Python 3.10+** with [uv](https://docs.astral.sh/uv/)
- **Git**

### Clone and Install

```bash
git clone https://github.com/MarekWadinger/tbxmanager.git
cd tbxmanager
make dev          # Install Python dev dependencies
```

### Useful Make Targets

| Command | What it does |
| ------- | ------------ |
| `make help` | Show all targets |
| `make test` | Lint + validate (no MATLAB needed) |
| `make test-matlab` | Run MATLAB test suite |
| `make test-matlab-verbose` | Verbose MATLAB test output |
| `make test-matlab-single CLASS=TestName` | Run a single test class |
| `make test-all` | Everything (lint + validate + MATLAB) |
| `make docs` | Serve docs locally at `http://127.0.0.1:8000` |
| `make lint` | Lint Python scripts |
| `make validate` | Validate JSON fixtures against schemas |

## Project Structure

```text
tbxmanager.m          # The MATLAB client (single-file, all code here)
tests/                # MATLAB unit tests (matlab.unittest.TestCase)
  fixtures/           # Test data (JSON fixtures)
scripts/              # Python tooling (migration, validation, indexing)
  schemas/            # JSON schemas for all data formats
docs/                 # MkDocs Material site source
.github/workflows/    # CI/CD (test, deploy-site, release)
```

## Code Conventions

### MATLAB (`tbxmanager.m`)

- **All code lives in one file** as local functions — this enables the one-line install
- `tbx_` prefix for internal helper functions (e.g., `tbx_setup`, `tbx_fetchJson`)
- `main_` prefix for command handler functions (e.g., `main_install`, `main_update`)
- Use `arguments` blocks for input validation
- Use `string` arrays (`"string"`) not char arrays (`'string'`) for new code
- Target MATLAB R2022a+ features only

### Tests

- Framework: `matlab.unittest.TestCase`
- Tests must be self-contained: create all mock data at runtime
- Test files: `tests/Test*.m`

### Python Scripts

- Standard library preferred; minimal dependencies
- Linted with `ruff`

## Contribution Workflow

1. **Fork** [MarekWadinger/tbxmanager](https://github.com/MarekWadinger/tbxmanager)
2. **Branch** from `dev`:

    ```bash
    git checkout dev
    git checkout -b feat/my-feature
    ```

3. **Make changes** — edit `tbxmanager.m`, add tests in `tests/`
4. **Verify** before committing:

    ```bash
    make test-all
    ```

5. **Commit** using [conventional commits](https://www.conventionalcommits.org/):

    ```text
    feat(client): add frobnicate command
    fix(client): handle empty version string
    docs(site): update install instructions
    ```

6. **Open a PR** to `dev`

### What Gets CI-Tested

- Python linting (`ruff`)
- JSON schema validation
- MATLAB tests on 2 releases x 3 OSes (via GitHub Actions matrix)

## Reporting Issues

| Issue type | Where to report |
| ---------- | --------------- |
| Client bugs (`tbxmanager.m`) | [MarekWadinger/tbxmanager/issues](https://github.com/MarekWadinger/tbxmanager/issues) |
| Registry/index issues | [MarekWadinger/tbxmanager-registry/issues](https://github.com/MarekWadinger/tbxmanager-registry/issues) |
| Broken package downloads | Contact the package author (see `tbxmanager info <pkg>`) |
| Documentation issues | [MarekWadinger/tbxmanager/issues](https://github.com/MarekWadinger/tbxmanager/issues) |

## Next Steps

- [Commands Reference](commands.md) — all CLI commands
- [Concepts](concepts.md) — architecture and design decisions
- [Troubleshooting](troubleshooting.md) — common issues and solutions
