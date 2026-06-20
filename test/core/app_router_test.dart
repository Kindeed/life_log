import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/core/routing/app_router.dart';
import 'package:life_log/core/routing/app_routes.dart';

void main() {
  testWidgets('buildCoreRouter wires root and login routes', (tester) async {
    final router = buildCoreRouter(
      rootBuilder: (context, state) => const Text('root route'),
      loginBuilder: (context, state) => const Text('login route'),
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    expect(find.text('root route'), findsOneWidget);

    router.go(AppRoutes.login);
    await tester.pumpAndSettle();

    expect(find.text('login route'), findsOneWidget);
  });

  test('mobile app shell is wired through MaterialApp.router and GoRouter', () {
    final source = File('lib/app/lifelog_mobile_entry.dart').readAsStringSync();

    expect(source, contains('buildCoreRouter'));
    expect(source, contains('MaterialApp.router'));
    expect(source, isNot(contains('GetMaterialApp')));
    expect(source, isNot(contains('GetPage(')));
    expect(source, isNot(contains('getPages:')));
    expect(source, isNot(contains('initialRoute:')));
    expect(source, isNot(contains('initialBinding:')));
    expect(source, isNot(contains('binding: TabsBinding()')));
    expect(source, isNot(contains('TabsBinding')));
  });
}
