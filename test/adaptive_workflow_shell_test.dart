import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:punit_label/widgets/adaptive_workflow_shell.dart';

void main() {
  Future<void> pumpShell(WidgetTester tester, {required double width}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: Size(width, 900)),
          child: Material(
            child: AdaptiveWorkflowShell(
              title: 'Dispatch',
              subtitle: 'Tablet shell test',
              compactContent: const Text('Compact Content'),
              leftPanel: const Text('Left Panel'),
              rightPanel: const Text('Right Panel'),
              primaryAction: const Text('Primary Action'),
              result: const Text('Result Section'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders compact layout below expanded tablet breakpoint', (
    tester,
  ) async {
    await pumpShell(tester, width: 800);

    expect(
      find.byKey(const Key('adaptive_workflow_compact_body')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('adaptive_workflow_split_row')), findsNothing);
    expect(find.text('Compact Content'), findsOneWidget);
    expect(find.text('Primary Action'), findsOneWidget);
    expect(find.text('Result Section'), findsOneWidget);
  });

  testWidgets('renders split row at expanded tablet breakpoint', (
    tester,
  ) async {
    await pumpShell(tester, width: 1180);

    expect(
      find.byKey(const Key('adaptive_workflow_split_row')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('adaptive_workflow_compact_body')),
      findsNothing,
    );
    expect(find.text('Left Panel'), findsOneWidget);
    expect(find.text('Right Panel'), findsOneWidget);
    expect(find.text('Primary Action'), findsOneWidget);
    expect(find.text('Result Section'), findsOneWidget);
  });
}
