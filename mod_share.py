import codecs

fp = r'd:\trogon_media_projects\upgradepsc\lib\components\referral_share.dart'
with codecs.open(fp, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('Future<void> shareAppWithReferral({String? referrerUserId}) async {',
'''Future<void> shareAppWithReferral({String? referrerUserId}) async {
  debugPrint('[DEEPLINK][SHARE] Share button clicked');
  debugPrint('[DEEPLINK][SHARE] Input data: referrer=$referrerUserId');''')

content = content.replace('final id = examId?.trim();',
'''debugPrint('[DEEPLINK][SHARE] Share button clicked');
  debugPrint('[DEEPLINK][SHARE] Input data: examId=$examId, title=$examTitle, referrer=$referrerUserId');
  final id = examId?.trim();''')

content = content.replace('await SharePlus.instance.share(',
'''debugPrint('[DEEPLINK][SHARE] Opening system share sheet...');
  await SharePlus.instance.share(''')

content = content.replace('shareDescriptionWithLink(link),\n    ),\n  );',
'''shareDescriptionWithLink(link),\n    ),\n  );\n  debugPrint('[DEEPLINK][SHARE] Share completed/cancelled');''')

content = content.replace('ShareParams(text: share_description.toString()),\n    );\n    return;',
'''ShareParams(text: share_description.toString()),\n    );\n    debugPrint('[DEEPLINK][SHARE] Share completed/cancelled');\n    return;''')

content = content.replace("examShareDescription(examTitle ?? '', link)),\n  );",
"examShareDescription(examTitle ?? '', link)),\n  );\n  debugPrint('[DEEPLINK][SHARE] Share completed/cancelled');")

content = content.replace('final userId = _resolveUserId(referrerUserId);',
'''final userId = _resolveUserId(referrerUserId);
  debugPrint('[DEEPLINK][GENERATE] Starting deep-link generation...');
  debugPrint('[DEEPLINK][GENERATE] Input: userId=$userId, deepLinkValue=$deepLinkValue, extra=$extraParams');''')

content = content.replace("if (link == null) log('Share: link generation returned nothing');",
'''debugPrint('[DEEPLINK][GENERATE] Response: $link');
    debugPrint('[DEEPLINK][GENERATE] Generated URL: $link');
    if (link == null) log('Share: link generation returned nothing');''')

with codecs.open(fp, 'w', encoding='utf-8') as f:
    f.write(content)
print('Done referral_share')
