import codecs
import re

file_path = r'd:\trogon_media_projects\upgradepsc\lib\view\dashboard\home\practice_intro_instruction.dart'
with codecs.open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

questions_logic_old = '''String questions = controller.practiceContent?['questions_count']?.toString() ?? '0';
        if (questions == '0' || questions == 'null') {
          questions = controller.practiceContent?['questions']?.length?.toString() ?? '0';
        }'''
questions_logic_new = '''String questions = (controller.selectedPracticeQuestionCount ??
            (controller.practiceData != null && controller.practiceData!['questions'] != null
                ? controller.practiceData!['questions'].length
                : 0)).toString();'''
content = content.replace(questions_logic_old, questions_logic_new)

summary_cards_old = '''// Summary Cards
                        Row(
                          children: [
                            Expanded(
                              child: _buildSummaryCard(
                                context,
                                Icons.access_time,
                                const Color(0xFF4285F4),
                                const Color(0xFFEEF3FC),
                                "Duration",
                                duration.toLowerCase().contains('min') ||
                                        duration.toLowerCase().contains('hr') ||
                                        duration.contains(':')
                                    ? duration
                                    : "$duration Min",
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildSummaryCard(
                                context,
                                Icons.format_list_bulleted,
                                const Color(0xFFF25A68),
                                const Color(0xFFFEF2F3),
                                "Questions",
                                "$questions Qns",
                              ),
                            ),
                          ],
                        ),'''
summary_cards_new = '''// Summary Cards
                        _buildSummaryCard(
                          context,
                          Icons.format_list_bulleted,
                          const Color(0xFFF25A68),
                          const Color(0xFFFEF2F3),
                          "Questions",
                          "$questions Qns",
                        ),'''
content = content.replace(summary_cards_old, summary_cards_new)

with codecs.open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print('Fixed questions and removed duration')
