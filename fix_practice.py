import codecs

content = """import 'package:flutter/material.dart';
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
  final ExamController examController = Get.put(ExamController());

  static const Color _pageBg = Color(0xFFF7F8FA);
  static const Color _heading = Color(0xFF0F172A);
  static const Color _body = Color(0xFF475569);
  static const Color _muted = Color(0xFF8F9BB3);

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      examController.fetch_practice_exam_content(widget.url);
    });
  }

  @override
  Widget build(BuildContext context) {
    final double hPad = Responsive.isTablet(context) ? 24 : 16;

    return GetBuilder<ExamController>(
      builder: (controller) {
        String title = controller.practiceContent?['title']?.toString() ?? 'Practice Exam';
        String duration = controller.practiceContent?['duration']?.toString() ?? '0';
        if (duration.isEmpty || duration == 'null') duration = '0';
        
        String questions = controller.practiceContent?['questions_count']?.toString() ?? '0';
        if (questions == '0' || questions == 'null') {
          questions = controller.practiceContent?['questions']?.length?.toString() ?? '0';
        }

        return Scaffold(
          backgroundColor: _pageBg,
          appBar: AppBar(
            backgroundColor: _pageBg,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
              onPressed: () => Get.back(),
            ),
            title: const Text(
              'PRACTICE EXAM',
              style: TextStyle(
                color: Colors.black,
                fontFamily: font_bold,
                fontSize: 18,
              ),
            ),
            centerTitle: true,
          ),
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
                child: ElevatedButton(
                  onPressed: controller.isPracticeContentLoading ? null : () {
                    Get.off<Widget>(
                      () => PracticeExam(examId: widget.url, fetchData: false),
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
                ),
              ),
            ),
          ),
          body: controller.isPracticeContentLoading
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                  bottom: false,
                  child: SingleChildScrollView(
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
                                      color: _heading,
                                      fontFamily: font_bold,
                                      fontSize: Responsive.font(context, mobile: 16),
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Divider(
                                color: Colors.grey.shade100,
                                height: 1,
                                thickness: 1,
                              ),
                              const SizedBox(height: 14),
                              Builder(builder: (context) {
                                String descriptionHtml =
                                    controller.practiceContent?['instructions']?.toString() ??
                                    controller.practiceContent?['description']?.toString() ??
                                    '';
                                if (descriptionHtml.isNotEmpty) {
                                  return HtmlWidget(
                                    descriptionHtml,
                                    textStyle: TextStyle(
                                      color: _body,
                                      fontFamily: font_regular,
                                      fontSize: Responsive.font(context, mobile: 14),
                                      height: 1.55,
                                    ),
                                    customStylesBuilder: (e) {
                                      switch (e.localName) {
                                        case 'li':
                                          return const {'margin': '0 0 10px 0'};
                                        case 'ul':
                                        case 'ol':
                                          return const {
                                            'margin': '0',
                                            'padding-left': '18px',
                                          };
                                        case 'p':
                                          return const {'margin': '0 0 10px 0'};
                                        case 'strong':
                                        case 'b':
                                          return const {
                                            'font-family': 'plusjakartasans_semibold',
                                            'color': '#0F172A',
                                          };
                                        default:
                                          return ExamContentStyle.tableCss(e);
                                      }
                                    },
                                  );
                                } else {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildInstructionItem(
                                        context,
                                        "+1 marks for each correct answer and negative -0.33 for each incorrect answer.",
                                      ),
                                      _buildInstructionItem(
                                        context,
                                        "You can skip questions if you do not want to attend.",
                                      ),
                                      _buildInstructionItem(
                                        context,
                                        "In last question you can finish practice after confirmation.",
                                      ),
                                      _buildInstructionItem(
                                        context,
                                        "You can navigate between questions using the question numbers at the top.",
                                      ),
                                      _buildInstructionItem(
                                        context,
                                        "Once you select an answer, the correct solution will be displayed immediately.",
                                        isLast: true,
                                      ),
                                    ],
                                  );
                                }
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    IconData icon,
    Color iconColor,
    Color bgColor,
    String title,
    String value,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: _muted,
                    fontFamily: font_medium,
                    fontSize: Responsive.font(context, mobile: 12),
                    height: 1.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: const Color(0xFF0A142F),
                    fontFamily: font_bold,
                    fontSize: Responsive.font(context, mobile: 15),
                    height: 1.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(
    BuildContext context,
    String text, {
    bool isLast = false,
  }) {
    final double fontSize = Responsive.font(context, mobile: 14);
    const double lineHeight = 1.55;
    const double dotSize = 6;
    // Vertically centre the dot on the first line of text.
    final double dotTop = (fontSize * lineHeight - dotSize) / 2;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: dotTop),
            child: Container(
              width: dotSize,
              height: dotSize,
              decoration: const BoxDecoration(
                color: Color(0xFF4C429D),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: _body,
                fontFamily: font_regular,
                fontSize: fontSize,
                height: lineHeight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
"""

with codecs.open(r'd:\trogon_media_projects\upgradepsc\lib\view\dashboard\home\practice_intro_instruction.dart', 'w', encoding='utf-8') as f:
    f.write(content)
