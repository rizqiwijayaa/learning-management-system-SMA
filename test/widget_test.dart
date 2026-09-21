import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lms_guru/app.dart';

void main() {
  testWidgets('LmsGuruApp builds successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const LmsGuruApp());

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });
}
