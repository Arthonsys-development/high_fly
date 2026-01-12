import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:permission_handler/permission_handler.dart';

import 'config/constant/app_strings.dart';
import 'config/routes.dart';
import 'config/theme.dart';
import 'module/providers/organization_provider.dart';
import 'utils/flutter_web_error_handler.dart';
import 'utils/notification_service.dart';

final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
final navigatorKey = GlobalKey<NavigatorState>();

// Background message handler - MUST be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if not already initialized
  await Firebase.initializeApp();
  
  debugPrint('🔔 Handling a background message: ${message.messageId}');
  debugPrint('🔔 Message data: ${message.data}');
  debugPrint('🔔 Message notification: ${message.notification?.title}');
  debugPrint('🔔 Message notification body: ${message.notification?.body}');
}

// Handle notification tap
void _handleNotificationTap(RemoteMessage message) {
  debugPrint('🔔 Handling notification tap');
  debugPrint('🔔 Message data: ${message.data}');
  
  // TODO: Navigate to appropriate screen based on message.data
  // Example:
  // final String? screen = message.data['screen'];
  // if (screen != null && navigatorKey.currentState != null) {
  //   navigatorKey.currentState!.pushNamed(screen);
  // }
}


Future<void> main() async {
  // Add comprehensive error handling
  try {
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint('🔥 App: WidgetsFlutterBinding initialized');
  } catch (e) {
    debugPrint('🔥 App: Error initializing WidgetsFlutterBinding: $e');
  }
  
  // Initialize Flutter web error handler
  try {
    FlutterWebErrorHandler.initialize();
    debugPrint('🔥 App: FlutterWebErrorHandler initialized');
  } catch (e) {
    debugPrint('🔥 App: Error initializing FlutterWebErrorHandler: $e');
  }
  
  // Initialize plugins
  try {
    // This helps ensure all plugins are properly initialized
    await Permission.camera.status;
    debugPrint('🔥 App: Plugins initialized');
  } catch (e) {
    debugPrint('🔥 App: Plugin initialization warning: $e');
  }
  
  try {
    if (kIsWeb) {
      // For web, Firebase will be initialized by the JS SDK in index.html
      // We just need to initialize the Flutter Firebase plugin
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyAuLYabgeakEBFP0vijPe0B1HlxJXLwmVg",
          authDomain: "vistarak-apps.firebaseapp.com",
          projectId: "vistarak-apps",
          storageBucket: "vistarak-apps.firebasestorage.app",
          messagingSenderId: "930030992658",
          appId: "1:930030992658:web:0f03cbb4fd5ac8a0f407cb",
          measurementId: "G-MTNV4XJEBF",
        ),
      );
      debugPrint('🔥 Firebase Web initialized successfully for project: vistarak-apps');
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
      // Initialize notification service for foreground notifications
      await NotificationService().initialize();
      
      // Request permission for notifications (iOS specific)
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
      }
      
      // Set the background messaging handler early, before other initialization
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      
      // Configure foreground notification presentation (iOS)
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      
      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('🔔 Got a message whilst in the FOREGROUND!');
        debugPrint('🔔 Message data: ${message.data}');

        if (message.notification != null) {
          debugPrint('🔔 Message also contained a notification: ${message.notification}');
          debugPrint('🔔 Title: ${message.notification?.title}');
          debugPrint('🔔 Body: ${message.notification?.body}');
          
          // Show notification in foreground
          NotificationService().showNotification(message);
        }
      });

      // Handle notification taps when app is in background (but not terminated)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('🔔 A notification was tapped - app was in BACKGROUND');
        debugPrint('🔔 Message data: ${message.data}');
        
        // Handle navigation based on notification data
        _handleNotificationTap(message);
      });

      // Check if app was opened from a notification (terminated state)
      RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('🔔 App opened from TERMINATED state via notification');
        debugPrint('🔔 Message data: ${initialMessage.data}');
        
        // Handle navigation based on notification data
        _handleNotificationTap(initialMessage);
      }
      
      // Get the FCM token
      final String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        debugPrint('🔔 FCM Registration Token: $token');
      } else {
        debugPrint('🔔 Failed to get FCM token');
      }
      
      // Listen for token refreshes
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        debugPrint('🔔 FCM Token refreshed: $newToken');
      }).onError((error) {
        debugPrint('🔔 Error listening for token refresh: $error');
      });
    }
  } catch (e) {
    debugPrint('🔥 Firebase Messaging initialization error: $e');
  }
  
  // Initialize Firebase Analytics
  try {
    final analytics = FirebaseAnalytics.instance;
    debugPrint('🔥 Firebase Analytics initialized successfully');
    // Set analytics collection enabled (it's enabled by default)
    await analytics.setAnalyticsCollectionEnabled(true);
  } catch (e) {
    debugPrint('🔥 Firebase Analytics initialization error: $e');
    // Continue anyway - analytics is not critical for app functionality
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
    final organizationState = ref.watch(organizationProvider);
    final organizationName =
        organizationState.asData?.value?.name ?? GlobalStrings.appName;

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
      title: organizationName,
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