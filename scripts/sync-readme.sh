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

# Prepare the README as a YAML block literal (indented 6 spaces)
INDENT="      "
ESCAPED_README=$(sed "s/^/${INDENT}/" "$README_PATH")

# Use awk to replace the entire readme annotation block
awk -v readme="$ESCAPED_README" '
  BEGIN {in_readme=0}
  /^ {4}meta\.crossplane\.io\/readme:/ {
    print "    meta.crossplane.io/readme: |"
    print readme
    in_readme=1
    next
  }
  in_readme && /^ {4}[^ ]/ {in_readme=0}
  !in_readme {print}
' "$CROSSPLANE_YAML" > "$CROSSPLANE_YAML.tmp" && mv "$CROSSPLANE_YAML.tmp" "$CROSSPLANE_YAML"

echo "README.md content synced to crossplane.yaml annotation."
