# Quick Start for Package Authors

Publish your MATLAB toolbox to [tbxmanager](https://marekwadinger.github.io/tbxmanager) in minutes.

## The Fast Way: `tbxmanager publish`

### 1. Add `tbxmanager.json`

Run `tbxmanager init` in your project directory:

```matlab
>> cd my-toolbox
>> tbxmanager init
Created tbxmanager.json
```

Edit the generated file to match your package:

```json
{
  "name": "my-toolbox",
  "version": "1.0.0",
  "description": "A useful MATLAB toolbox",
  "authors": ["YourGitHubUsername"],
  "license": "MIT",
  "homepage": "https://github.com/you/my-toolbox",
  "matlab": ">=R2022a",
  "platforms": {
    "all": {}
  },
  "dependencies": {}
}
```

Set `platforms` to `"all"` for pure MATLAB packages. If you distribute compiled MEX files, use platform-specific keys (`win64`, `maci64`, `maca64`, `glnxa64`) instead.

!!! tip
    You can also create `tbxmanager.json` by hand if you don't have tbxmanager installed yet.

### 2. Publish

```matlab
>> tbxmanager publish
```

That's it. This single command:

- Builds the archive (respecting your `publish.exclude` patterns)
- Creates a GitHub release and uploads the archive
- Computes the SHA256 hash
- Submits a PR to the registry

Once a maintainer merges the PR, your package is live:

```matlab
>> tbxmanager install my-toolbox
```

!!! note "GitHub tokens are only for publishing"
    You do **not** need a GitHub token to install or use packages — tokens are only required for publishing. A classic Personal Access Token with `public_repo` scope is prompted on first use and saved to `~/.tbxmanager/config.json`. Create one at [github.com/settings/tokens](https://github.com/settings/tokens).

### Updating Your Package

1. Bump `version` in `tbxmanager.json`
2. Run `tbxmanager publish` again

New versions are added alongside existing ones. Users can install specific versions with `tbxmanager install my-toolbox@>=1.1`.

### Customize What Gets Packaged

Add a `publish` section to `tbxmanager.json`:

```json
{
  "publish": {
    "exclude": [".git", ".github", "tests", "docs", "benchmarks"]
  }
}
```

---

## Manual Steps (Without `tbxmanager publish`)

If you prefer to handle each step yourself, or don't have tbxmanager installed:

### 1. Create a GitHub Release with an Archive

1. Tag your version and push:

    ```bash
    git tag v1.0.0
    git push --tags
    ```

2. Build a zip of your package sources (excluding dev files):

    ```bash
    zip -r my-toolbox-all.zip . -x '.git/*' -x '.github/*' -x 'tests/*' -x 'docs/*'
    ```

    See [Building Archives](creating-packages.md#building-archives) for platform-specific packages.

3. Go to your repo on GitHub, click **Releases** > **Create a new release**
4. Select the tag, add a title, and **upload your zip** as a release asset
5. Click **Publish release**

!!! warning
    You must attach an archive file — the registry bot does not use GitHub's auto-generated source downloads.

### 2. Submit via Issue Form

1. Go to [tbxmanager-registry > Issues > New Issue](https://github.com/MarekWadinger/tbxmanager-registry/issues)
2. Click **"Submit Package"**
3. Fill in your **Repository URL** and **Release tag**
4. Click **Submit new issue**

A bot will automatically fetch your `tbxmanager.json`, download the archive, compute SHA256, and create a PR.

### 3. Or Submit Manually via PR

See [Creating Packages — Manual Submission](creating-packages.md#advanced-manual-submission) for the full manual process (fork, create `package.json`, open PR).

## MEX Packages (Platform-Specific)

If your package includes compiled MEX files, create separate archives per platform:

- `my-toolbox-win64.zip`
- `my-toolbox-maci64.zip`
- `my-toolbox-maca64.zip`
- `my-toolbox-glnxa64.zip`

Attach all of them to your GitHub Release and select the appropriate platform in the submission form.

## Next Steps

- [Case Study](casestudy.md) — real-world example with RLS_identification
- [Full metadata reference](creating-packages.md) — all `tbxmanager.json` fields
- [Commands reference](commands.md) — all tbxmanager CLI commands
