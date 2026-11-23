import codecs

fp = r'd:\trogon_media_projects\upgradepsc\lib\view\common\deep_link_router.dart'
with codecs.open(fp, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace(
'''  static void handle(Map<String, dynamic> raw) {
    final params = _clean(raw);
    if (params.isEmpty) return;''',
'''  static void handle(Map<String, dynamic> raw) {
    final params = _clean(raw);
    debugPrint('[DEEPLINK][ROUTER] handle() received: $params');
    if (params.isEmpty) return;''')

content = content.replace(
'''  static void handleUrl(String? url) {
    final uri = Uri.tryParse(url?.trim() ?? '');
    if (uri == null || uri.toString().isEmpty) return;''',
'''  static void handleUrl(String? url) {
    final rawUrl = url?.trim();
    debugPrint('[DEEPLINK][PARSE] Raw URI: $rawUrl');

    if (rawUrl == null || rawUrl.isEmpty) {
      debugPrint('[DEEPLINK][ERROR] Empty deep-link URL');
      return;
    }

    final uri = Uri.tryParse(rawUrl);
    if (uri == null) {
      debugPrint('[DEEPLINK][ERROR] URI parsing failed');
      return;
    }

    debugPrint('[DEEPLINK][PARSE] scheme=${uri.scheme}');
    debugPrint('[DEEPLINK][PARSE] host=${uri.host}');
    debugPrint('[DEEPLINK][PARSE] path=${uri.path}');
    debugPrint('[DEEPLINK][PARSE] query=${uri.query}');
    debugPrint('[DEEPLINK][PARSE] queryParameters=${uri.queryParameters}');''')

content = content.replace(
'''  static void _route(Map<String, String> params) {
    try {
      final destination = _first(params, _destinationKeys)?.toLowerCase();
      final url = _first(params, _urlKeys);''',
'''  static void _route(Map<String, String> params) {
    try {
      final rawDestination = _first(params, _destinationKeys);
      debugPrint('[DEEPLINK][ROUTE] Raw destination=$rawDestination');
      
      final destination = rawDestination?.trim().toLowerCase();
      debugPrint('[DEEPLINK][ROUTE] Normalized destination=$destination');
      debugPrint('[DEEPLINK][ROUTE] All params=$params');

      final url = _first(params, _urlKeys);''')

content = content.replace(
'''        case 'exam':
          final examId = _first(params, _examIdKeys);
          if (examId != null) {
            _openExam(examId);
          } else {
            _openTab(3, destination);
          }
          return;''',
'''        case 'exam':
          debugPrint('[DEEPLINK][ROUTE] Exam ID candidate keys=$_examIdKeys');
          final examId = _first(params, _examIdKeys);
          debugPrint('[DEEPLINK][ROUTE] Extracted examId=$examId');
          
          if (examId != null) {
            debugPrint('[DEEPLINK][NAVIGATION] Opening exam $examId');
            try {
              _openExam(examId);
              debugPrint('[DEEPLINK][NAVIGATION] _openExam() called successfully');
            } catch (e, stack) {
              debugPrint('[DEEPLINK][NAVIGATION][ERROR] $e');
              debugPrint('[DEEPLINK][NAVIGATION][STACK] $stack');
            }
          } else {
            _openTab(3, destination);
          }
          return;''')

content = content.replace(
'''        case 'course':
          final courseId = _first(params, _courseIdKeys);
          if (courseId != null) {
            log('DeepLinkRouter: opening course $courseId');
            Get.to(() => course_details(course_id: courseId));
          } else {
            _openTab(0, destination);
          }
          return;''',
'''        case 'course':
          debugPrint('[DEEPLINK][ROUTE] Course ID candidate keys=$_courseIdKeys');
          final courseId = _first(params, _courseIdKeys);
          debugPrint('[DEEPLINK][ROUTE] Extracted courseId=$courseId');
          
          if (courseId != null) {
            debugPrint('[DEEPLINK][NAVIGATION] Opening course $courseId');
            try {
              Get.to(() => course_details(course_id: courseId));
              debugPrint('[DEEPLINK][NAVIGATION] course_details called successfully');
            } catch (e, stack) {
              debugPrint('[DEEPLINK][NAVIGATION][ERROR] $e');
              debugPrint('[DEEPLINK][NAVIGATION][STACK] $stack');
            }
          } else {
            _openTab(0, destination);
          }
          return;''')

content = content.replace(
'''    } catch (e) {
      log('DeepLinkRouter error: $e');
    }
  }''',
'''    } catch (e, stack) {
      debugPrint('[DEEPLINK][ERROR] Routing exception: $e');
      debugPrint('[DEEPLINK][ERROR] Stack: $stack');
    }
  }''')

with codecs.open(fp, 'w', encoding='utf-8') as f:
    f.write(content)
print('Done deep_link_router')
