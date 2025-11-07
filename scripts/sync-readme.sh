#!/bin/bash
# Robustly sync README.md into package.yaml meta.crossplane.io/readme annotation

README_PATH="README.md"
PACKAGE_YAML="package/package.yaml"

if [ ! -f "$README_PATH" ]; then
  echo "README.md not found!"
  exit 1
fi
if [ ! -f "$PACKAGE_YAML" ]; then
  echo "package/package.yaml not found!"
  exit 1
fi

# Prepare README as YAML block literal (6 spaces indent)
INDENT="      "
ESCAPED_README=$(sed "s/^/${INDENT}/" "$README_PATH")

# Check if the annotation exists
if grep -q '^\s*meta\.crossplane\.io/readme:' "$PACKAGE_YAML"; then
  # Replace the entire readme annotation block, regardless of previous content
  awk -v readme="$ESCAPED_README" '
    BEGIN {in_readme=0}
    /^\s*meta\.crossplane\.io\/readme:/ {
      print "    meta.crossplane.io/readme: |"
      print readme
      in_readme=1
      next
    }
    in_readme && (/^\s*\S/ && !/^\s{6,}/) {in_readme=0}
    !in_readme {print}
    in_readme && /^\s{6,}/ {next}
  ' "$PACKAGE_YAML" > "$PACKAGE_YAML.tmp" && mv "$PACKAGE_YAML.tmp" "$PACKAGE_YAML"
else
  # Insert the annotation under the annotations: key
  awk -v readme="$ESCAPED_README" '
    /^\s*annotations:/ {
      print
      print "    meta.crossplane.io/readme: |"
      print readme
      next
    }
    {print}
  ' "$PACKAGE_YAML" > "$PACKAGE_YAML.tmp" && mv "$PACKAGE_YAML.tmp" "$PACKAGE_YAML"
fi

echo "README.md content fully synced to package.yaml annotation."
