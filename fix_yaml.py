#!/usr/bin/env python3
import re
import yaml

with open('package/crossplane.yaml', 'r') as f:
    content = f.read()

# Parse the YAML to work with the structure properly
data = yaml.safe_load(content)

# Clean the readme annotation by removing YAML code blocks
if 'metadata' in data and 'annotations' in data['metadata']:
    readme = data['metadata']['annotations'].get('meta.crossplane.io/readme', '')
    if readme:
        # Remove YAML code blocks from the readme annotation
        pattern = r'```yaml.*?```'
        replacement = '```yaml\n# YAML examples removed during package build\n# See repository examples/ directory for complete examples\n```'
        cleaned_readme = re.sub(pattern, replacement, readme, flags=re.DOTALL)
        data['metadata']['annotations']['meta.crossplane.io/readme'] = cleaned_readme

# Write back the cleaned YAML
with open('package/crossplane.yaml', 'w') as f:
    yaml.dump(data, f, default_flow_style=False, width=1000, allow_unicode=True)

print('Successfully cleaned crossplane.yaml')
