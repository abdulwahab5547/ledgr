import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgr/core/privacy/privacy_mask.dart';
import 'package:ledgr/core/privacy/privacy_provider.dart';

void main() {
  testWidgets('renders child unchanged when privacy mode off', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: PrivacyMask(child: Text('\$1,234.56')),
          ),
        ),
      ),
    );

    expect(find.text('\$1,234.56'), findsOneWidget);
    expect(find.byType(ImageFiltered), findsNothing);
  });

  testWidgets('wraps child in ImageFiltered when privacy mode on',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(privacyModeProvider.notifier).setMasked(true);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: PrivacyMask(child: Text('\$1,234.56')),
          ),
        ),
      ),
    );

    expect(find.byType(ImageFiltered), findsOneWidget);
    expect(find.text('\$1,234.56'), findsOneWidget);
  });

  testWidgets('toggling provider rebuilds the mask', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: PrivacyMask(child: Text('secret')),
          ),
        ),
      ),
    );
    expect(find.byType(ImageFiltered), findsNothing);

    container.read(privacyModeProvider.notifier).toggle();
    await tester.pump();
    expect(find.byType(ImageFiltered), findsOneWidget);

    container.read(privacyModeProvider.notifier).toggle();
    await tester.pump();
    expect(find.byType(ImageFiltered), findsNothing);
  });
}
