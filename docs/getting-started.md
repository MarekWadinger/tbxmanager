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

That's it -- one file, no compilation, no admin rights. This downloads the package manager, sets up its storage directory (`~/.tbxmanager/`), and saves the MATLAB path so it persists between sessions.

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

## Install your first package

Let's install [MPT3](http://control.ee.ethz.ch/~mpt/) -- the Multi-Parametric Toolbox, a popular control systems library with 10 dependencies. With tbxmanager, it's one command:

```matlab
>> tbx install mpt --yes
Resolving dependencies...

Installation plan:
  + yalmip@R20250626_fix2 (all)
  + sedumi@1.3 (maca64)
  + lcp@1.0.3 (maca64)
  + cddmex@1.0.1 (maca64)
  + glpkmex@1.0 (maca64)
  + clpmex@1.0 (maca64)
  + espresso@1.0 (maca64)
  + hysdel@2.0.6 (maca64)
  + oasesmex@3.2.0 (maca64)
  + qpspline@1.0 (all)
  + mpt@3.2.1 (all)

Done in 8.2s. 11 package(s) installed.
```

tbxmanager resolved all 10 dependencies, downloaded the correct platform-specific archives (notice `maca64` for Apple Silicon), verified their SHA256 integrity, and added everything to your MATLAB path. The `--yes` flag skips the confirmation prompt.

<!-- markdownlint-disable MD046 -->

!!! tip "Use `tbx` instead of `tbxmanager`"
    The `tbx` shorthand is created automatically during setup. All examples on this page use it.

    Commands can also be abbreviated to their unique prefix:

    | You type | Same as |
    | -------- | ------- |
    | `tbx inst mpt` | `tbx install mpt` |
    | `tbx up` | `tbx update` |
    | `tbx ls` | `tbx list` |
    | `tbx se mpt` | `tbx search mpt` |

<!-- markdownlint-enable MD046 -->

### Version constraints

Need a specific version? Pin it when installing:

```matlab
tbx install mpt@>=3.0        % minimum version
tbx install lcp@==1.0.3      % exact version
tbx install mpt@~=3.2        % compatible release (>=3.2, <4.0)
tbx install mpt@>=3.0,<4.0   % range (comma = AND)
```

## Discover packages

Find what's available in the registry:

```matlab
>> tbx search mpt
Found 5 package(s):

Name        Latest     Description
----------------------------------------------------------------------
mpt         3.2.1      Multi-Parametric Toolbox 3.0
mpt2        2.6.3      MPT2
mpt3lowcom  1.0.3      Low-complexity control design module for MPT3
mptdoc      3.0.4      Multi-Parametric Toolbox documentation
mptplus     R20260508  mptplus
```

Want to know more about a package before installing? Use `info`:

```matlab
>> tbx info mpt
Package: mpt
Description: Multi-Parametric Toolbox 3.0
Homepage: http://control.ee.ethz.ch/~mpt/
Authors: mpt@control.ee.ethz.ch
Latest version: 3.2.1
Installed version: 3.2.1

Available versions:
  3.2.1 (released: 2018-06-07) [matlab: >=R2014a]
    requires: yalmip *
    requires: sedumi *
    requires: lcp *
    ...
    platforms: all
```

## See what you have

Check which packages are installed and whether updates are available:

```matlab
>> tbx list
Name      Version         Latest          Status
---------------------------------------------------
cddmex    1.0.1           1.0.1           enabled
clpmex    1.0             1.0             enabled
espresso  1.0             1.0             enabled
glpkmex   1.0             1.0             enabled
hysdel    2.0.6           2.0.6           enabled
lcp       1.0.3           1.0.3           enabled
mpt       3.2.1           3.2.1           enabled
oasesmex  3.2.0           3.2.0           enabled
qpspline  1.0             1.0             enabled
sedumi    1.3             1.3             enabled
yalmip    R20250626_fix2  R20250626_fix2  enabled
```

Visualize the dependency tree to understand how packages relate:

