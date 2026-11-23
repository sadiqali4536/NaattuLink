import sys

with open(sys.argv[1], 'r', encoding='utf-8') as f:
    content = f.read()

target = 'var url = Uri.parse("${api}exam/access?exam_id=$examId");'
replacement = 'var url = Uri.parse("${api}exam/access?exam_id=$examId&auth_token=$authToken");'

if target in content:
    content = content.replace(target, replacement)
    with open(sys.argv[1], 'w', encoding='utf-8') as f:
        f.write(content)
    print("Updated main_apis.dart")
else:
    print("Target not found")
