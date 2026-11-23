import codecs
import re

file_path = r'd:\trogon_media_projects\upgradepsc\lib\view\dashboard\home\practice_intro_instruction.dart'
with codecs.open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('title: const Text(', 'title: Text(')
# Regex to remove const before Text(...)
content = re.sub(r'const\s+Text\(', r'Text(', content)

with codecs.open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print('Fixed const issue')
