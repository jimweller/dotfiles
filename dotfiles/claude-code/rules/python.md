---
paths:
  - "**/*.py"
  - "**/pyproject.toml"
---

# Python Development

## Package Manager

uv is the only package manager. Never use pip, poetry, pipenv, conda, or bare python/python3 commands.

## Project Structure

Always use src layout with a proper package. Never write loose scripts in the project root.

```text
<project-name>/
├── pyproject.toml
├── uv.lock
├── .python-version
├── .envrc
├── src/
│   └── <package_name>/
│       ├── __init__.py
│       └── ...
└── tests/
    ├── conftest.py
    ├── unit/
    ├── integration/
    ├── contract/
    ├── property/
    ├── regression/
    ├── smoke/
    └── e2e/
```

Virtual environment lives at `.venv/` at the project root. Never `venv/` or `env/`.

## pyproject.toml Template

Use `uv init --lib` defaults for `[build-system]`. Do not override the build backend.

```toml
[project]
name = "<package-name>"
version = "0.1.0"
requires-python = ">=3.12"
dependencies = []

[project.scripts]
<cli-name> = "<package_name>.__main__:main"

[dependency-groups]
dev = [
    "pytest>=8",
    "pytest-cov",
    "ruff",
]

[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = "--cov=src --cov-report=term-missing"

[tool.coverage.report]
fail_under = 90

[tool.ruff]
line-length = 100
```

Use `[dependency-groups]` for dev deps. Older projects may use `[project.optional-dependencies]` but new projects use dependency-groups.

Pytest config lives in `pyproject.toml`. Never create a separate `pytest.ini`.

## Python Version

Set `.python-version` at the project root. Match `requires-python` in `pyproject.toml` to that version.

## Testing

| Directory | Purpose |
|-----------|---------|
| tests/unit/ | Isolated unit tests with mocks |
| tests/integration/ | Tests across real subsystems |
| tests/contract/ | Interface contract verification |
| tests/property/ | Property-based tests |
| tests/regression/ | Bug regression coverage |
| tests/smoke/ | Minimal viability verification |
| tests/e2e/ | Full end-to-end workflow tests |

Run tests: `uv run pytest`

For async code: add `pytest-asyncio` and set `asyncio_mode = "auto"` in `[tool.pytest.ini_options]`.

## Linting

```bash
uv run ruff check .        # lint
uv run ruff format .       # format (ruff)
uv run black .             # format (black)
```

Line length is 100 for both ruff and black.

## New Project

Use `uv init --lib <name>` to scaffold. Edit `pyproject.toml` to add dependency-groups and tool config per the template above. Run `uv sync` to create `.venv` and install deps.

## Environment

Source `.envrc` before running scripts when present:

```bash
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd) && [[ -f "$PROJECT_ROOT/.envrc" ]] && source "$PROJECT_ROOT/.envrc"
```
