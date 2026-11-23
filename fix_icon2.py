import codecs

fp = r'd:\trogon_media_projects\upgradepsc\lib\view\dashboard\exams\exams_new.dart'
with codecs.open(fp, 'r', encoding='utf-8') as f:
    content = f.read()

old = ("                        : Image.asset(\r\n"
       "                          'assets/icons/exam_icon.png',\r\n"
       "                          width: 35,\r\n"
       "                          height: 35,\r\n"
       "                          fit: BoxFit.cover,\r\n"
       "                        ),")

new = ("                        : Builder(builder: (context) {\r\n"
       "                          final iconUrl = exam['exam_icon']?.toString() ?? '';\r\n"
       "                          if (iconUrl.isNotEmpty) {\r\n"
       "                            return Image.network(\r\n"
       "                              iconUrl,\r\n"
       "                              width: 35,\r\n"
       "                              height: 35,\r\n"
       "                              fit: BoxFit.cover,\r\n"
       "                              errorBuilder: (_, __, ___) => Image.asset(\r\n"
       "                                'assets/icons/exam_icon.png',\r\n"
       "                                width: 35,\r\n"
       "                                height: 35,\r\n"
       "                                fit: BoxFit.cover,\r\n"
       "                              ),\r\n"
       "                            );\r\n"
       "                          }\r\n"
       "                          return Image.asset(\r\n"
       "                            'assets/icons/exam_icon.png',\r\n"
       "                            width: 35,\r\n"
       "                            height: 35,\r\n"
       "                            fit: BoxFit.cover,\r\n"
       "                          );\r\n"
       "                        }),")

count = content.count(old)
print('Found:', count)
content = content.replace(old, new)

with codecs.open(fp, 'w', encoding='utf-8') as f:
    f.write(content)
print('Done')
