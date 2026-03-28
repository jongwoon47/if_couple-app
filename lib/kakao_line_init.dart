import 'package:flutter_line_sdk/flutter_line_sdk.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';

import 'services/app_config.dart';

Future<void> initKakaoAndLine() async {
  final k = AppConfig.kakaoNativeAppKey.trim();
  if (k.isNotEmpty) {
    KakaoSdk.init(nativeAppKey: k);
  }
  final l = AppConfig.lineChannelId.trim();
  if (l.isNotEmpty) {
    await LineSDK.instance.setup(l);
  }
}
