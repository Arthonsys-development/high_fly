import 'package:flutter_test/flutter_test.dart';
import 'package:highfly/module/widgets/dashboard_side_menu.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('MobileSideMenuDrawer Tests', () {
    test('MobileSideMenuDrawer can be instantiated', () {
      // Verify that the widget can be created
      expect(
        MobileSideMenuDrawer(
          selectedIndex: 0,
          onMenuItemSelected: (int index) {},
        ),
        isNotNull,
      );
    });
  });
}