import re

def find_strings(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    patterns = [
        r"Text\(\s*'([^']+)'",
        r'Text\(\s*"([^"]+)"',
        r"labelText:\s*'([^']+)'",
        r'labelText:\s*"([^"]+)"',
        r"hintText:\s*'([^']+)'",
        r'hintText:\s*"([^"]+)"',
    ]

    strings = set()
    for p in patterns:
        for match in re.findall(p, content):
            strings.add(match)
            
    print(f"Strings found in {file_path}:")
    for s in sorted(list(strings)):
        print(s)

find_strings('lib/screens/wallet_dashboard_screen.dart')
