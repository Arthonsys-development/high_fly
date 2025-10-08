// // This is a basic FCM provider test.
// //
// // To perform an interaction with a provider in your test, use the ProviderContainer
// // utility in the flutter_riverpod package.
//
// import 'package:flutter_test/flutter_test.dart';
// import 'package:highfly/data/repository/auth_api_repository_provider.dart';
// import 'package:mockito/mockito.dart';
// import 'package:mockito/annotations.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:highfly/module/providers/fcm_provider.dart';
// import 'package:highfly/data/repository/auth_api_repository.dart';
//
// // Generate mock classes
// @GenerateMocks([AuthApiRepository])
// import 'fcm_test.mocks.dart';
//
// void main() {
//   group('FCM Provider Tests', () {
//     late MockAuthApiRepository mockAuthApiRepository;
//     late ProviderContainer container;
//
//     setUp(() {
//       mockAuthApiRepository = MockAuthApiRepository();
//       container = ProviderContainer(
//         overrides: [
//           authApiRepositoryProvider.overrideWithValue(mockAuthApiRepository),
//         ],
//       );
//     });
//
//     tearDown(() {
//       container.dispose();
//     });
//
//     test('Initial state should be correct', () {
//       final fcmState = container.read(fcmProvider);
//       expect(fcmState.isLoading, false);
//       expect(fcmState.token, null);
//       expect(fcmState.error, null);
//     });
//
//     test('State should update correctly when copyWith is called', () {
//       final initialState = FcmTokenState();
//       final newState = initialState.copyWith(isLoading: true, token: 'test_token');
//
//       expect(newState.isLoading, true);
//       expect(newState.token, 'test_token');
//       expect(newState.error, null);
//     });
//   });
// }