import codecs

content = """import 'package:flutter/material.dart';
import 'package:upgradepsc/components/exam_content_style.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:get/get.dart';
import 'package:upgradepsc/components/constants.dart';
import 'package:upgradepsc/controller/exam_controller.dart';
import 'package:upgradepsc/view/dashboard/home/practice_exam.dart';

class practice_intro_instruction extends StatefulWidget {
  final String url;

  const practice_intro_instruction({super.key, required this.url});

  @override
  State<practice_intro_instruction> createState() =>
      _practice_intro_instructionState();
}

class _practice_intro_instructionState
    extends State<practice_intro_instruction> {
  final ExamController controller = Get.find<ExamController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetch_practice_exam_content(widget.url);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ExamController>(
      builder: (controller) {
        return Scaffold(
          backgroundColor: const Color(0xFFF7F8FA),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF7F8FA),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
              onPressed: () => Get.back(),
            ),
            title: const Text(
              'PRACTICE EXAM',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            centerTitle: true,
          ),
          body:
              controller.isPracticeContentLoading
                  ? Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  )
                  : _buildContent(context, controller),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, ExamController controller) {
    String instructionsHtml =
        "<ul>\\n    <li>+1 marks for each correct answer and negative -0.33 for each incorrect answer.</li>\\n    <li>You can skip questions if you do not want to attend.</li>\\n    <li>In last question you can finish practice after confirmation.</li>\\n    <li>You can navigate between questions using the question numbers at the top.</li>\\n    <li>Once you select an answer, the correct solution will be displayed immediately.</li>\\n</ul>";

    if (controller.practiceContent != null &&
        controller.practiceContent!['instructions'] != null) {
      instructionsHtml = controller.practiceContent!['instructions'].toString();
    }

    int totalQuestions =
        controller.selectedPracticeQuestionCount ??
        (controller.practiceData != null &&
                controller.practiceData!['questions'] != null
            ? controller.practiceData!['questions'].length
            : 0);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5F0FF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFECCC),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.question_mark,
                            color: Color(0xFFFFA500),
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Questions',
                              style: TextStyle(
                                color: Color(0xFF718096),
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '$totalQuestions Qus',
                              style: const TextStyle(
                                color: Color(0xFF2D3748),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Instructions',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 16),
                HtmlWidget(
                  instructionsHtml,
                  textStyle: const TextStyle(
                    fontSize: 16.0,
                    color: Color(0xFF4A5568),
                    height: 1.5,
                  ),
                  customStylesBuilder: (e) => e.localName == 'li'
                      ? const {'margin': '0 0 12px 0'}
                      : ExamContentStyle.tableCss(e),
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: const Color(0xFFF7F8FA)),
          child: SafeArea(
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Get.off<Widget>(
                    () => PracticeExam(examId: widget.url, fetchData: false),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B1B3A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: const Text(
                  "Let's Start",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
"""

with codecs.open(r'd:\trogon_media_projects\upgradepsc\lib\view\dashboard\home\practice_intro_instruction.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print('Reverted to original')
