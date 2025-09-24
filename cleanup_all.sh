#!/bin/bash

set -e

REPO_OWNER="mgeorge67701"
REPO_NAME="crossplane-nutanix"

echo "🧹 Starting cleanup of all releases, packages, and tags for ${REPO_OWNER}/${REPO_NAME}..."

# Check if gh CLI is available
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) is not installed. Please install it first."
    exit 1
fi

# Check if user is authenticated
if ! gh auth status &> /dev/null; then
    echo "❌ Not authenticated with GitHub CLI. Please run 'gh auth login' first."
    exit 1
fi

echo "✅ GitHub CLI authenticated and ready"

# Check token permissions
echo "🔍 Checking GitHub token permissions..."
token_info=$(gh api /user 2>/dev/null || echo "")
if [ -n "$token_info" ]; then
    echo "✅ Token has basic access"
    echo "📝 Note: If package deletion fails, you may need to re-authenticate with additional scopes:"
    echo "   gh auth login --scopes 'repo,read:packages,write:packages,delete:packages'"
else
    echo "⚠️  Token may have limited permissions"
fi

# Delete all releases
echo "🗑️  Deleting all GitHub releases..."
releases=$(gh release list --repo "${REPO_OWNER}/${REPO_NAME}" --json tagName --jq '.[].tagName' 2>/dev/null || true)
if [ -n "$releases" ]; then
    echo "Found releases: $(echo "$releases" | tr '\n' ' ')"
    for release in $releases; do
        echo "  Deleting release: $release"
        gh release delete "$release" --repo "${REPO_OWNER}/${REPO_NAME}" --yes || echo "    Failed to delete release $release"
    done
    echo "✅ All releases deleted"
else
    echo "  No releases found"
fi

# Delete all packages
echo "🗑️  Deleting all GitHub packages..."

# First try to get packages for the user
packages=$(gh api "/users/${REPO_OWNER}/packages?package_type=container" --jq '.[].name' 2>/dev/null || echo "")

# If that fails, try organization packages (in case it's an org repo)
if [ -z "$packages" ] || [[ "$packages" == *"message"* ]]; then
    echo "  Trying organization packages..."
    packages=$(gh api "/orgs/${REPO_OWNER}/packages?package_type=container" --jq '.[].name' 2>/dev/null || echo "")
fi

# Also try to get packages by searching for known package names
echo "  Checking for specific package names..."
known_packages=("provider-nutanix" "crossplane-nutanix" "nutanix-provider")

for pkg_name in "${known_packages[@]}"; do
    echo "    Checking package: $pkg_name"
    
    # Try user packages
    user_response=$(gh api "/users/${REPO_OWNER}/packages/container/${pkg_name}/versions" 2>/dev/null || echo '{"error": true}')
    if [[ "$user_response" != *"message"* ]] && [[ "$user_response" != *"error"* ]]; then
        user_versions=$(echo "$user_response" | jq -r '.[].id' 2>/dev/null | grep -E '^[0-9]+$' || echo "")
        if [ -n "$user_versions" ]; then
            echo "    Found versions for user package $pkg_name: $(echo "$user_versions" | tr '\n' ' ')"
            for version_id in $user_versions; do
                if [[ "$version_id" =~ ^[0-9]+$ ]]; then
                    echo "      Deleting user package version ID: $version_id"
                    gh api --method DELETE "/users/${REPO_OWNER}/packages/container/${pkg_name}/versions/${version_id}" || echo "        Failed to delete version $version_id"
                fi
            done
        fi
    else
        echo "    No access to user package $pkg_name ($(echo "$user_response" | jq -r '.message // "unknown error"' 2>/dev/null || echo "API error"))"
    fi
    
    # Try org packages
    org_response=$(gh api "/orgs/${REPO_OWNER}/packages/container/${pkg_name}/versions" 2>/dev/null || echo '{"error": true}')
    if [[ "$org_response" != *"message"* ]] && [[ "$org_response" != *"error"* ]]; then
        org_versions=$(echo "$org_response" | jq -r '.[].id' 2>/dev/null | grep -E '^[0-9]+$' || echo "")
        if [ -n "$org_versions" ]; then
            echo "    Found versions for org package $pkg_name: $(echo "$org_versions" | tr '\n' ' ')"
            for version_id in $org_versions; do
                if [[ "$version_id" =~ ^[0-9]+$ ]]; then
                    echo "      Deleting org package version ID: $version_id"
                    gh api --method DELETE "/orgs/${REPO_OWNER}/packages/container/${pkg_name}/versions/${version_id}" || echo "        Failed to delete version $version_id"
                fi
            done
        fi
    else
        echo "    No access to org package $pkg_name ($(echo "$org_response" | jq -r '.message // "unknown error"' 2>/dev/null || echo "API error"))"
    fi
