import codecs

dart_code = """import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:upgradepsc/components/exam_content_style.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:get/get.dart';
import 'package:upgradepsc/components/constants.dart';
import 'package:upgradepsc/components/responsive.dart';
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
  final ExamController examController = Get.find<ExamController>();

  static const Color _pageBg = Color(0xFFF7F8FA);
  static const Color _heading = Color(0xFF0F172A);
  static const Color _body = Color(0xFF475569);
  static const Color _muted = Color(0xFF8F9BB3);

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    );
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      examController.fetch_practice_exam_content(widget.url);
    });
  }

  @override
  Widget build(BuildContext context) {
    final double hPad = Responsive.isTablet(context) ? 24 : 16;

    return Scaffold(
      backgroundColor: _pageBg,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 12),
            child: GetBuilder<ExamController>(
              builder: (controller) {
                return ElevatedButton(
                  onPressed: controller.isPracticeContentLoading
                      ? null
                      : () {
                          Get.off<Widget>(
                            () => PracticeExam(
                              examId: widget.url,
                              fetchData: false,
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4C429D),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: Size.fromHeight(
                      Responsive.buttonHeight(context, mobile: 50),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    "Start Exam",
                    style: TextStyle(
                      fontFamily: font_semibold,
                      fontSize: Responsive.font(context, mobile: 16),
                      letterSpacing: 0.2,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: GetBuilder<ExamController>(
          builder: (controller) {
            if (controller.isPracticeContentLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            String title = controller.practiceContent?['title']?.toString() ?? 'Practice Exam';
            
            String duration = controller.practiceContent?['duration']?.toString() ?? '0';
            if (duration.isEmpty || duration == 'null') duration = '0';

            String questions = (controller.selectedPracticeQuestionCount ??
                    (controller.practiceData != null && controller.practiceData!['questions'] != null
                        ? controller.practiceData!['questions'].length
                        : 0))
                .toString();

            String instructionsHtml = "<ul>\\n    <li>+1 marks for each correct answer and negative -0.33 for each incorrect answer.</li>\\n    <li>You can skip questions if you do not want to attend.</li>\\n    <li>In last question you can finish practice after confirmation.</li>\\n    <li>You can navigate between questions using the question numbers at the top.</li>\\n    <li>Once you select an answer, the correct solution will be displayed immediately.</li>\\n</ul>";

            if (controller.practiceContent != null &&
                controller.practiceContent!['instructions'] != null) {
              instructionsHtml = controller.practiceContent!['instructions'].toString();
            }

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 18,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1E293B).withOpacity(0.05),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: Responsive.font(context, mobile: 17) * 1.35 * 6,
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _heading,
                            fontFamily: font_bold,
                            fontSize: Responsive.font(context, mobile: 17),
                            height: 1.35,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Summary Cards
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
                  ),
                  const SizedBox(height: 16),

                  // Instructions Card
                  Container(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF4E5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.info_outline,
                                color: Color(0xFFF07427),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              "Instructions",
                              style: TextStyle(
                                fontFamily: font_bold,
                                fontSize: Responsive.font(context, mobile: 18),
                                color: _heading,
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(color: Color(0xFFF1F5F9), height: 1),
                        ),
                        HtmlWidget(
                          instructionsHtml,
                          textStyle: TextStyle(
                            fontFamily: font_regular,
                            fontSize: Responsive.font(context, mobile: 15),
                            color: _body,
                            height: 1.5,
                          ),
                          customStylesBuilder:
                              (e) =>
                                  e.localName == 'li'
                                      ? const {'margin': '0 0 12px 0'}
                                      : ExamContentStyle.tableCss(e),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    IconData icon,
    Color iconColor,
    Color bgColor,
    String label,
    String value,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: _muted,
                    fontSize: Responsive.font(context, mobile: 12),
                    fontFamily: font_medium,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: _heading,
                    fontSize: Responsive.font(context, mobile: 14),
                    fontFamily: font_bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
"""

with codecs.open(r'd:\trogon_media_projects\upgradepsc\lib\view\dashboard\home\practice_intro_instruction.dart', 'w', encoding='utf-8') as f:
    f.write(dart_code)
print('UI Restored completely to match PracticeStartPage')
