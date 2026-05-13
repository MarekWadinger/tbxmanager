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

## Quick Start

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

```matlab
>> tbxmanager search toolbox
Found 3 package(s):

Name    Latest       Description
---------------------------------------------------------------
brcm    v0.96(Beta)  The Building Resistance-Capacitance ...
mpt     3.2.1        Multi-Parametric Toolbox 3.0
mptdoc  3.0.4        Multi-Parametric Toolbox documentation
```

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

**All commands have shorthands:** `tbx inst mpt` works like `tbxmanager install mpt`. Any unique prefix works.

[Get Started :material-arrow-right:](getting-started.md){ .md-button .md-button--primary }
