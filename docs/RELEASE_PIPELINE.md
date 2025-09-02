# Automatic Release Pipeline

This document describes the automated release pipeline for the Crossplane Nutanix Provider.

## Overview

When changes are merged to the `main` branch the pipeline can:

- Run tests and build packages
- Compute and push a semantic version tag (when appropriate)
- Publish the package to Upbound and create a GitHub release

## Versioning rules

The `auto-tag` job computes the next version using commit messages:

- Major: commit contains `BREAKING` or `major:`
- Minor: commit contains `feat:` or `minor:`
- Patch: default for other commits

The job will skip tagging when the last commit was produced by the pipeline (to avoid loops) or when there are no commits since the last tag.

## Manual controls

You can manually inspect or bump versions using the provided tooling.

### Make targets

```bash
# Preview the next version (no changes)
make version-dry-run

# Create patch version
make version-patch

# Create minor version
make version-minor

# Create major version
make version-major
```

### Script usage

```bash
# Preview next patch version
./scripts/version.sh patch --dry-run

# Create and tag a new minor version
./scripts/version.sh minor

# Create and tag a new major version
./scripts/version.sh major
```

### Manual tag

```bash
git tag -a v1.0.47 -m "Manual release v1.0.47"
git push origin v1.0.47
```

## Pipeline overview

The pipeline runs tests, builds the provider, constructs a Crossplane package (`.xpkg`), and then publishes it. Important jobs:

- `test` — runs unit tests
- `auto-tag` — calculates and pushes the tag (outputs `version`)
- `package` — builds the provider and the `.xpkg`
- `publish` — logs into Upbound and pushes the `.xpkg`
- `create-release` — creates a GitHub release and uploads the `.xpkg`

## Example flow

1. Commit with an appropriate message
2. Push to `main`
3. `test` runs, then `auto-tag` computes the version and may create a tag
4. `package` builds the `.xpkg` and uploads it as an artifact
5. `publish` logs into Upbound and pushes the `.xpkg`
6. `create-release` makes a GitHub release and uploads the `.xpkg`

## Monitoring

- GitHub Actions: [Actions](https://github.com/mgeorge67701/crossplane-nutanix/actions)
- GitHub Releases: [Releases](https://github.com/mgeorge67701/crossplane-nutanix/releases)
- Upbound Marketplace: [Provider page](https://marketplace.upbound.io/providers/mgeorge67701/provider-nutanix)

## Troubleshooting

### Auto-tag not created

- Ensure the commit message matches the bump rules
- Confirm `test` and `package` succeeded

### Publish failures

- Verify `UPBOUND_ACCESS_ID` and `UPBOUND_TOKEN` repository secrets exist and are correct
- Confirm the `.xpkg` artifact was created and downloaded by the `publish` job

### Manual recovery

If automation fails you can manually create and push a tag; the release pipeline will pick it up.

```bash
git tag -a v1.0.48 -m "Manual recovery release"
git push origin v1.0.48
```

## Manual Package Building

If you need to manually build and push packages outside of the CI pipeline, follow these steps:

### Install the correct Crossplane CLI

```bash
# Download the latest Crossplane CLI (supports xpkg commands)
os=$(uname | tr '[:upper:]' '[:lower:]')
arch=$(uname -m | sed 's/x86_64/amd64/')
[ "$arch" = "arm64" ] && arch="arm64"
curl -sLO "https://releases.crossplane.io/stable/v1.13.2/bin/${os}_${arch}/crossplane"
chmod +x crossplane
mkdir -p ~/bin
mv crossplane ~/bin/
export PATH=~/bin:$PATH
```

Add to your shell profile for persistence:

```bash
echo 'export PATH=~/bin:$PATH' >> ~/.zshrc  # or ~/.bashrc
```

### Build package manually

```bash
# Build the package
crossplane xpkg build --package-root=package -o provider-nutanix.xpkg
```

### Push package to registry

```bash
# Login to Upbound registry via Docker
export UPBOUND_ACCESS_ID="your-access-id"
export UPBOUND_TOKEN="your-token"
echo "$UPBOUND_TOKEN" | docker login xpkg.upbound.io -u "$UPBOUND_ACCESS_ID" --password-stdin

# Push the package with version tag
latest_tag=$(git describe --tags --abbrev=0)
crossplane xpkg push -f provider-nutanix.xpkg xpkg.upbound.io/mgeorge67701/provider-nutanix:$latest_tag

# Also push as latest
crossplane xpkg push -f provider-nutanix.xpkg xpkg.upbound.io/mgeorge67701/provider-nutanix:latest
```

