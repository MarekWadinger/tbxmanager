---
hide:
  - navigation
  - toc
---

# tbxmanager

**A modern package manager for MATLAB** with dependency resolution, lockfiles, and a community registry.

```matlab
websave('tbxmanager.m', 'https://tbxmanager.com/tbxmanager.m');
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

    Automatically resolves and installs package dependencies with version constraint satisfaction.

-   :material-lock:{ .lg .middle } **Reproducible Environments**

    ---

    Lock exact versions with `tbxmanager lock`. Share `tbxmanager.lock` for identical setups across machines.

-   :material-account-group:{ .lg .middle } **Community Registry**

    ---

    Open package registry. Anyone can contribute packages via pull request. CI validates every submission.

-   :material-monitor:{ .lg .middle } **Cross-Platform**

    ---

    Windows, macOS (Intel & Apple Silicon), and Linux. Platform-specific packages resolved automatically.

-   :material-shield-check:{ .lg .middle } **Integrity Verification**

    ---

    Every download verified with SHA256 checksums. No tampered packages reach your MATLAB path.

</div>

## Why tbxmanager?

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

=== "With tbxmanager"

    ```matlab
    tbxmanager install mpt
    % Done. Dependencies resolved, verified, and on your path.
    ```

tbxmanager is to MATLAB what [pip](https://pip.pypa.io) is to Python or npm is to JavaScript — a package manager that handles downloads, dependencies, and versioning so you don't have to.

## Quick Start

```matlab
% Install a package
tbxmanager install mpt

% Search for packages
tbxmanager search optimization

% List installed packages
tbxmanager list

% Update all packages
tbxmanager update

% Create reproducible project dependencies
tbxmanager init
tbxmanager lock
tbxmanager sync
```
