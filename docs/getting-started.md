# Getting Started

## Prerequisites

- **MATLAB R2022a** or newer

## Installation

Run these three lines in the MATLAB Command Window:

```matlab
websave('tbxmanager.m', 'https://marekwadinger.github.io/tbxmanager/tbxmanager.m');
tbxmanager
savepath
```

This downloads the package manager, initializes its storage directory (`~/.tbxmanager/`), and saves the MATLAB path.

<!-- markdownlint-disable MD046 -->
!!! tip "Auto-restore on startup"
    Add this line to your `startup.m` so installed packages are available every time MATLAB starts:

    ```matlab
    tbxmanager restorepath
    ```

    To find or create your `startup.m`:

    ```matlab
    edit(fullfile(userpath, 'startup.m'))
    ```
<!-- markdownlint-enable MD046 -->

## Install Your First Package

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

tbxmanager resolves dependencies, downloads archives, verifies SHA256 integrity, and adds everything to your MATLAB path. Use the `--yes` flag to skip the confirmation prompt.

<!-- markdownlint-disable MD046 -->
!!! tip "Command shorthand"
    All commands can be abbreviated to their unique prefix. The `tbx` alias also works:

    | You type | Same as |
    | -------- | ------- |
    | `tbx inst mpt` | `tbxmanager install mpt` |
    | `tbx up` | `tbxmanager update` |
    | `tbx ls` | `tbxmanager list` |
    | `tbx se toolbox` | `tbxmanager search toolbox` |
<!-- markdownlint-enable MD046 -->

### Version constraints

Pin versions when installing:

```matlab
tbxmanager install mpt@>=3.0        % minimum version
tbxmanager install lcp@==1.0.3      % exact version
tbxmanager install mpt@~=3.2        % compatible release (>=3.2, <4.0)
tbxmanager install mpt@>=3.0,<4.0   % range (comma = AND)
```

## Search for Packages

```matlab
>> tbxmanager search toolbox
Found 3 package(s):

Name    Latest       Description
---------------------------------------------------------------
brcm    v0.96(Beta)  The Building Resistance-Capacitance ...
mpt     3.2.1        Multi-Parametric Toolbox 3.0
mptdoc  3.0.4        Multi-Parametric Toolbox documentation
```

## Inspect a Package

```matlab
>> tbxmanager info mpt
Package: mpt
Description: Multi-Parametric Toolbox 3.0
Homepage: http://control.ee.ethz.ch/~mpt/
Authors: mpt@control.ee.ethz.ch
Latest version: 3.2.1
Not installed.

Available versions:
  3.2.1 (released: 2018-06-07) [matlab: >=R2014a]
    requires: yalmip *
    requires: sedumi *
    requires: lcp *
    ...
    platforms: all
```

## List Installed Packages

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

## Dependency Tree

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
```

## Update Packages

```matlab
>> tbxmanager update
  cddmex: 1.0.1 (up to date)
  lcp: 1.0.3 (up to date)
  oasesmex: 3.2.0 (up to date)
  sedumi: 1.3 (up to date)
  yalmip: R20250626_fix2 (up to date)
All packages are up to date.
```

Update a specific package:

```matlab
tbxmanager update mpt
```

## Uninstall

```matlab
tbxmanager uninstall oasesmex
```

tbxmanager warns you if other installed packages depend on the one being removed.

---

## Project Dependencies

For reproducible, shareable environments, use a project file instead of global installs.

### Initialize a project

```matlab
>> tbxmanager init
Created /home/user/my-project/tbxmanager.json
Disabling 2 global package(s) for project isolation.
Fill in 'description' and 'platforms' URLs, then run 'tbxmanager add <pkg>'.
Use 'tbxmanager restorepath' to re-enable global packages when done.
```

This creates a `tbxmanager.json` in the current directory and disables global packages to keep the project environment isolated.

### Add dependencies

```matlab
>> tbxmanager add lcp --yes
  + lcp@>=1.0.3
Done in 0.8s.

>> tbxmanager add sedumi --yes
  + sedumi@>=1.3
Done in 0.5s.
```

`add` updates `tbxmanager.json`, regenerates the lock file, and syncs -- all in one step.

### Remove dependencies

```matlab
>> tbxmanager remove sedumi
  - sedumi removed from tbxmanager.json
Done in 0.4s.
```

### The project file

After `init` and `add`, your `tbxmanager.json` looks like this:

```json
{
  "name": "my-project",
  "version": "0.1.0",
  "description": "",
  "matlab": ">=R2025b",
  "platforms": {
    "all": ""
  },
  "dependencies": {
    "lcp": ">=1.0.3"
  }
}
```

### Generate the lock file

```matlab
>> tbxmanager lock
Generating lock file from /home/user/my-project/tbxmanager.json ...
Lock file written to /home/user/my-project/tbxmanager.lock

Resolved packages:
  lcp@1.0.3
```

The lock file pins every dependency (including transitive ones) to an exact version and SHA256 hash:

```json
{
  "lockfile_version": 1,
  "generated": "2026-05-13T11:25:58Z",
  "requires": {
    "lcp": ">=1.0.3"
  },
  "packages": {
    "lcp": {
      "version": "1.0.3",
      "resolved": {
        "url": "https://raw.githubusercontent.com/.../lcp_1_0_3_MACA64.tgz",
        "sha256": "84063e28bc98fafd08e1ca3b7f2e9d5a1c6f0e4d8b2a7c9f3e5d1b0a8c6f4e2d",
        "platform": "maca64"
      },
      "dependencies": {}
    }
  }
}
```

!!! note
    The lock file is auto-generated by `tbxmanager lock` — never edit it by hand. Commit `tbxmanager.lock` to version control so collaborators get identical package versions.

### Sync: reproduce the environment

When a collaborator clones the project:

```matlab
>> tbxmanager sync
Syncing from /home/user/my-project/tbxmanager.lock ...
Everything is up to date.
```

`sync` installs the exact versions from `tbxmanager.lock`, verifying SHA256 integrity.

### Verify consistency

```matlab
>> tbxmanager check
  ✓ lcp@1.0.3
```

`check` compares installed packages against the lock file without making changes:

- `✓` -- matches lock
- `✗` -- version mismatch
- `!` -- missing or extra package

Run `tbxmanager sync` to fix any discrepancies.

---

## Self-Update

Keep tbxmanager itself up to date:

```matlab
tbxmanager selfupdate
```

## Use in Scripts

Add `require` at the top of any MATLAB script to declare its package dependencies:

```matlab
tbxmanager require mpt@>=3.0 sedumi
```

If any package is missing or the wrong version, MATLAB throws a clear error before your code runs. See the [require command reference](commands.md#require) for more examples.

## Next Steps

- [Command Reference](commands.md) -- all commands with full syntax
- [Quick Start for Authors](quick-start-authors.md) -- publish your own package
- [Troubleshooting](troubleshooting.md) -- common issues and solutions
