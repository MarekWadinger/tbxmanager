# Concepts

This page explains how tbxmanager works under the hood. Understanding these concepts helps you troubleshoot issues and make better decisions about how to manage your MATLAB packages.

## Architecture Overview

tbxmanager has four main components. Data flows left to right:

```text
Registry          Index             Client            Local Store
(GitHub repo)  →  (GitHub Pages)  →  (tbxmanager.m)  →  (~/.tbxmanager/)
```

**Registry** -- A GitHub repository ([MarekWadinger/tbxmanager-registry](https://github.com/MarekWadinger/tbxmanager-registry)) containing a `package.json` file for every published package. Anyone can submit a new package by opening a pull request.

**Index** -- A single `index.json` file auto-generated from the registry and hosted on GitHub Pages. The client fetches this file to discover available packages, their versions, and download URLs.

**Client** -- `tbxmanager.m`, a single MATLAB file that handles everything: searching, downloading, installing, versioning, and path management. The single-file design makes installation a one-liner.

**Local store** -- The `~/.tbxmanager/` directory on your machine, containing installed packages, a download cache, and configuration files.

## Storage Layout

```text
~/.tbxmanager/
├── packages/[name]/[version]/   # Installed package files
├── cache/                        # Downloaded archives (reused on reinstall)
├── state/
│   ├── enabled.json              # Currently enabled packages
│   └── sources.json              # Package index URLs
└── config.json                   # User settings (e.g., GitHub token)
```

- **packages/** holds extracted package files, organized by name and version. Each version is a separate directory so multiple versions can coexist.
- **cache/** stores downloaded `.zip` archives. If you uninstall and reinstall a package, tbxmanager reuses the cached archive instead of downloading again.
- **state/enabled.json** tracks which packages are currently on the MATLAB path.
- **state/sources.json** lists the index URLs tbxmanager checks for packages.
- **config.json** stores user preferences like a GitHub token for accessing private packages.

## Package Resolution

When you run:

```matlab
tbxmanager install mpt
```

the client performs these steps:

1. **Fetches the index** from GitHub Pages (or a cached copy if recent enough).
2. **Finds the package** and all its dependencies, including transitive ones (dependencies of dependencies).
3. **Solves version constraints** to find a set of compatible versions that satisfy every requirement.
4. **Downloads archives** for each package, checking the local cache first.
5. **Verifies SHA256 hashes** to confirm each download matches the expected checksum. This catches corrupted or tampered files.
6. **Extracts packages** to `~/.tbxmanager/packages/[name]/[version]/`.
7. **Adds directories to the MATLAB path** so you can use the packages immediately.

## Lockfiles

A lockfile (`tbxmanager.lock`) records the exact resolved versions and SHA256 hashes for every package in a project.

**Why lockfiles matter:** Without a lockfile, running `tbxmanager install` on two different machines might pick different versions if a new release appeared in between. The lockfile pins every version so that all collaborators get identical environments.

**Workflow:**

```matlab
% Generate or update the lockfile from tbxmanager.json
tbxmanager lock

% Install exactly what the lockfile specifies
tbxmanager sync
```

!!! tip
    Commit `tbxmanager.lock` to version control. Never edit it by hand -- regenerate it with `tbxmanager lock` whenever you change dependencies.

## Platforms

MATLAB packages can contain platform-specific compiled files (MEX files). tbxmanager uses five platform identifiers:

| Platform | Architecture | When to use |
| -------- | ----------- | ----------- |
| `all` | Any | Pure MATLAB code (no MEX files) |
| `win64` | Windows 64-bit | Packages with `.mexw64` files |
| `maci64` | macOS Intel | Packages with `.mexmaci64` files |
| `maca64` | macOS Apple Silicon | Packages with `.mexmaca64` files |
| `glnxa64` | Linux 64-bit | Packages with `.mexa64` files |

tbxmanager detects your platform automatically using MATLAB's `computer('arch')` command and downloads the correct archive. If you are running Intel MATLAB on Apple Silicon via Rosetta, it reports `maci64` -- this is correct, because Intel MEX files are what that MATLAB session needs.

## Global vs. Project Mode

tbxmanager supports two ways of managing packages:

**Global mode** (`install`, `uninstall`, `update`) -- Packages live in `~/.tbxmanager/packages/` and are available across all MATLAB sessions. Use this for tools you always want at hand.

**Project mode** (`init`, `add`, `remove`, `lock`, `sync`) -- Dependencies are declared in a `tbxmanager.json` file and pinned in `tbxmanager.lock`. Use this for reproducible, shareable research environments where every collaborator needs the same setup.

The two modes can coexist. However, `tbxmanager init` disables global packages to keep the project environment isolated. To re-enable them afterward, run:

```matlab
tbxmanager restorepath
```
