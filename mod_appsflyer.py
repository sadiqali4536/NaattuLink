import codecs

fp = r'd:\trogon_media_projects\upgradepsc\lib\view\common\AppsFlyerService.dart'
with codecs.open(fp, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace(
'''      // Step 1 — the deep-link listener goes first. See rule 1 above.
      await _sdk.registerDeepLinkListener(onDeepLinking: _onDeepLinking);

      // Step 2 — initialize. This does not send a session yet.
      await _sdk.init(devKey: appsflyerDevKey, appId: appsflyerIosAppId);''',
'''      // Step 1 — the deep-link listener goes first. See rule 1 above.
      debugPrint('[DEEPLINK][INIT] AppsFlyer initialization started');
      await _sdk.registerDeepLinkListener(onDeepLinking: _onDeepLinking);
      debugPrint('[DEEPLINK][INIT] Deep-link listener registered');

      // Step 2 — initialize. This does not send a session yet.
      await _sdk.init(devKey: appsflyerDevKey, appId: appsflyerIosAppId);
      debugPrint('[DEEPLINK][INIT] AppsFlyer SDK initialized');''')

content = content.replace(
'''  static void _onDeepLinking(DeepLinkResult result) {
    switch (result.status) {
      case DeepLinkStatus.found:
        final deepLink = result.deepLink;
        if (deepLink == null) {
          log('AppsFlyer: deep link found but payload was empty');
          return;
        }
        log('AppsFlyer deep link (deferred=${deepLink.isDeferred}): $deepLink');
        _captureReferrer(deepLink);
        // Parks the link itself if it arrived during splash.
        DeepLinkRouter.handle(_routableParams(deepLink));
        break;''',
'''  static void _onDeepLinking(DeepLinkResult result) {
    final deepLink = result.deepLink;
    final isDeferred = deepLink?.clickEvent['is_deferred']?.toString().toLowerCase() == 'true';
    
    debugPrint('[DEEPLINK][APPSFLYER] status=${result.status}, isDeferred=$isDeferred, clickEvent=${deepLink?.clickEvent}');

    switch (result.status) {
      case DeepLinkStatus.found:
        if (deepLink == null) {
          log('AppsFlyer: deep link found but payload was empty');
          return;
        }
        
        debugPrint('[DEEPLINK][APPSFLYER] deepLinkValue=${deepLink.deepLinkValue}');
        
        _captureReferrer(deepLink);
        
        final routableParams = _routableParams(deepLink);
        debugPrint('[DEEPLINK][ROUTER] _routableParams output=$routableParams');
        DeepLinkRouter.handle(routableParams);
        break;''')

with codecs.open(fp, 'w', encoding='utf-8') as f:
    f.write(content)
print('Done AppsFlyerService')
