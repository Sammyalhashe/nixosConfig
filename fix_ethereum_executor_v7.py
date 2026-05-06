import sys

file_path = '/home/salhashemi2/trading-bot-flake/ethereum_executor.py'
with open(file_path, 'r') as f:
    content = f.read()

if 'import time' not in content[:500]:
    content = 'import logging\nimport time\nimport os\n' + content.replace('import logging\nimport os\n', '')

with open(file_path, 'w') as f:
    f.write(content)
print("Restored global import time")
