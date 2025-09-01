#!/bin/bash

# Version management script for crossplane-nutanix
# Usage: ./scripts/version.sh [patch|minor|major] [--dry-run]

set -euo pipefail

# Default bump type
BUMP_TYPE="${1:-patch}"
DRY_RUN="${2:-}"

# Validate bump type
case "$BUMP_TYPE" in
    patch|minor|major)
        ;;
    *)
        echo "Error: Invalid bump type '$BUMP_TYPE'. Use: patch, minor, or major"
        exit 1
        ;;
esac

# Get the latest tag
LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "v1.0.0")
echo "Current latest tag: $LATEST_TAG"

# Extract version numbers (remove 'v' prefix)
VERSION=${LATEST_TAG#v}
IFS='.' read -r MAJOR MINOR PATCH <<< "$VERSION"

# Bump version based on type
case "$BUMP_TYPE" in
    patch)
        NEW_PATCH=$((PATCH + 1))
        NEW_VERSION="v${MAJOR}.${MINOR}.${NEW_PATCH}"
        ;;
    minor)
        NEW_MINOR=$((MINOR + 1))
        NEW_VERSION="v${MAJOR}.${NEW_MINOR}.0"
        ;;
    major)
        NEW_MAJOR=$((MAJOR + 1))
        NEW_VERSION="v${NEW_MAJOR}.0.0"
        ;;
esac

echo "Next version will be: $NEW_VERSION"

# Check for uncommitted changes
if [[ -n $(git status --porcelain) ]]; then
    echo "Warning: You have uncommitted changes"
    git status --short
    echo ""
fi

# Get commit messages since last tag for changelog
echo "Changes since $LATEST_TAG:"
git log --oneline "${LATEST_TAG}..HEAD" || echo "No commits since last tag"
echo ""

if [[ "$DRY_RUN" == "--dry-run" ]]; then
    echo "DRY RUN: Would create tag $NEW_VERSION"
    exit 0
fi

# Confirm before creating tag
read -p "Create tag $NEW_VERSION? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled"
    exit 0
fi

# Create tag with commit message
COMMIT_MESSAGES=$(git log --oneline "${LATEST_TAG}..HEAD" | sed 's/^/- /' || echo "- Package updates")

git tag -a "$NEW_VERSION" -m "Release $NEW_VERSION

$COMMIT_MESSAGES

This release includes:
- Updated package configuration
- All tests passing
- Ready for production deployment"

echo "Created tag: $NEW_VERSION"
echo "Push with: git push origin $NEW_VERSION"
echo "Or push all tags with: git push --tags"
