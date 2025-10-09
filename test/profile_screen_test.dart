import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:highfly/module/screens/profile/profile_screen.dart';

void main() {
  group('ProfileScreen Widget Tests', () {
    testWidgets('ProfileScreen displays correctly', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );

      // Wait for the initial load to complete
      await tester.pumpAndSettle();

      // Verify that the profile settings header is displayed
      expect(find.text('PROFILE SETTINGS'), findsOneWidget);
      expect(find.text('Update your profile details.'), findsOneWidget);

      // Verify that the profile form fields are displayed
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Phone Number'), findsOneWidget);
      expect(find.text('Rera Number'), findsOneWidget);
      expect(find.text('Team Leader Name'), findsOneWidget);
      expect(find.text('ID Number'), findsOneWidget);

      // Verify that the action buttons are displayed
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Update'), findsOneWidget);

      // Verify that the profile picture edit button is displayed
      expect(find.text('Edit'), findsOneWidget);
    });

    testWidgets('ProfileScreen form fields contain sample data', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );

      // Wait for the profile to load
      await tester.pumpAndSettle();

      // Verify that the form fields contain the sample data
      expect(find.text('Alex Johnson'), findsOneWidget);
      expect(find.text('1234567890'), findsOneWidget);
      expect(find.text('9876543210'), findsOneWidget);
      expect(find.text('Daniel Roberts'), findsOneWidget);
      expect(find.text('9892654845'), findsOneWidget);
    });

    testWidgets('ProfileScreen header displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );

      // Wait for the initial load
      await tester.pumpAndSettle();

      // Verify the app bar title
      expect(find.text('HighFly - PROFILE'), findsOneWidget);

      // Verify the menu and logout buttons are present
      expect(find.byIcon(Icons.menu), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_ios), findsOneWidget);
    });
  });
}
