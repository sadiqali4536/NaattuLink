import codecs

fp = r'd:\trogon_media_projects\upgradepsc\lib\controller\exam_controller.dart'
with codecs.open(fp, 'r', encoding='utf-8') as f:
    content = f.read()

old = "startResponse['status'] == 1"
new = "(startResponse['status'] == 1 || startResponse['status'] == true)"
content = content.replace(old, new)

with codecs.open(fp, 'w', encoding='utf-8') as f:
    f.write(content)
print('Done, replacements:', content.count(new))
