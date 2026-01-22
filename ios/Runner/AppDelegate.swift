import Flutter
import UIKit
import FirebaseCore
import FirebaseAuth
import FirebaseMessaging
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    
    // Enable App Verification for Phone Auth (uses reCAPTCHA as fallback)
    Auth.auth().settings?.isAppVerificationDisabledForTesting = false
    
    // Store reference to application for later APNs token setting
    // This ensures we can set the token even if it arrives after phone auth is attempted
    print("✅ Firebase configured, ready for APNs token")
    
    // Request notification permissions
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
      UNUserNotificationCenter.current().requestAuthorization(
        options: authOptions,
        completionHandler: { granted, error in
          if granted {
            print("✅ Notification permission granted")
            // Register for remote notifications after permission is granted
            DispatchQueue.main.async {
              application.registerForRemoteNotifications()
            }
          } else {
            print("❌ Notification permission denied: \(error?.localizedDescription ?? "unknown")")
            // Still try to register - might work for silent notifications
            DispatchQueue.main.async {
              application.registerForRemoteNotifications()
            }
          }
        }
      )
    } else {
      let settings: UIUserNotificationSettings =
        UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
      application.registerUserNotificationSettings(settings)
      application.registerForRemoteNotifications()
    }
    
    // Set FCM messaging delegate
    Messaging.messaging().delegate = self
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // Handle URL schemes for Firebase Phone Auth
  override func application(_ app: UIApplication, open url: URL,
                            options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    if Auth.auth().canHandle(url) {
      return true
    }
    return super.application(app, open: url, options: options)
  }
  
  // Handle APNs device token registration
  override func application(_ application: UIApplication,
                            didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    print("✅ APNs device token retrieved: \(tokenString)")
    
    // Pass device token to Firebase Messaging
    Messaging.messaging().apnsToken = deviceToken
    
    // Determine APNs token type based on entitlements
    // ALWAYS use entitlements value - this must match Firebase Console APNs key configuration
    var tokenType: AuthAPNSTokenType = .sandbox // Default to sandbox
    
    // Read entitlements to determine environment - this is the source of truth
    if let entitlementsPath = Bundle.main.path(forResource: "Runner", ofType: "entitlements"),
       let entitlements = NSDictionary(contentsOfFile: entitlementsPath),
       let apsEnvironment = entitlements["aps-environment"] as? String {
      if apsEnvironment == "production" {
        tokenType = .prod
        print("📱 Using Production APNs token type (from entitlements: \(apsEnvironment))")
      } else {
        tokenType = .sandbox
        print("📱 Using Sandbox APNs token type (from entitlements: \(apsEnvironment))")
      }
    } else {
      // If entitlements can't be read, default to sandbox for safety
      tokenType = .sandbox
      print("⚠️ Could not read entitlements, defaulting to Sandbox APNs token type")
    }
    
    // Pass device token to Firebase Auth for Phone Authentication
    // This allows Firebase Auth to use APNs instead of reCAPTCHA
    Auth.auth().setAPNSToken(deviceToken, type: tokenType)
    print("✅ APNs token set for Firebase Auth (type: \(tokenType == .sandbox ? "Sandbox" : "Production"))")
    
    // IMPORTANT: Also try the other type as a fallback
    // Sometimes Firebase needs both to be set, especially if there's a configuration mismatch
    let alternateType: AuthAPNSTokenType = tokenType == .sandbox ? .prod : .sandbox
    Auth.auth().setAPNSToken(deviceToken, type: alternateType)
    print("✅ APNs token also set for Firebase Auth (alternate type: \(alternateType == .sandbox ? "Sandbox" : "Production"))")
    
    // Also pass to Flutter
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }
  
  // Handle silent push notifications for Firebase Auth
  // This is required for Firebase Phone Authentication to work with APNs
  override func application(_ application: UIApplication,
                            didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                            fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    // Check if this is a Firebase Auth notification
    if Auth.auth().canHandleNotification(userInfo) {
      completionHandler(.noData)
      return
    }
    
    // Handle other notifications
    super.application(application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler)
  }
  
  // Handle APNs registration failure
  override func application(_ application: UIApplication,
                            didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print("❌ Failed to register for remote notifications: \(error.localizedDescription)")
    print("❌ APNs registration error details: \(error)")
    
    // If APNs fails, Firebase Auth will fall back to reCAPTCHA
    // Make sure reCAPTCHA is properly configured
    print("⚠️ Firebase Auth will use reCAPTCHA fallback for phone authentication")
    
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }
}

// MARK: - MessagingDelegate
extension AppDelegate: MessagingDelegate {
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    print("Firebase registration token: \(String(describing: fcmToken))")
    
    let dataDict: [String: String] = ["token": fcmToken ?? ""]
    NotificationCenter.default.post(
      name: Notification.Name("FCMToken"),
      object: nil,
      userInfo: dataDict
    )
  }
}