import base64
import os

workspace_root = "/Users/mohan.george/Documents/github/crossplane-nutanix"
svg_path = os.path.join(workspace_root, "package/icon.svg")
yaml_path = os.path.join(workspace_root, "package/crossplane.yaml")

try:
    with open(svg_path, "rb") as f:
        svg_data = f.read()
    
    encoded_string = base64.b64encode(svg_data).decode("utf-8")
    
    print(f"Base64 encoded string: {encoded_string}")

except FileNotFoundError:
    print(f"Error: The file {svg_path} was not found.")
    exit(1)
except Exception as e:
    print(f"An error occurred: {e}")
    exit(1)
