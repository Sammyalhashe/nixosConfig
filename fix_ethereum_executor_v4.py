import sys

file_path = '/home/salhashemi2/trading-bot-flake/ethereum_executor.py'
with open(file_path, 'r') as f:
    lines = f.readlines()

new_lines = []
in_approve = False
for line in lines:
    if 'def _approve_token(self, token_address, amount):' in line:
        in_approve = True
    if in_approve:
        if 'return None' in line and not 'logging' in line:
            # Replace return None with return True unless it's the final error return
            # We'll be more specific:
            if 'if self.trading_mode' in lines[new_lines.__len__()-1 if new_lines else 0]: # Not this one
                pass
            elif 'if cached_allowance == 2**256 - 1:' in lines[new_lines.__len__()-1]:
                line = line.replace('return None', 'return True')
            elif 'if cached_allowance >= amount:' in lines[new_lines.__len__()-1]:
                line = line.replace('return None', 'return True')
            elif 'if allowance == 2**256 - 1:' in lines[new_lines.__len__()-1]:
                line = line.replace('return None', 'return True')
            elif 'if allowance >= amount:' in lines[new_lines.__len__()-1]:
                line = line.replace('return None', 'return True')
    
    if 'def get_quote' in line:
        in_approve = False
    new_lines.append(line)

with open(file_path, 'w') as f:
    f.writelines(new_lines)
print("Updated _approve_token return values")
