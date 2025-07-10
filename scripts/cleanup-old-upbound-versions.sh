#!/bin/bash
# Delete all but the latest 3 versions of the provider from Upbound Marketplace
# Requires: up CLI, logged in, and jq installed

REPO="mgeorge67701/provider-nutanix"
KEEP=3

# List all versions, sort semver, and keep only the latest $KEEP
VERSIONS=$(up xpkg list xpkg.upbound.io/$REPO | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' | sort -V)
TOTAL=$(echo "$VERSIONS" | wc -l | tr -d ' ')
DELETE_COUNT=$((TOTAL - KEEP))

if [ "$DELETE_COUNT" -le 0 ]; then
  echo "Nothing to delete. Only $TOTAL versions found."
  exit 0
fi

# Get the versions to delete (all but the latest $KEEP)
TO_DELETE=$(echo "$VERSIONS" | head -n $DELETE_COUNT)

for v in $TO_DELETE; do
  echo "Deleting version: $v"
  if up xpkg delete xpkg.upbound.io/$REPO:$v; then
    echo "Deleted $v"
  else
    echo "Failed to delete $v, skipping."
  fi
  sleep 1 # avoid rate limits
done

echo "Cleanup complete. Remaining versions:"
up xpkg list xpkg.upbound.io/$REPO | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' | sort -V | tail -n $KEEP
