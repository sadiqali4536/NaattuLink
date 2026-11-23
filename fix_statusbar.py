import codecs

fp = r'd:\trogon_media_projects\upgradepsc\lib\view\dashboard\exams\practice_start_page.dart'
with codecs.open(fp, 'r', encoding='utf-8') as f:
    content = f.read()

old = (
    "    SystemChrome.setEnabledSystemUIMode(\r\n"
    "      SystemUiMode.manual,\r\n"
    "      overlays: SystemUiOverlay.values,\r\n"
    "    );\r\n"
    "    SystemChrome.setSystemUIOverlayStyle(\r\n"
    "      const SystemUiOverlayStyle(\r\n"
    "        statusBarColor: Colors.transparent,\r\n"
    "        statusBarIconBrightness: Brightness.dark,\r\n"
    "        statusBarBrightness: Brightness.light,\r\n"
    "      ),\r\n"
    "    );"
)

new = (
    "    SystemChrome.setEnabledSystemUIMode(\r\n"
    "      SystemUiMode.edgeToEdge,\r\n"
    "    );\r\n"
    "    SystemChrome.setSystemUIOverlayStyle(\r\n"
    "      const SystemUiOverlayStyle(\r\n"
    "        statusBarColor: Colors.transparent,\r\n"
    "        statusBarIconBrightness: Brightness.dark,\r\n"
    "        statusBarBrightness: Brightness.light,\r\n"
    "        systemNavigationBarColor: Colors.transparent,\r\n"
    "      ),\r\n"
    "    );"
)

count = content.count(old)
print('Found:', count)
content = content.replace(old, new)

with codecs.open(fp, 'w', encoding='utf-8') as f:
    f.write(content)
print('Done')
