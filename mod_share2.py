import codecs

fp = r'd:\trogon_media_projects\upgradepsc\lib\components\referral_share.dart'
with codecs.open(fp, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('Future<void> shareAppWithReferral({String? referrerUserId}) async {',
'''Future<void> shareAppWithReferral({String? referrerUserId}) async {
  final traceId = DateTime.now().millisecondsSinceEpoch.toString();
  debugPrint('[DEEPLINK][$traceId][SHARE] Share button clicked');
  debugPrint('[DEEPLINK][$traceId][SHARE] Input data: referrer=$referrerUserId');''')
content = content.replace('final link = await _generateLink(referrerUserId: referrerUserId);',
'''final link = await _generateLink(traceId: traceId, referrerUserId: referrerUserId);''')

content = content.replace('await SharePlus.instance.share(\n    ShareParams(\n      text:\n          link == null\n              ? share_description.toString()\n              : shareDescriptionWithLink(link),\n    ),\n  );',
'''final result = await SharePlus.instance.share(
    ShareParams(
      text: link == null ? share_description.toString() : shareDescriptionWithLink(link),
    ),
  );
  debugPrint('[DEEPLINK][$traceId][SHARE] Share result: $result');''')

content = content.replace('Future<void> shareExamWithReferral({',
'''Future<void> shareExamWithReferral({''')

content = content.replace("debugPrint('[DEEPLINK][SHARE] Share button clicked');\n  debugPrint('[DEEPLINK][SHARE] Input data: examId=$examId, title=$examTitle, referrer=$referrerUserId');",
'''final traceId = DateTime.now().millisecondsSinceEpoch.toString();
  debugPrint('[DEEPLINK][$traceId][SHARE] Share button clicked');
  debugPrint('[DEEPLINK][$traceId][SHARE] Input data: examId=$examId, title=$examTitle, referrer=$referrerUserId');''')

content = content.replace("final link = await _generateLink(\n    referrerUserId: referrerUserId,\n    deepLinkValue: 'exam',\n    extraParams: {'eid': id},\n  );",
'''debugPrint('[DEEPLINK][$traceId][GENERATE] Starting deep-link generation');
  debugPrint('[DEEPLINK][$traceId][GENERATE] deepLinkValue=exam');
  debugPrint('[DEEPLINK][$traceId][GENERATE] extra={eid: $id}');
  
  final link = await _generateLink(
    traceId: traceId,
    referrerUserId: referrerUserId,
    deepLinkValue: 'exam',
    extraParams: {'eid': id},
  );''')

content = content.replace("debugPrint('[DEEPLINK][SHARE] Opening system share sheet...');\n  await SharePlus.instance.share(\n      ShareParams(text: share_description.toString()),\n    );\n    return;",
'''debugPrint('[DEEPLINK][$traceId][SHARE] Opening system share sheet (fallback)...');
    final result = await SharePlus.instance.share(
      ShareParams(text: share_description.toString()),
    );
    debugPrint('[DEEPLINK][$traceId][SHARE] Share result: $result');
    return;''')

content = content.replace("debugPrint('[DEEPLINK][SHARE] Opening system share sheet...');\n  await SharePlus.instance.share(\n    ShareParams(text: examShareDescription(examTitle ?? '', link)),\n  );",
'''debugPrint('[DEEPLINK][$traceId][SHARE] Opening system share sheet...');
  final result = await SharePlus.instance.share(
    ShareParams(text: examShareDescription(examTitle ?? '', link)),
  );
  debugPrint('[DEEPLINK][$traceId][SHARE] Share result: $result');''')

content = content.replace("Future<String?> _generateLink({\n  String? referrerUserId,",
'''Future<String?> _generateLink({\n  required String traceId,\n  String? referrerUserId,''')

content = content.replace("debugPrint('[DEEPLINK][GENERATE] Starting deep-link generation...');\n  debugPrint('[DEEPLINK][GENERATE] Input: userId=$userId, deepLinkValue=$deepLinkValue, extra=$extraParams');",
"")

content = content.replace("final link = await AppsFlyerService.generateShareLink(",
'''debugPrint('[DEEPLINK][$traceId][APPSFLYER_GENERATE] Started');
    debugPrint('[DEEPLINK][$traceId][APPSFLYER_GENERATE] referrerUserId=$userId');
    debugPrint('[DEEPLINK][$traceId][APPSFLYER_GENERATE] deepLinkValue=$deepLinkValue');
    debugPrint('[DEEPLINK][$traceId][APPSFLYER_GENERATE] extraParams=$extraParams');
    
    final link = await AppsFlyerService.generateShareLink(''')

content = content.replace("debugPrint('[DEEPLINK][GENERATE] Response: $link');\n    debugPrint('[DEEPLINK][GENERATE] Generated URL: $link');",
'''debugPrint('[DEEPLINK][$traceId][APPSFLYER_GENERATE] GeneratedLink=$link');''')

with codecs.open(fp, 'w', encoding='utf-8') as f:
    f.write(content)
print('Done referral_share')
