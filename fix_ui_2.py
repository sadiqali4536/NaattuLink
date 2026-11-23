import codecs
import re

file_path = r'd:\trogon_media_projects\upgradepsc\lib\view\dashboard\home\practice_intro_instruction.dart'
with codecs.open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace questions logic
content = re.sub(
    r'String questions =[\s\S]*?if \(questions == \'0\' \|\| questions == \'null\'\) \{[\s\S]*?\}',
    '''String questions = (controller.selectedPracticeQuestionCount ??
        (controller.practiceData != null && controller.practiceData!['questions'] != null
            ? controller.practiceData!['questions'].length
            : 0)).toString();''',
    content
)

# Remove the summary cards row and replace with just one card
content = re.sub(
    r'Row\(\s*children: \[\s*Expanded\([\s\S]*?\"Duration\"[\s\S]*?Expanded\([\s\S]*?\"Questions\"[\s\S]*?\]\s*,\s*\)',
    '''_buildSummaryCard(
        context,
        Icons.format_list_bulleted,
        const Color(0xFFF25A68),
        const Color(0xFFFEF2F3),
        "Questions",
        "$questions Qns",
    )''',
    content
)

with codecs.open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print('Done')
