import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lastcheck_app/theme.dart';

void main() {
  testWidgets('theme smoke test', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(),
      home: const Scaffold(body: Text('x')),
    ));
    expect(find.text('x'), findsOneWidget);
  });
}
