#!/bin/bash
# Robustly sync README.md into crossplane.yaml meta.crossplane.io/readme annotation

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

# Prepare README as YAML block literal (6 spaces indent)
INDENT="      "
ESCAPED_README=$(sed "s/^/${INDENT}/" "$README_PATH")

# Replace the entire readme annotation block, regardless of previous content
awk -v readme="$ESCAPED_README" '
  BEGIN {in_readme=0}
  /^\s*meta\.crossplane\.io\/readme:/ {
    print "    meta.crossplane.io/readme: |"
    print readme
    in_readme=1
    next
  }
  in_readme && /^\s*[^ ]/ {in_readme=0}
  !in_readme {print}
' "$CROSSPLANE_YAML" > "$CROSSPLANE_YAML.tmp" && mv "$CROSSPLANE_YAML.tmp" "$CROSSPLANE_YAML"

echo "README.md content fully synced to crossplane.yaml annotation."
