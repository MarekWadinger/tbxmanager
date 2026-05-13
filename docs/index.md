---
hide:
  - navigation
  - toc
---

# tbxmanager

**A modern package manager for MATLAB** with dependency resolution, lockfiles, and a community registry.

```matlab
websave('tbxmanager.m', 'https://marekwadinger.github.io/tbxmanager/tbxmanager.m');
tbxmanager
savepath
```

[Get Started](getting-started.md){ .md-button .md-button--primary }
[Browse Packages](https://github.com/MarekWadinger/tbxmanager-registry){ .md-button }

---

<div class="grid cards" markdown>

-   :material-download:{ .lg .middle } **One-Line Install**

    ---

    Download a single file and you're ready. No compilation, no prerequisites beyond MATLAB R2022a+.

-   :material-source-branch:{ .lg .middle } **Dependency Resolution**

    ---

    Automatically resolves and installs transitive dependencies with version constraint satisfaction.

-   :material-lock:{ .lg .middle } **Reproducible Environments**

    ---

    Lock exact versions with `tbxmanager lock`. Share `tbxmanager.lock` for identical setups across machines.

-   :material-account-group:{ .lg .middle } **Community Registry**

    ---

    Open package registry. Anyone can contribute packages via pull request or `tbxmanager publish`. CI validates every submission.

-   :material-monitor:{ .lg .middle } **Cross-Platform**

    ---

    Windows, macOS (Intel & Apple Silicon), and Linux. Platform-specific packages resolved automatically.

-   :material-shield-check:{ .lg .middle } **Integrity Verification**

    ---

    Every download verified with SHA256 checksums. No tampered packages reach your MATLAB path.

</div>

## Why tbxmanager?

<!-- markdownlint-disable MD046 -->
=== "With tbxmanager"

    ```matlab
    tbxmanager install mpt
    % Done. Dependencies resolved, verified, and on your path.
    ```

=== "Without tbxmanager"

    ```matlab
    % 1. Find the toolbox website, download the zip
    % 2. Extract to some folder
    % 3. Add to path (and hope you got the right subfolder)
    addpath(genpath('/Users/me/Downloads/mpt-3.2.1'))
    % 4. Repeat for every dependency...
    addpath(genpath('/Users/me/Downloads/sedumi-1.3'))
    addpath(genpath('/Users/me/Downloads/yalmip'))
    % 5. Hope the versions are compatible
    % 6. Tell your collaborator to do the same (good luck)
    ```
<!-- markdownlint-enable MD046 -->

tbxmanager is to MATLAB what [pip](https://pip.pypa.io) or [uv](https://docs.astral.sh/uv/) is to Python or npm is to JavaScript — a package manager that handles downloads, dependencies, and versioning so you don't have to.

!!! tip "Use `tbx` instead of `tbxmanager`"
    The `tbx` shorthand is created automatically during setup. All examples below use it.

## Quick Start

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

Installing 11 package(s)...

Done in 7.1s. 11 package(s) installed.
```

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

!!! tip "Command abbreviations"
    Commands can be abbreviated to their unique prefix: `tbx inst mpt` works like `tbx install mpt`.

[Get Started :material-arrow-right:](getting-started.md){ .md-button .md-button--primary }