done

# Try to delete packages found via listing
if [ -n "$packages" ] && [[ "$packages" != *"message"* ]]; then
    echo "  Found packages via listing: $(echo "$packages" | tr '\n' ' ')"
    for package in $packages; do
        if [[ "$package" == *"nutanix"* ]] || [[ "$package" == *"provider"* ]] || [[ "$package" == *"crossplane"* ]]; then
            echo "    Processing package: $package"
            
            # Try user endpoint
            user_response=$(gh api "/users/${REPO_OWNER}/packages/container/${package}/versions" 2>/dev/null || echo '{"error": true}')
            if [[ "$user_response" != *"message"* ]] && [[ "$user_response" != *"error"* ]]; then
                user_versions=$(echo "$user_response" | jq -r '.[].id' 2>/dev/null | grep -E '^[0-9]+$' || echo "")
                if [ -n "$user_versions" ]; then
                    for version_id in $user_versions; do
                        if [[ "$version_id" =~ ^[0-9]+$ ]]; then
                            echo "      Deleting user package version ID: $version_id"
                            gh api --method DELETE "/users/${REPO_OWNER}/packages/container/${package}/versions/${version_id}" || echo "        Failed to delete version $version_id"
                        fi
                    done
                fi
            fi
            
            # Try org endpoint
            org_response=$(gh api "/orgs/${REPO_OWNER}/packages/container/${package}/versions" 2>/dev/null || echo '{"error": true}')
            if [[ "$org_response" != *"message"* ]] && [[ "$org_response" != *"error"* ]]; then
                org_versions=$(echo "$org_response" | jq -r '.[].id' 2>/dev/null | grep -E '^[0-9]+$' || echo "")
                if [ -n "$org_versions" ]; then
                    for version_id in $org_versions; do
                        if [[ "$version_id" =~ ^[0-9]+$ ]]; then
                            echo "      Deleting org package version ID: $version_id"
                            gh api --method DELETE "/orgs/${REPO_OWNER}/packages/container/${package}/versions/${version_id}" || echo "        Failed to delete version $version_id"
                        fi
                    done
                fi
            fi
        fi
    done
else
    echo "  No packages found via listing"
fi

# Additional cleanup - try to find and delete any remaining versions
echo "  Performing additional version cleanup..."

# Try to find packages using the repository-specific approach
echo "    Checking repository packages..."
repo_response=$(gh api "/repos/${REPO_OWNER}/${REPO_NAME}/packages" 2>/dev/null || echo '{"error": true}')
if [[ "$repo_response" != *"message"* ]] && [[ "$repo_response" != *"error"* ]]; then
    repo_packages=$(echo "$repo_response" | jq -r '.[].name' 2>/dev/null || echo "")
    if [ -n "$repo_packages" ]; then
        echo "    Found repo packages: $(echo "$repo_packages" | tr '\n' ' ')"
        for package in $repo_packages; do
            echo "      Processing repo package: $package"
            versions_response=$(gh api "/repos/${REPO_OWNER}/${REPO_NAME}/packages/container/${package}/versions" 2>/dev/null || echo '{"error": true}')
            if [[ "$versions_response" != *"message"* ]] && [[ "$versions_response" != *"error"* ]]; then
                versions=$(echo "$versions_response" | jq -r '.[].id' 2>/dev/null | grep -E '^[0-9]+$' || echo "")
                if [ -n "$versions" ]; then
                    for version_id in $versions; do
                        if [[ "$version_id" =~ ^[0-9]+$ ]]; then
                            echo "        Deleting repo package version ID: $version_id"
                            gh api --method DELETE "/repos/${REPO_OWNER}/${REPO_NAME}/packages/container/${package}/versions/${version_id}" || echo "          Failed to delete version $version_id"
                        fi
                    done
                fi
            fi
        done
    fi
fi

# Try GHCR cleanup using Docker registry API approach
echo "    Attempting GHCR registry cleanup..."
repo_owner_lower=$(echo "${REPO_OWNER}" | tr '[:upper:]' '[:lower:]')
registry_packages=("ghcr.io/${repo_owner_lower}/provider-nutanix" "ghcr.io/${repo_owner_lower}/crossplane-nutanix")

