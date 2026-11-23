import codecs

fp = r'd:\trogon_media_projects\upgradepsc\lib\controller\exam_controller.dart'
with codecs.open(fp, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace(
'''  Future<void> fetch_scheduled_exam_content(String examId) async {
    isPracticeContentLoading = true;
    update();

    var response = await ApiBasehandler.scheduled_exam_content(examId);
    print("DEBUG: scheduled_exam_content response: $response");

    if (response != 'failed' && response['status'] == 1) {''',
'''  Future<void> fetch_scheduled_exam_content(String examId) async {
    isPracticeContentLoading = true;
    update();
    
    debugPrint('[DEEPLINK][TARGET] ExamController initialized');
    debugPrint('[DEEPLINK][TARGET] examId=$examId');
    debugPrint('[DEEPLINK][API] fetch_scheduled_exam_content started for examId=$examId');

    var response = await ApiBasehandler.scheduled_exam_content(examId);
    
    if (response != 'failed') {
      debugPrint('[DEEPLINK][API] Response status=${response['status']}');
    }
    debugPrint('[DEEPLINK][API] Response=$response');

    print("DEBUG: scheduled_exam_content response: $response");

    if (response != 'failed' && response['status'] == 1) {
      debugPrint('[DEEPLINK][TARGET] Exam data parsed successfully');
      var questions = response['data']?['questions'];
      if (questions != null) {
        debugPrint('[DEEPLINK][TARGET] Question count=${questions.length}');
      }''')

with codecs.open(fp, 'w', encoding='utf-8') as f:
    f.write(content)
print('Done exam_controller')
