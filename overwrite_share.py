import codecs

dart_code = """import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:share_plus/share_plus.dart';
import 'package:upgradepsc/components/constants.dart';
import 'package:upgradepsc/view/common/AppsFlyerService.dart';

Future<void> shareAppWithReferral({String? referrerUserId}) async {
  final traceId = DateTime.now().millisecondsSinceEpoch.toString();
  debugPrint('[DEEPLINK][$traceId][SHARE] Share button clicked');
  debugPrint('[DEEPLINK][$traceId][SHARE] Input data: referrer=$referrerUserId');
  final link = await _generateLink(traceId: traceId, referrerUserId: referrerUserId);

  debugPrint('[DEEPLINK][$traceId][SHARE] Opening system share sheet...');
  final result = await SharePlus.instance.share(
    ShareParams(
      text:
          link == null
              ? share_description.toString()
              : shareDescriptionWithLink(link),
    ),
  );
  debugPrint('[DEEPLINK][$traceId][SHARE] Share result: $result');
}

Future<void> shareExamWithReferral({
  required String? examId,
  String? examTitle,
  String? referrerUserId,
}) async {
  final traceId = DateTime.now().millisecondsSinceEpoch.toString();
  debugPrint('[DEEPLINK][$traceId][SHARE] Share button clicked');
  debugPrint('[DEEPLINK][$traceId][SHARE] Input data: examId=$examId, title=$examTitle, referrer=$referrerUserId');
  final id = examId?.trim();
  if (id == null || id.isEmpty || id == 'null') {
    log('Exam share: no exam id, sharing the app instead');
    await shareAppWithReferral(referrerUserId: referrerUserId);
    return;
  }

  debugPrint('[DEEPLINK][$traceId][GENERATE] Starting deep-link generation');
  debugPrint('[DEEPLINK][$traceId][GENERATE] deepLinkValue=exam');
  debugPrint('[DEEPLINK][$traceId][GENERATE] extra={eid: $id}');
  
  final link = await _generateLink(
    traceId: traceId,
    referrerUserId: referrerUserId,
    deepLinkValue: 'exam',
    extraParams: {'eid': id},
  );

  if (link == null) {
    debugPrint('[DEEPLINK][$traceId][SHARE] Opening system share sheet (fallback)...');
    final result = await SharePlus.instance.share(
      ShareParams(text: share_description.toString()),
    );
    debugPrint('[DEEPLINK][$traceId][SHARE] Share result: $result');
    return;
  }

  debugPrint('[DEEPLINK][$traceId][SHARE] Opening system share sheet...');
  final result = await SharePlus.instance.share(
    ShareParams(text: examShareDescription(examTitle ?? '', link)),
  );
  debugPrint('[DEEPLINK][$traceId][SHARE] Share result: $result');
}

Future<String?> _generateLink({
  required String traceId,
  String? referrerUserId,
  String? deepLinkValue,
  Map<String, String>? extraParams,
}) async {
  final userId = _resolveUserId(referrerUserId);

  _showGeneratingDialog();
  try {
    debugPrint('[DEEPLINK][$traceId][APPSFLYER_GENERATE] Started');
    debugPrint('[DEEPLINK][$traceId][APPSFLYER_GENERATE] referrerUserId=$userId');
    debugPrint('[DEEPLINK][$traceId][APPSFLYER_GENERATE] deepLinkValue=$deepLinkValue');
    debugPrint('[DEEPLINK][$traceId][APPSFLYER_GENERATE] extraParams=$extraParams');
    
    final link = await AppsFlyerService.generateShareLink(
      referrerUserId: userId,
      deepLinkValue: deepLinkValue,
      extraParams: extraParams,
    );
    debugPrint('[DEEPLINK][$traceId][APPSFLYER_GENERATE] GeneratedLink=$link');
    if (link == null) log('Share: link generation returned nothing');
    return link;
  } catch (e) {
    log('Share: link generation failed: $e');
    return null;
  } finally {
    if (Get.isDialogOpen ?? false) Get.back();
  }
}

String? _resolveUserId(String? referrerUserId) {
  final fromProfile = referrerUserId?.trim();
  if (fromProfile != null && fromProfile.isNotEmpty && fromProfile != 'null') {
    return fromProfile;
  }
  try {
    final stored = GetStorage().read('user_id')?.toString().trim();
    if (stored != null && stored.isNotEmpty && stored != 'null') return stored;
  } catch (_) {}
  return null;
}

void _showGeneratingDialog() {
  Get.dialog(
    Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: textwhiteColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: CircularProgressIndicator(color: primaryColor),
      ),
    ),
    barrierDismissible: false,
  );
}
"""

with codecs.open(r'd:\trogon_media_projects\upgradepsc\lib\components\referral_share.dart', 'w', encoding='utf-8') as f:
    f.write(dart_code)
print('Replaced')
