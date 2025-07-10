#!/bin/bash
# Sync README.md into crossplane.yaml meta.crossplane.io/readme annotation

README_PATH="README.md"
CROSSPLANE_YAML="package/crossplane.yaml"

if [ ! -f "$README_PATH" ]; then
  echo "README.md not found!"
  exit 1
fi
if [ ! -f "$CROSSPLANE_YAML" ]; then
  echo "package/crossplane.yaml not found!"
  exit 1
fi

# Escape the README for YAML block literal
ESCAPED_README=$(awk '{print "      "$0}' "$README_PATH")

# Replace the annotation in crossplane.yaml
awk -v r="\n$ESCAPED_README" '
  BEGIN {in_readme=0}
  /meta.crossplane.io\/readme:/ {print; in_readme=1; next}
  in_readme && /^\s*[^ ]/ {in_readme=0}
  !in_readme {print}
  in_readme && /^\s*[^ ]/ {print r; in_readme=0}
' "$CROSSPLANE_YAML" > "$CROSSPLANE_YAML.tmp" && mv "$CROSSPLANE_YAML.tmp" "$CROSSPLANE_YAML"

echo "README.md content synced to crossplane.yaml annotation."
