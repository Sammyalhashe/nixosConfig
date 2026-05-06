import sys

file_path = '/home/salhashemi2/trading-bot-flake/ethereum_executor.py'
with open(file_path, 'r') as f:
    content = f.read()

# Remove internal imports of time and use global
content = content.replace('import time', '# import time') # This is lazy but effective for now
# Wait, I'll just remove them properly.
import re
content = re.sub(r'\s+import time', '', content)

with open(file_path, 'w') as f:
    f.write(content)
print("Removed redundant internal time imports")