for registry_pkg in "${registry_packages[@]}"; do
    echo "      Checking registry package: $registry_pkg"
    pkg_name=$(basename "$registry_pkg")
    
    # Try to get package versions
    pkg_response=$(gh api "/users/${REPO_OWNER}/packages/container/${pkg_name}/versions" 2>/dev/null || echo '{"error": true}')
    if [[ "$pkg_response" != *"message"* ]] && [[ "$pkg_response" != *"error"* ]]; then
        # Get version IDs for tagged versions
        version_ids=$(echo "$pkg_response" | jq -r '.[] | select(.metadata.container.tags != null and .metadata.container.tags != []) | .id' 2>/dev/null | grep -E '^[0-9]+$' || echo "")
        if [ -n "$version_ids" ]; then
            echo "        Found tagged versions for $pkg_name: $(echo "$version_ids" | tr '\n' ' ')"
            for version_id in $version_ids; do
                if [[ "$version_id" =~ ^[0-9]+$ ]]; then
                    echo "          Deleting tagged version ID: $version_id"
                    gh api --method DELETE "/users/${REPO_OWNER}/packages/container/${pkg_name}/versions/${version_id}" || echo "            Failed to delete version $version_id"
                fi
            done
        fi
    fi
done

echo "✅ Package cleanup completed"

# Delete all local git tags
echo "🗑️  Deleting all local git tags..."
local_tags=$(git tag -l)
if [ -n "$local_tags" ]; then
    echo "Found local tags: $(echo "$local_tags" | tr '\n' ' ')"
    git tag -d $local_tags
    echo "✅ All local tags deleted"
else
    echo "  No local tags found"
fi

# Delete all remote git tags
echo "🗑️  Deleting all remote git tags..."
remote_tags=$(git ls-remote --tags origin | cut -f2 | sed 's/refs\/tags\///' | grep -v '\^{}$' || true)
if [ -n "$remote_tags" ]; then
    echo "Found remote tags: $(echo "$remote_tags" | tr '\n' ' ')"
    for tag in $remote_tags; do
        echo "  Deleting remote tag: $tag"
        git push origin ":refs/tags/$tag" || echo "    Failed to delete remote tag $tag"
    done
    echo "✅ All remote tags deleted"
else
    echo "  No remote tags found"
fi

# Final cleanup - try to delete any untagged versions
echo "    Cleaning up untagged package versions..."
for pkg_name in "provider-nutanix" "crossplane-nutanix" "nutanix-provider"; do
    echo "      Checking untagged versions for: $pkg_name"
    
    # Get untagged versions
    untagged_response=$(gh api "/users/${REPO_OWNER}/packages/container/${pkg_name}/versions" 2>/dev/null || echo '{"error": true}')
    if [[ "$untagged_response" != *"message"* ]] && [[ "$untagged_response" != *"error"* ]]; then
        untagged_versions=$(echo "$untagged_response" | jq -r '.[] | select(.metadata.container.tags == null or .metadata.container.tags == []) | .id' 2>/dev/null | grep -E '^[0-9]+$' || echo "")
        if [ -n "$untagged_versions" ]; then
            echo "        Found untagged versions: $(echo "$untagged_versions" | tr '\n' ' ')"
            for version_id in $untagged_versions; do
                if [[ "$version_id" =~ ^[0-9]+$ ]]; then
                    echo "          Deleting untagged version ID: $version_id"
                    gh api --method DELETE "/users/${REPO_OWNER}/packages/container/${pkg_name}/versions/${version_id}" || echo "            Failed to delete untagged version $version_id"
                fi
            done
        fi
    fi
done

echo "✅ Package cleanup completed"

# Clean up any local Docker images related to the project
echo "🗑️  Cleaning up local Docker images..."

# Clean up images by repository name patterns
docker_images=$(docker images --format "table {{.Repository}}:{{.Tag}}" | grep -E "(nutanix|provider|crossplane)" | grep -v "REPOSITORY" || true)
if [ -n "$docker_images" ]; then
    echo "Found Docker images:"
    echo "$docker_images"
    docker images --format "{{.Repository}}:{{.Tag}}" | grep -E "(nutanix|provider|crossplane)" | xargs -r docker rmi -f || echo "  Some images may have failed to delete"
fi

# Clean up any dangling/untagged images
echo "  Cleaning up dangling images..."
dangling_images=$(docker images -f "dangling=true" -q || true)
if [ -n "$dangling_images" ]; then
    echo "  Found dangling images, removing..."
    docker rmi $dangling_images || echo "  Some dangling images may have failed to delete"
fi

# Clean up any build cache
echo "  Cleaning up Docker build cache..."
docker builder prune -f || echo "  Build cache cleanup may have failed"

echo "✅ Docker images cleaned up"

echo "🎉 Cleanup completed! All releases, packages, and tags have been removed."
echo "📝 Note: This operation cannot be undone. Make sure this is what you wanted to do."