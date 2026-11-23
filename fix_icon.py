import codecs

fp = r'd:\trogon_media_projects\upgradepsc\lib\view\dashboard\exams\exams_new.dart'
with codecs.open(fp, 'r', encoding='utf-8') as f:
    content = f.read()

old = '''                child:
                    _isLocked
                        ? Icon(
                          Icons.lock,
                          color: Colors.grey.shade400,
                          size: 30,
                        )
                        : Image.asset(
                          'assets/icons/exam_icon.png',
                          width: 35,
                          height: 35,
                          fit: BoxFit.cover,
                        ),'''

new = '''                child:
                    _isLocked
                        ? Icon(
                          Icons.lock,
                          color: Colors.grey.shade400,
                          size: 30,
                        )
                        : Builder(builder: (context) {
                          final iconUrl = exam['exam_icon']?.toString() ?? '';
                          if (iconUrl.isNotEmpty) {
                            return Image.network(
                              iconUrl,
                              width: 35,
                              height: 35,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Image.asset(
                                'assets/icons/exam_icon.png',
                                width: 35,
                                height: 35,
                                fit: BoxFit.cover,
                              ),
                            );
                          }
                          return Image.asset(
                            'assets/icons/exam_icon.png',
                            width: 35,
                            height: 35,
                            fit: BoxFit.cover,
                          );
                        }),'''

count = content.count(old)
print('Found:', count)
content = content.replace(old, new)

with codecs.open(fp, 'w', encoding='utf-8') as f:
    f.write(content)
print('Done')
