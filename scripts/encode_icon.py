import base64
import os

# The script is in the 'scripts' directory. The project root is one level up.
script_dir = os.path.dirname(os.path.abspath(__file__))
project_root = os.path.dirname(script_dir)

svg_path = os.path.join(project_root, "package", "icon.svg")

try:
    with open(svg_path, "rb") as f:
        svg_data = f.read()
    
    encoded_string = base64.b64encode(svg_data).decode("utf-8")
    
    print(encoded_string)

except FileNotFoundError:
    print(f"Error: The file {svg_path} was not found.")
    exit(1)
except Exception as e:
    print(f"An error occurred: {e}")
    exit(1)
