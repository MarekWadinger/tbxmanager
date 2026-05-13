<p align="center">
  <img src="docs/assets/logo.png" alt="tbxmanager" width="200">
</p>

<h1 align="center">tbxmanager</h1>

<p align="center">
  <em>A modern package manager for MATLAB.</em>
</p>

<p align="center">
  <a href="https://github.com/MarekWadinger/tbxmanager/actions/workflows/test.yml"><img src="https://github.com/MarekWadinger/tbxmanager/actions/workflows/test.yml/badge.svg" alt="Test"></a>
  <a href="https://codecov.io/gh/MarekWadinger/tbxmanager"><img src="https://codecov.io/gh/MarekWadinger/tbxmanager/graph/badge.svg?token=TmB6OzWFfo" alt="codecov"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License: MIT"></a>
  <a href="https://mathworks.com/products/matlab.html"><img src="https://img.shields.io/badge/MATLAB-R2022a+-orange.svg" alt="MATLAB R2022a+"></a>
</p>

---

## Highlights

- **One-line install** -- single MATLAB file, no compilation, no prerequisites beyond MATLAB R2022a+
- **Dependency resolution** -- automatic transitive dependencies with version constraints
- **Lockfiles** -- reproducible environments with `tbxmanager.lock`, shareable across machines
- **SHA256 verification** -- every download checked for integrity before reaching your path
- **Cross-platform** -- Windows, macOS (Intel & Apple Silicon), Linux, with automatic platform detection
- **Community registry** -- open package index at [tbxmanager-registry](https://github.com/MarekWadinger/tbxmanager-registry), anyone can submit
- **Command shorthand** -- `tbx inst mpt` works just like `tbxmanager install mpt`

## Installation

```matlab
websave('tbxmanager.m', 'https://marekwadinger.github.io/tbxmanager/tbxmanager.m');
tbxmanager
savepath
```

Add to your `startup.m` for automatic path restoration:

```matlab
tbxmanager restorepath
```

See the [installation guide](https://marekwadinger.github.io/tbxmanager/getting-started) for details.

## Projects

tbxmanager manages project dependencies through `tbxmanager.json`, similar to `package.json` or `pyproject.toml`. Each project declares its dependencies and gets a lockfile for reproducible installs.

Initialize a project, add dependencies, and share the lockfile with collaborators:

```matlab
>> tbxmanager init
Created /home/user/my-project/tbxmanager.json
Disabling 2 global package(s) for project isolation.
Fill in 'description' and 'platforms' URLs, then run 'tbxmanager add <pkg>'.
Use 'tbxmanager restorepath' to re-enable global packages when done.

>> tbxmanager add lcp --yes
  + lcp@>=1.0.3
Done in 0.8s.

>> tbxmanager add sedumi --yes
  + sedumi@>=1.3
Done in 0.5s.

>> tbxmanager remove sedumi
  - sedumi removed from tbxmanager.json
Done in 0.4s.

>> tbxmanager tree
my-project
+-- lcp@1.0.3
```

When a collaborator clones the project, `sync` installs the exact versions from the lockfile:

```matlab
>> tbxmanager sync
Syncing from /home/user/my-project/tbxmanager.lock ...
Everything is up to date.
```

Verify the environment matches the lockfile without making changes:

```matlab
>> tbxmanager check
  ✓ lcp@1.0.3
```

See the [project documentation](https://marekwadinger.github.io/tbxmanager/getting-started#project-dependencies) to get started.

## Global Packages

For quick one-off installs outside a project context, `install` and `uninstall` work directly on the global MATLAB path. These are the classic tbxmanager commands, compatible with scripts and CI workflows that don't use a project file:

```matlab
>> tbxmanager install oasesmex --yes
Resolving dependencies...

Installation plan:
  + oasesmex@3.2.0 (maca64)

Installing oasesmex@3.2.0 ...
  Downloading...
  Verifying SHA256...
  Extracting...
  Enabled oasesmex@3.2.0.

Done in 1.2s. 1 package(s) installed.

>> tbxmanager list
Name      Version         Latest          Status
----------------------------------------------------
lcp       1.0.3           1.0.3           disabled
oasesmex  3.2.0           3.2.0           disabled
sedumi    1.3             1.3             disabled
yalmip    R20250626_fix2  R20250626_fix2  disabled

>> tbxmanager search toolbox
Found 3 package(s):

Name    Latest       Description
---------------------------------------------------------------
brcm    v0.96(Beta)  The Building Resistance-Capacitance ...
mpt     3.2.1        Multi-Parametric Toolbox 3.0
mptdoc  3.0.4        Multi-Parametric Toolbox documentation

>> tbxmanager update
  lcp: 1.0.3 (up to date)
  oasesmex: 3.2.0 (up to date)
  sedumi: 1.3 (up to date)
  yalmip: R20250626_fix2 (up to date)
All packages are up to date.

>> tbxmanager uninstall oasesmex
Uninstalled oasesmex@3.2.0.
```

> **Note:** `install`/`uninstall` modify the global package store. In a project with `tbxmanager.json`, prefer `add`/`remove` -- they keep the manifest and lockfile in sync and won't affect packages used by other projects.

See the [command reference](https://marekwadinger.github.io/tbxmanager/commands) for all options.

## Publishing Packages

Publish your own MATLAB toolbox to the community registry:

```matlab
>> tbxmanager init        % creates tbxmanager.json with package metadata
>> tbxmanager publish     % builds archive, creates GitHub release, submits to registry
```

Or [submit manually](https://github.com/MarekWadinger/tbxmanager-registry/issues/new?template=submit-package.yml) via the registry issue form. See the [Quick Start for Authors](https://marekwadinger.github.io/tbxmanager/quick-start-authors) for the full guide.

## Documentation

Full documentation at [marekwadinger.github.io/tbxmanager](https://marekwadinger.github.io/tbxmanager):

- [Getting Started](https://marekwadinger.github.io/tbxmanager/getting-started)
- [Command Reference](https://marekwadinger.github.io/tbxmanager/commands)
- [Creating Packages](https://marekwadinger.github.io/tbxmanager/quick-start-authors)
- [Troubleshooting](https://marekwadinger.github.io/tbxmanager/troubleshooting)

## Contributing

[Submit packages](https://github.com/MarekWadinger/tbxmanager-registry/issues/new?template=submit-package.yml) to the registry, or contribute to the client by opening a PR to the `dev` branch. See the [contributing guide](https://marekwadinger.github.io/tbxmanager/contributing).

## Acknowledgements

tbxmanager was originally developed by [Michal Kvasnica](https://github.com/kvasnica) as the package manager for the [Multi-Parametric Toolbox (MPT)](https://www.mpt3.org/). This version is a ground-up rewrite inspired by modern tools like [uv](https://github.com/astral-sh/uv).

If you use tbxmanager in academic work, please see [CITATION.cff](CITATION.cff) for citation information.

## License

[MIT](LICENSE)
