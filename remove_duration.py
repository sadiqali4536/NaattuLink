import codecs
import re

fp = r'd:\trogon_media_projects\upgradepsc\lib\view\dashboard\home\practice_intro_instruction.dart'
with codecs.open(fp, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace the Row of summary cards with a centered single summary card
content = re.sub(
    r'Row\(\s*children:\s*\[\s*Expanded\(\s*child:\s*_buildSummaryCard\(.*?\)\s*,\s*\)\s*,\s*const\s*SizedBox\(width:\s*12\),\s*Expanded\(\s*child:\s*_buildSummaryCard\(.*?context,\s*Icons\.format_list_bulleted.*?\]\s*,\s*\)',
    '''Center(
                    child: SizedBox(
                      width: 200,
                      child: _buildSummaryCard(
                        context,
                        Icons.format_list_bulleted,
                        const Color(0xFFF25A68),
                        const Color(0xFFFEF2F3),
                        "Questions",
                        "$questions Qns",
                      ),
                    ),
                  )''',
    content,
    flags=re.DOTALL
)

with codecs.open(fp, 'w', encoding='utf-8') as f:
    f.write(content)
print('Duration removed, questions centered.')
