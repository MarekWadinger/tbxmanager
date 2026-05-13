# Command Reference

All commands can be abbreviated to their shortest unique prefix (e.g., `tbx inst` for `tbxmanager install`). Use `--yes` / `-y` to skip confirmation prompts and `--quiet` / `-q` to suppress output.

<!-- markdownlint-disable MD051 -->
| Command | Category | Description | Shorthand |
| ------- | -------- | ----------- | --------- |
| [`install`](#install) | Global | Install packages with dependency resolution | `inst` |
| [`uninstall`](#uninstall) | Global | Remove installed packages | `unin` |
| [`update`](#update) | Global | Update packages to latest versions | `up` |
| [`list`](#list) | Global | Show installed packages | `ls` |
| [`search`](#search) | Global | Search available packages | `se` |
| [`info`](#info) | Global | Show package details | `inf` |
| [`tree`](#tree) | Global | Show dependency tree | `tr` |
| [`init`](#init) | Project | Create `tbxmanager.json` template | `ini` |
| [`add`](#add) | Project | Add dependency and sync | `ad` |
| [`remove`](#remove) | Project | Remove dependency and sync | `rem` |
| [`lock`](#lock) | Project | Generate lock file | `lo` |
| [`sync`](#sync) | Project | Install from lock file | `sy` |
| [`check`](#check) | Project | Verify lock file consistency | `ch` |
| [`publish`](#publish) | Project | Publish package to registry | `pub` |
| [`enable`](#enable-disable) | Path | Add packages to MATLAB path | `en` |
| [`disable`](#enable-disable) | Path | Remove packages from MATLAB path | `dis` |
| [`restorepath`](#restorepath) | Path | Restore all enabled package paths | `res` |
| [`require`](#require) | Path | Assert packages are installed | `req` |
| [`selfupdate`](#selfupdate) | Maintenance | Update tbxmanager itself | `self` |
| [`source`](#source) | Maintenance | Manage package index sources | `so` |
| [`cache`](#cache) | Maintenance | Manage download cache | `ca` |
| [`help`](#help) | Maintenance | Show help text | `h` |
<!-- markdownlint-enable MD051 -->

!!! tip "Prefix matching"
    The shorthands above are the shortest unambiguous prefixes. Any unique prefix works — for example, `instal` and `inst` both resolve to `install`. Prefixes that match multiple commands (like `in`) produce an error listing the matches.

---

## Global Commands

These commands operate on the global package store at `~/.tbxmanager/`.

### install

Install one or more packages with automatic dependency resolution.

```matlab
tbxmanager install pkg1 [pkg2@>=1.0] ...
```

Version constraints can be appended with `@`:

| Constraint | Meaning |
| ---------- | ------- |
| `pkg@>=1.0` | Minimum version |
| `pkg@<2.0` | Upper bound |
| `pkg@==1.2.3` | Exact version |
| `pkg@~=1.2` | Compatible release (`>=1.2, <2.0`) |
| `pkg@>=1.0,<2.0` | Range (comma = AND) |

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
```

Packages are downloaded to `~/.tbxmanager/cache/`, verified with SHA256, extracted to `~/.tbxmanager/packages/`, and added to the MATLAB path.

### uninstall

Remove installed packages.

```matlab
tbxmanager uninstall pkg1 [pkg2] ...
```

Warns if other installed packages depend on the one being removed:

```matlab
>> tbxmanager uninstall sedumi
Warning: Package 'sedumi' is required by: mpt2
```

### update

Update packages to their latest available versions.

```matlab
tbxmanager update              % update all
tbxmanager update pkg1 ...     % update specific packages
```

```matlab
>> tbxmanager update
  cddmex: 1.0.1 (up to date)
  lcp: 1.0.3 (up to date)
  sedumi: 1.3 (up to date)
All packages are up to date.
```

### list

Show installed packages with version and status information.

```matlab
>> tbxmanager list
Name      Version         Latest          Status
----------------------------------------------------
cddmex    1.0.1           1.0.1           disabled
lcp       1.0.3           1.0.3           disabled
oasesmex  3.2.0           3.2.0           disabled
sedumi    1.3             1.3             disabled
yalmip    R20250626_fix2  R20250626_fix2  disabled
```

### search

Search available packages by name or description.

```matlab
>> tbxmanager search toolbox
Found 3 package(s):

Name    Latest       Description
---------------------------------------------------------------
brcm    v0.96(Beta)  The Building Resistance-Capacitance ...
mpt     3.2.1        Multi-Parametric Toolbox 3.0
mptdoc  3.0.4        Multi-Parametric Toolbox documentation
```

### info

Show detailed information about a package.

```matlab
>> tbxmanager info mpt
Package: mpt
Description: Multi-Parametric Toolbox 3.0
Homepage: http://control.ee.ethz.ch/~mpt/
Authors: mpt@control.ee.ethz.ch
Latest version: 3.2.1

Available versions:
  3.2.1 (released: 2018-06-07) [matlab: >=R2014a]
    requires: yalmip *
    requires: sedumi *
    requires: lcp *
    requires: cddmex *
    ...
    platforms: all
```

### tree

Show installed packages as a dependency tree.

```matlab
>> tbxmanager tree
mpt2@2.6.3
+-- yalmip@R20250626_fix2
+-- sedumi@1.3
+-- lcp@1.0.3
+-- cddmex@1.0.1
+-- glpkmex@1.0
+-- clpmex@1.0
+-- espresso@1.0
\-- hysdel@2.0.6
oasesmex@3.2.0
qpspline@1.0
```

---

## Project Commands

These commands require a `tbxmanager.json` in the current directory. Use them for reproducible, shareable environments.

### init

Create a `tbxmanager.json` template in the current directory.

```matlab
>> tbxmanager init
Created /home/user/my-project/tbxmanager.json
Disabling 2 global package(s) for project isolation.
Fill in 'description' and 'platforms' URLs, then run 'tbxmanager add <pkg>'.
```

Global packages are automatically disabled to isolate the project environment. Use `tbxmanager restorepath` to re-enable them when done.

### add

Add packages to the project manifest and sync.

```matlab
tbxmanager add pkg1 [pkg2@>=1.0] ...
```

```matlab
>> tbxmanager add lcp --yes
  + lcp@>=1.0.3
Done in 0.8s.
```

This edits `tbxmanager.json`, regenerates the lock file, and syncs the environment -- all in one step. The resolved version is back-filled into the manifest (e.g., `lcp@>=1.0.3` after resolving to `1.0.3`).

For global installs without a project file, use `tbxmanager install` instead.

### remove

Remove packages from the project manifest and sync.

```matlab
>> tbxmanager remove sedumi
  - sedumi removed from tbxmanager.json
Done in 0.4s.
```

### lock

Generate `tbxmanager.lock` from `tbxmanager.json`.

```matlab
>> tbxmanager lock
Generating lock file from /home/user/my-project/tbxmanager.json ...
Lock file written to /home/user/my-project/tbxmanager.lock

Resolved packages:
  lcp@1.0.3
```

Resolves all dependencies for the current platform and writes pinned versions with SHA256 hashes.

### sync

Install exact versions from `tbxmanager.lock`.

```matlab
>> tbxmanager sync
Syncing from /home/user/my-project/tbxmanager.lock ...
Everything is up to date.
```

Packages not listed in the lock file are disabled (removed from path, but not deleted from disk).

### check

Verify installed packages match the lock file without making changes.

```matlab
>> tbxmanager check
  ✓ lcp@1.0.3
  ! cddmex@1.0.1 not in lock file
```

Symbols:

- `✓` -- installed version matches lock
- `✗` -- version mismatch
- `!` -- missing or extra package

Run `tbxmanager sync` to fix discrepancies.

### publish

Publish a package to the registry.

```matlab
tbxmanager publish
```

Reads `tbxmanager.json` from the current directory, builds a zip archive, creates a GitHub release, uploads the archive, and submits to the tbxmanager registry.

Requires a GitHub token with `public_repo` scope. The token is prompted on first use and saved to `~/.tbxmanager/config.json`.

See [Quick Start for Authors](quick-start-authors.md) for the full publishing guide.

---

## Path Commands

### enable / disable

Manage which installed packages are on the MATLAB path.

```matlab
tbxmanager enable mpt sedumi
tbxmanager disable mpt
```

### restorepath

Restore all enabled packages to the MATLAB path. Add to `startup.m` for automatic setup on every MATLAB launch:

```matlab
tbxmanager restorepath
```

### require

Assert that packages are installed and enabled. Place at the top of scripts to declare dependencies up front.

```matlab
tbxmanager require mpt cddmex@>=1.0
```

Throws an error listing which packages are missing or version-mismatched. This makes scripts self-documenting — anyone reading the script immediately sees its package requirements.

#### Script example

```matlab
% my_analysis.m — Reproducible parameter identification
tbxmanager require rls-identification@>=1.0 mpt@>=3.0

% If we get here, all packages are guaranteed available
data = load('experiment_data.mat');
params = recursiveLeastSquares(data.input, data.output);
```

#### CI example

Use `require` as a pre-flight check in GitHub Actions:

```yaml
- name: Run MATLAB tests
  uses: matlab-actions/run-command@v2
  with:
    command: |
      tbxmanager restorepath
      tbxmanager require mpt@>=3.0 sedumi
      runtests('tests')
```

---

## Maintenance

### selfupdate

Update tbxmanager itself to the latest version.

```matlab
tbxmanager selfupdate
```

Compares SHA256 before replacing. Runs `rehash` after a successful update.

### source

Manage package index sources.

```matlab
>> tbxmanager source list
Configured sources:
  1. https://marekwadinger.github.io/tbxmanager-registry/index.json

tbxmanager source add https://example.com/index.json
tbxmanager source remove https://example.com/index.json
```

### cache

Manage the download cache at `~/.tbxmanager/cache/`.

```matlab
>> tbxmanager cache list
  lcp-1.0.3.tgz (54.4 KB)
  mpt-3.2.1.tgz (580.5 KB)
  sedumi-1.3.zip (297.2 KB)
  yalmip-R20250626_fix2.zip (1.1 MB)

Total: 19 file(s), 8.7 MB
```

```matlab
tbxmanager cache clean    % remove all cached files
```

### help

Show help text for all commands or a specific command.

```matlab
tbxmanager help
tbxmanager help install
```
