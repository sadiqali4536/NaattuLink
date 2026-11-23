import re
with open(r'd:\trogon_media_projects\upgradepsc\lib\view\common\deep_link_router.dart', 'r', encoding='utf-8') as f:
    content = f.read()

replacement = '''static Future<void> _openExam(String examId) async {
    try {
      try {
        final result = await InternetAddress.lookup('example.com');
        if (result.isEmpty || result[0].rawAddress.isEmpty) {
          toast_error(
            'No internet connection. Please check your network and try again.',
          );
          return;
        }
      } catch (_) {
        toast_error(
          'No internet connection. Please check your network and try again.',
        );
        return;
      }

      final data = await ApiBasehandler.exam_access(examId);
      log('STEP 1: data=$data');

      if (data is! Map) {
        log('DeepLinkRouter: exam_access failed for $examId');
        toast_error('Could not open this exam. Please try again.');
        return;
      }

      log('STEP 2');
      final canAccess =
          (data['data'] is Map)
              ? data['data']['can_access'] == true
              : (data['can_access'] == true);
      
      log('STEP 3');
      final message = data['message']?.toString();

      log('STEP 4');
      if (!canAccess) {
        log('DeepLinkRouter: access denied for exam $examId ($message)');
        toast_info(
          message != null && message.isNotEmpty
              ? message
              : 'This exam is not available for you',
        );
        return;
      }

      log('STEP 5');
      log('DeepLinkRouter: opening exam $examId');
      if (openInExamWebView(examWebViewUrl(examId))) return;

      log('STEP 6');
      Map examMap = {'id': examId};
      if (data['data'] is Map) {
        examMap.addAll(data['data']);
      }
      examMap['id'] = examId;

      log('STEP 7');
      Get.to(() => PracticeStartPage(exam: examMap, isPracticeMode: false));
      log('STEP 8');
    } catch (e, stack) {
      log('DeepLinkRouter exam access error: $e\\n$stack');
      toast_error('Could not open this exam. Please try again.');
    }
  }'''

content = re.sub(r'static Future<void> _openExam\(String examId\) async \{.*?\n  \}', replacement, content, flags=re.DOTALL)

with open(r'd:\trogon_media_projects\upgradepsc\lib\view\common\deep_link_router.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print('Fixed file')
