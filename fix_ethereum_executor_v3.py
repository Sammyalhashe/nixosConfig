import sys

file_path = '/home/salhashemi2/trading-bot-flake/ethereum_executor.py'
with open(file_path, 'r') as f:
    content = f.read()

# Fix return values in _approve_token
content = content.replace('return None  # Already approved', 'return True  # Already approved')
content = content.replace('return None # Already approved', 'return True # Already approved')

# The MAX approval cases
content = content.replace('return None', 'return True', 5) # Careful here

with open(file_path, 'w') as f:
    f.write(content)
