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
- **Prefix shorthand** -- `tbx inst mpt` works just like `tbxmanager install mpt`

## Installation

```matlab
websave('tbxmanager.m', 'https://tbxmanager.com/tbxmanager.m');
tbxmanager
savepath
```

Add to your `startup.m` for automatic path restoration:

```matlab
tbxmanager restorepath
```

See the [installation guide](https://tbxmanager.com/getting-started) for details.

## Projects

tbxmanager manages project dependencies through `tbxmanager.json`, similar to `package.json` or `pyproject.toml`. Each project declares its dependencies and gets a lockfile for reproducible installs.

Initialize a project, add dependencies, and share the lockfile with collaborators:

```matlab
>> tbxmanager init
Created tbxmanager.json in /home/user/my-project

>> tbxmanager add mpt
  + mpt@>=3.0.0
Done in 4.2s.

>> tbxmanager add yalmip lcp
  + yalmip@>=1.0.0
  + lcp@>=1.2.0
Done in 3.1s.

>> tbxmanager remove lcp
  - lcp removed from tbxmanager.json
Done in 0.8s.

>> tbxmanager tree
my-project
 +-- mpt@3.0.0
 |    +-- yalmip@1.0.0
 |    +-- lcp@1.2.0
 +-- yalmip@1.0.0
```

When a collaborator clones the project, `sync` installs the exact versions from the lockfile:

```matlab
>> tbxmanager sync
Syncing from tbxmanager.lock ...
Installing/updating 3 package(s):
  + mpt@3.0.0
  + yalmip@1.0.0
  + lcp@1.2.0

Sync complete in 5.3s.
```

See the [project documentation](https://tbxmanager.com/getting-started) to get started.

## Global packages

For quick one-off installs outside a project context, `install` and `uninstall` work directly on the global MATLAB path. These are the classic tbxmanager commands, compatible with scripts and CI workflows that don't use a project file:

```matlab
>> tbxmanager install mpt
Resolving dependencies...
  + mpt@3.0.0
  + yalmip@1.0.0
  + lcp@1.2.0
Installed 3 packages in 6.1s.

>> tbxmanager list
  mpt       3.0.0   enabled
  yalmip    1.0.0   enabled
  lcp       1.2.0   enabled

>> tbxmanager search optimization
  mpt         3.0.0   Multi-Parametric Toolbox
  yalmip      1.0.0   YALMIP optimization toolbox

>> tbxmanager update
Checking for updates...
  mpt 3.0.0 -> 3.1.0
Updated 1 package in 2.4s.

>> tbxmanager uninstall lcp
Uninstalled lcp@1.2.0.
```

> **Note:** `install`/`uninstall` modify the global package store. In a project with `tbxmanager.json`, prefer `add`/`remove` -- they keep the manifest and lockfile in sync and won't affect packages used by other projects.

See the [command reference](https://tbxmanager.com/commands) for all options.

## Publishing packages

Publish your own MATLAB toolbox to the community registry:

```matlab
>> tbxmanager init           % creates tbxmanager.json with package metadata
>> tbxmanager publish        % validates and submits to the registry
```

Or [submit manually](https://github.com/MarekWadinger/tbxmanager-registry/issues/new?template=submit-package.yml) via the registry issue form. See the [Quick Start for Authors](https://tbxmanager.com/quick-start-authors) for the full guide.

## Documentation

Full documentation at [tbxmanager.com](https://tbxmanager.com):

- [Getting Started](https://tbxmanager.com/getting-started)
- [Command Reference](https://tbxmanager.com/commands)
- [Creating Packages](https://tbxmanager.com/quick-start-authors)
- [Troubleshooting](https://tbxmanager.com/troubleshooting)

## Contributing

[Submit packages](https://github.com/MarekWadinger/tbxmanager-registry/issues/new?template=submit-package.yml) to the registry, or contribute to the client by opening a PR to the `dev` branch. See the [contributing guide](https://tbxmanager.com/contributing).

## Acknowledgements

tbxmanager was originally developed by [Michal Kvasnica](https://github.com/kvasnica) as the package manager for the [Multi-Parametric Toolbox (MPT)](https://www.mpt3.org/). This version is a ground-up rewrite inspired by modern tools like [uv](https://github.com/astral-sh/uv).

If you use tbxmanager in academic work, please see [CITATION.cff](CITATION.cff) for citation information.

## License

[MIT](LICENSE)
