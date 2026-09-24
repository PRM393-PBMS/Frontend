import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_frontend/core/config/app_config.dart';

void main() {
  test('AppConfig smoke test', () {
    expect(AppConfig.appTitle, isNotEmpty);
    expect(AppConfig.baseUrl, isNotEmpty);
  });
}
