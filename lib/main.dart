import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Add these new imports
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:permission_handler/permission_handler.dart';

// Add this import for our new provider
import 'module/providers/fcm_provider.dart';

import 'config/routes.dart';
import 'config/theme.dart';
import 'utils/flutter_web_error_handler.dart';

final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
final navigatorKey = GlobalKey<NavigatorState>();

// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  print('Handling a background message: ${message.messageId}');
  print('Message data: ${message.data}');
  print('Message notification: ${message.notification?.title}');
}

Future<void> main() async {
  // Add comprehensive error handling
  try {
    WidgetsFlutterBinding.ensureInitialized();
    print('🔥 App: WidgetsFlutterBinding initialized');
  } catch (e) {
    print('🔥 App: Error initializing WidgetsFlutterBinding: $e');
  }
  
  // Initialize Flutter web error handler
  try {
    FlutterWebErrorHandler.initialize();
    print('🔥 App: FlutterWebErrorHandler initialized');
  } catch (e) {
    print('🔥 App: Error initializing FlutterWebErrorHandler: $e');
  }
  
  // Initialize plugins
  try {
    // This helps ensure all plugins are properly initialized
    await Permission.camera.status;
    print('🔥 App: Plugins initialized');
  } catch (e) {
    print('🔥 App: Plugin initialization warning: $e');
  }
  
  try {
    if (kIsWeb) {
      // For web, Firebase will be initialized by the JS SDK in index.html
      // We just need to initialize the Flutter Firebase plugin
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyDdnfmVWzbB0k7JMpc3KfUyGDdMX5KC7fE",
          authDomain: "high-fly-21a85.firebaseapp.com",
          projectId: "high-fly-21a85",
          storageBucket: "high-fly-21a85.firebasestorage.app",
          messagingSenderId: "1014216862088",
          appId: "1:1014216862088:web:af9c032fe727a84d92723d",
          measurementId: "G-Z1B7S90QGE",
        ),
      );
      debugPrint('🔥 Firebase Web initialized successfully for project: high-fly-21a85');
    } else {
      // For mobile platforms, use the google-services configuration
      await Firebase.initializeApp();
      debugPrint('🔥 Firebase Mobile initialized successfully');
    }
  } catch (e) {
    debugPrint('🔥 Firebase initialization error: $e');
    // Continue anyway - the app should still work for basic functionality
  }
  
  // Initialize Firebase Messaging
  try {
    if (!kIsWeb) {
      // Request permission for notifications (iOS specific)
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
      }
      
      // Set the background messaging handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      
      // Get the FCM token
      final String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        print('FCM Registration Token: $token');
      } else {
        print('Failed to get FCM token');
      }
      
      // Listen for token refreshes
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        print('FCM Token refreshed: $newToken');
      }).onError((error) {
        print('Error listening for token refresh: $error');
      });
    }
  } catch (e) {
    debugPrint('🔥 Firebase Messaging initialization error: $e');
  }
  
  try {
    await initEnv();
    debugPrint('🔥 App: Environment initialized');
  } catch (e) {
    debugPrint('🔥 App: Environment initialization error: $e');
    // Continue with default environment
  }

  runApp(ProviderScope(
      child: MyApp()));
}

Future<void> initEnv() async{
  const env = String.fromEnvironment('env', defaultValue: 'dev');
  try {
    await dotenv.load(fileName: 'assets/env/.env.$env');
    debugPrint('Environment loaded successfully: $env');
    debugPrint('BASE_URL: ${dotenv.env['BASE_URL']}');
  } catch (e) {
    debugPrint('Failed to load environment file: $e');
    // Fallback to default values
    dotenv.env['ENVIRONMENT'] = env;
    dotenv.env['BASE_URL'] = 'https://2bb922f2af1d.ngrok-free.app/api/v1/';
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize FCM token and request notification permissions when app starts
    // WidgetsBinding.instance.addPostFrameCallback((_) async {
    //   if (!kIsWeb) {
    //     try {
    //       final fcmService = ref.read(fcmProvider);
    //
    //       // Request notification permissions on both Android and iOS
    //       final permissionGranted = await fcmService.requestNotificationPermission();
    //
    //       if (permissionGranted) {
    //         // Get FCM token
    //         final token = await fcmService.getFcmToken();
    //         if (token != null) {
    //           // Register token with backend
    //           await fcmService.registerToken(token);
    //         }
    //
    //         // Listen for token refreshes
    //         fcmService.listenForTokenRefresh((newToken) async {
    //           await fcmService.registerToken(newToken);
    //         });
    //       }
    //     } catch (e) {
    //       debugPrint('Error initializing FCM: $e');
    //     }
    //   }
    // });
    
    // Check authentication state
    // final user = FirebaseAuth.instance.currentUser;
    
    final app = MaterialApp.router(
      debugShowCheckedModeBanner: false,
      key: navigatorKey,
      scaffoldMessengerKey: scaffoldMessengerKey,
      title: 'HighFly',
      theme: lightTheme,
      // Define light theme
      // darkTheme: darkTheme,
      // Define dark theme
      // themeMode: themeMode,
      // Control theme mode
      routerConfig: router,
    );
    
    // Wrap with error boundary for web
    return FlutterWebErrorHandler.withErrorBoundary(app);
  }
}