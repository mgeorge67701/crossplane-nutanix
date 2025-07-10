#!/bin/bash
# Delete all but the latest 3 versions of the provider from Upbound Marketplace using the Upbound REST API
# Requires: jq installed
# Expects UPBOUND_TOKEN to be set in the environment (from GitHub Actions secret)

REPO="provider-nutanix"
ORG="mgeorge67701"
KEEP=3
UPBOUND_API="https://api.upbound.io/v1"

if [ -z "$UPBOUND_TOKEN" ]; then
  echo "UPBOUND_TOKEN is not set!"
  exit 1
fi

# DEBUG: Print the raw API response
RAW_JSON=$(curl -s -H "Authorization: Bearer $UPBOUND_TOKEN" \
  "$UPBOUND_API/orgs/$ORG/repos/$REPO/versions")
echo "Raw API response:" >&2
echo "$RAW_JSON" | jq . >&2

VERSIONS=$(echo "$RAW_JSON" | jq -r '.versions[].version')

TOTAL=$(echo "$VERSIONS" | wc -l | tr -d ' ')
DELETE_COUNT=$((TOTAL - KEEP))

if [ "$DELETE_COUNT" -le 0 ]; then
  echo "Nothing to delete. Only $TOTAL versions found."
  exit 0
fi

TO_DELETE=$(echo "$VERSIONS" | sort -V | head -n $DELETE_COUNT)

for v in $TO_DELETE; do
  echo "Deleting version: $v"
  curl -s -X DELETE -H "Authorization: Bearer $UPBOUND_TOKEN" \
    "$UPBOUND_API/orgs/$ORG/repos/$REPO/versions/$v" && echo "Deleted $v" || echo "Failed to delete $v, skipping."
  sleep 1
done

echo "Cleanup complete. Remaining versions:"
curl -s -H "Authorization: Bearer $UPBOUND_TOKEN" \
  "$UPBOUND_API/orgs/$ORG/repos/$REPO/versions" | jq -r '.versions[].version' | sort -V | tail -n $KEEP