```matlab
>> tbx tree
mpt@3.2.1
├── yalmip@R20250626_fix2
├── sedumi@1.3
├── lcp@1.0.3
├── cddmex@1.0.1
├── glpkmex@1.0
├── clpmex@1.0
├── espresso@1.0
├── hysdel@2.0.6
├── oasesmex@3.2.0
└── qpspline@1.0
```

## Keep packages up to date

Update all installed packages to their latest versions:

```matlab
>> tbx update
  cddmex: 1.0.1 (up to date)
  clpmex: 1.0 (up to date)
  espresso: 1.0 (up to date)
  glpkmex: 1.0 (up to date)
  hysdel: 2.0.6 (up to date)
  lcp: 1.0.3 (up to date)
  mpt: 3.2.1 (up to date)
  oasesmex: 3.2.0 (up to date)
  qpspline: 1.0 (up to date)
  sedumi: 1.3 (up to date)
  yalmip: R20250626_fix2 (up to date)
All packages are up to date.
```

Or update a specific package: `tbx update mpt`

## Uninstall

```matlab
>> tbx uninstall oasesmex --yes
Warning: Package 'oasesmex' is required by: mpt
Uninstalled oasesmex@3.2.0.
```

tbxmanager warns you when other packages depend on the one being removed, so you can reconsider before breaking your setup (well, if you do not append that --yes flag).

---

## Project dependencies

The commands above manage **global** packages -- available in every MATLAB session. For **reproducible, shareable** research environments, use a project file instead. This is similar to `requirements.txt` / `pyproject.toml` in Python or `package.json` in JavaScript.

### Initialize a project

```matlab
>> tbx init
Created /home/user/my-project/tbxmanager.json
Disabling 2 global package(s) for project isolation.
Fill in 'description' and 'platforms' URLs, then run 'tbx add <pkg>'.
Use 'tbx restorepath' to re-enable global packages when done.
```

This creates a `tbxmanager.json` manifest in the current directory and disables global packages to keep the project environment isolated.

### Add dependencies

```matlab
>> tbx add lcp --yes
  + lcp@>=1.0.3
Done in 0.8s.

>> tbx add sedumi --yes
  + sedumi@>=1.3
Done in 0.5s.
```

`add` updates `tbxmanager.json`, regenerates the lock file, and syncs the environment -- all in one step.

### Remove dependencies

```matlab
>> tbx remove sedumi
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

### Lock: pin exact versions

Generate a lock file that records the exact resolved versions and SHA256 hashes:

```matlab
>> tbx lock
Generating lock file from /home/user/my-project/tbxmanager.json ...
Lock file written to /home/user/my-project/tbxmanager.lock

Resolved packages:
  lcp@1.0.3
```

The lock file captures everything needed to reproduce your environment:

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
    The lock file is auto-generated -- never edit it by hand. Commit `tbxmanager.lock` to version control so collaborators get identical package versions.

### Sync: reproduce the environment

When a collaborator clones your project, one command installs everything:

```matlab
>> tbx sync
Syncing from /home/user/my-project/tbxmanager.lock ...
Everything is up to date.
```

`sync` installs the exact versions from `tbxmanager.lock`, verifying SHA256 integrity. Everyone gets the same packages, every time.

### Verify consistency

Check that your installed packages match the lock file:

```matlab
>> tbx check
  ✓ lcp@1.0.3
```

Symbols: `✓` matches lock, `✗` version mismatch, `!` missing or extra package. Run `tbx sync` to fix any discrepancies.

---

## Self-update

Keep tbxmanager itself up to date:

```matlab
tbx selfupdate
```

## Use in scripts

Add `require` at the top of any MATLAB script to declare its package dependencies:

```matlab
tbx require mpt@>=3.0 sedumi
```

If any package is missing or the wrong version, MATLAB throws a clear error before your code runs. This makes scripts self-documenting -- anyone reading the file immediately sees what it needs. See the [require command reference](commands.md#require) for more examples.

## Next steps

- [Concepts](concepts.md) -- how tbxmanager works under the hood
- [Command Reference](commands.md) -- all commands with full syntax
- [Quick Start for Authors](quick-start-authors.md) -- publish your own package
- [Troubleshooting](troubleshooting.md) -- common issues and solutions

<!-- test -->
