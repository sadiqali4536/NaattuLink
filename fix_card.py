import codecs

fp = r'd:\trogon_media_projects\upgradepsc\lib\view\dashboard\home\practice_intro_instruction.dart'
with codecs.open(fp, 'r', encoding='utf-8') as f:
    content = f.read()

old = '''                          // Summary Cards
                          _buildSummaryCard(
                            context,
                            Icons.format_list_bulleted,
                            const Color(0xFFF25A68),
                            const Color(0xFFFEF2F3),
                            "Questions",
                            "$questions Qns",
                          ),'''

new = '''                          // Summary Cards
                          Center(
                            child: SizedBox(
                              width: 160,
                              child: _buildSummaryCard(
                                context,
                                Icons.format_list_bulleted,
                                const Color(0xFFF25A68),
                                const Color(0xFFFEF2F3),
                                "Questions",
                                "$questions Qns",
                              ),
                            ),
                          ),'''

content = content.replace(old, new)
with codecs.open(fp, 'w', encoding='utf-8') as f:
    f.write(content)
print('Done')
