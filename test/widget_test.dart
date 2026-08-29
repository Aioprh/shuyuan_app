import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:shuyuan_app/main.dart';

void main() {
  testWidgets('App builds smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ShuYuanApp());
    await tester.pump();

    // 底部导航五大功能区
    expect(find.text('书源'), findsWidgets);
    expect(find.text('合集'), findsOneWidget);
    expect(find.text('订阅源'), findsOneWidget);
    expect(find.text('新建'), findsOneWidget);
    expect(find.text('我的'), findsOneWidget);
  });
}