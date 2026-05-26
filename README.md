# Vistarak (HighFly)

A comprehensive real estate management Flutter application that enables property visits, bookings, and visitor management for real estate professionals.

**Version**: 1.0.1+4

## 📱 About

Vistarak is a cross-platform mobile and web application built with Flutter that streamlines real estate operations including property visits, booking management, hold bookings, and visitor tracking. The app provides a seamless experience for real estate agents and customers to manage property-related activities.

## ✨ Features

### Authentication
- **Sign In/Sign Up**: Secure user authentication with Firebase
- **OTP Verification**: Phone number verification using Firebase Auth
- **Secure Storage**: Token management using Flutter Secure Storage

### Core Functionality
- **Dashboard**: Overview of visits, bookings, and key metrics
- **Visitor Management**: Track and manage property visits
  - Add new visits with location tracking
  - View visit details and history
  - Image capture for visit documentation
- **Booking Management**: Complete booking system for properties
  - Project and plot selection
  - Booking creation and management
  - Booking details and history
- **Hold Bookings**: Manage property hold requests
  - Create hold bookings
  - View hold details and status
- **Profile Management**: User profile with photo upload and details

### Additional Features
- **Push Notifications**: Firebase Cloud Messaging (FCM) integration with foreground/background handling
- **Analytics**: Firebase Analytics for user behavior tracking
- **Location Services**: Geolocation for visit tracking with permission handling
- **Image Picker**: Capture and upload images for visits and documents
- **Document Management**: Upload and manage documents for bookings and holds
- **reCAPTCHA Enterprise**: Bot protection for Android authentication
- **Multi-platform Support**: Android, iOS, and Web with platform-specific optimizations
- **Environment Configuration**: Support for dev and prod environments

## 🛠️ Tech Stack

### Core Framework
- **Flutter**: `^3.8.1` - Cross-platform UI framework
- **Dart**: SDK `^3.8.1`

### State Management & Navigation
- **flutter_riverpod**: `^3.2.0` - State management
- **go_router**: `^17.0.1` - Declarative routing and navigation

### Networking
- **dio**: `^5.9.0` - HTTP client for API calls
- **talker_dio_logger**: `^5.1.12` - Network request logging
- **http_parser**: `^4.1.2` - HTTP message parsing
- **universal_html**: `^2.3.0` - HTML parsing for web

### Firebase Services
- **firebase_core**: `^4.4.0` - Firebase initialization
- **firebase_auth**: `^6.1.4` - Authentication with phone OTP
- **firebase_messaging**: `^16.1.1` - Push notifications
- **firebase_analytics**: `^12.1.1` - Analytics tracking

### Security & Authentication
- **flutter_secure_storage**: `^10.0.0` - Secure token storage
- **recaptcha_enterprise_flutter**: `^18.8.2` - reCAPTCHA Enterprise for Android
- **flutter_dotenv**: `^6.0.0` - Environment configuration

### UI & Utilities
- **intl**: `^0.20.2` - Internationalization and date formatting
- **dotted_border**: `^3.1.0` - UI components
- **image_picker**: `^1.2.1` - Image selection and capture
- **file_picker**: `^10.3.8` - File selection
- **geolocator**: `^14.0.2` - Location services
- **permission_handler**: `^12.0.1` - Runtime permissions
- **webview_flutter**: `^4.13.1` - WebView support
- **url_launcher**: `^6.3.2` - URL launching
- **app_settings**: `^7.0.0` - Open device settings
- **flutter_local_notifications**: `^19.5.0` - Local notifications

### Development Tools
- **flutter_lints**: `^5.0.0` - Linting rules
- **build_runner**: `^2.4.14` - Code generation
- **mockito**: `^5.4.5` - Testing mocks

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (>=3.8.1)
- Dart SDK (>=3.8.1)
- Android Studio / Xcode (for mobile development)
- Firebase project setup
- Environment configuration files

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd high_fly
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up environment files**
   
   Environment files are not committed to git. Copy the examples and fill in your values:
   ```bash
   cp assets/env/.env.dev.example assets/env/.env.dev
   cp assets/env/.env.prod.example assets/env/.env.prod
   ```

4. **Firebase Setup**
   
   - **Android**: 
     - Place `google-services.json` in `android/app/`
     - Configure reCAPTCHA Enterprise for phone authentication (see `FIREBASE_AUTH_SETUP.md`)
   - **iOS**: 
     - Configure Firebase in `ios/Runner/Info.plist`
     - Run `pod install` in the `ios/` directory
     - Firebase Auth handles reCAPTCHA internally on iOS
   - **Web**: 
     - Firebase configuration is handled in `web/index.html`
     - See `firebase_web_setup.md` for detailed setup

5. **Run the application**
   ```bash
   # Development
   flutter run --dart-define=env=dev
   
   # Production
   flutter run --dart-define=env=prod
   ```

## 📁 Project Structure

```
lib/
├── config/              # Configuration files
│   ├── network/        # API client and constants
│   ├── routes.dart     # Navigation configuration
│   └── theme.dart      # App theming
├── data/               # Data layer
│   ├── models/         # Data models
│   │   ├── request_models/    # API request models
│   │   └── response_models/   # API response models
│   └── repository/     # API repositories
├── module/             # Feature modules
│   ├── screens/       # Screen widgets
│   │   ├── authentication/
│   │   ├── dashboard/
│   │   ├── visitors/
│   │   ├── Booking/
│   │   ├── bookings/
│   │   ├── holds/
│   │   └── profile/
│   └── widgets/       # Reusable widgets
└── utils/             # Utility functions
```

## 🏗️ Building

### Android
```bash
# Build APK
flutter build apk --release --dart-define=env=prod

# Build App Bundle (for Play Store)
flutter build appbundle --release --dart-define=env=prod

# Or use the provided scripts
./build_prod_apk.sh
./build_prod_bundle.sh
```

### iOS
```bash
flutter build ios --release --dart-define=env=prod
```

### Web
```bash
flutter build web --release --dart-define=env=prod

# Or use the provided script
./build_web.sh
```

### Deployment Scripts
The project includes several deployment scripts:
- `build_prod_apk.sh` - Build production APK
- `build_prod_bundle.sh` - Build production app bundle
- `build_web.sh` - Build web application
- `deploy_firebase.sh` - Deploy to Firebase Hosting
- `deploy_web.sh` - Deploy web application
- `clean_rebuild.sh` - Clean and rebuild the project

## 🧪 Testing

The project includes unit and widget tests. Run tests with:

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/profile_screen_test.dart
```

### Test Files
- `add_visit_dialog_test.dart` - Visit dialog widget tests
- `profile_screen_test.dart` - Profile screen tests
- `visit_detail_screen_test.dart` - Visit detail tests
- `mobile_side_menu_drawer_test.dart` - Navigation drawer tests

## 📱 Platform-Specific Setup

### Android
- Minimum SDK: Configured in `android/app/build.gradle.kts`
- Permissions: Defined in `android/app/src/main/AndroidManifest.xml`
- Firebase: `google-services.json` required

### iOS
- Minimum iOS version: Configured in `ios/Podfile`
- Permissions: Defined in `ios/Runner/Info.plist`
- Firebase: Run `pod install` in `ios/` directory

### Web
- Firebase configuration in `web/index.html`
- CORS configuration may be required for API calls (see `CORS_WEB_FIX.md`)
- Web-specific error handling implemented
- Terms and conditions page available at `/terms_and_conditions.html`

## 🔐 Environment Configuration

The app supports multiple environments (dev/prod) using `flutter_dotenv`. Set the environment using:

```bash
flutter run --dart-define=env=dev
```

Environment files should be placed in `assets/env/` with the following structure:
- `ENVIRONMENT`: Environment name (dev/prod)
- `BASE_URL`: API base URL

## 📚 Documentation

Additional documentation files:
- `FIREBASE_AUTH_SETUP.md` - Firebase authentication setup guide
- `FCM_IMPLEMENTATION.md` - Firebase Cloud Messaging implementation
- `NOTIFICATION_PERMISSIONS.md` - Notification permissions guide
- `NOTIFICATION_FIX_GUIDE.md` - Notification troubleshooting guide
- `TESTING_GUIDE.md` - Testing guidelines
- `IOS_PHONE_AUTH_FIX.md` - iOS phone authentication fixes
- `FIREBASE_IOS_FIX.md` - iOS Firebase configuration fixes
- `FIREBASE_IOS_FIX_SUMMARY.md` - iOS Firebase fix summary
- `FIREBASE_CONFIG_FIX.md` - Firebase configuration troubleshooting
- `FIREBASE_HOSTING.md` - Firebase Hosting deployment guide
- `DEPLOYMENT_GUIDE.md` - General deployment instructions
- `CORS_WEB_FIX.md` - CORS issues resolution for web
- `CUSTOM_DOMAIN_SETUP.md` - Custom domain configuration
- `DEBUG_FIREBASE.md` - Firebase debugging guide
- `firebase_web_setup.md` - Firebase web setup instructions
- `TERMS_AND_CONDITIONS.md` - Application terms and conditions

## 🚀 Quick Start Scripts

### Development
```bash
# Run in development mode
flutter run --dart-define=env=dev

# Run on specific device
flutter run -d <device-id> --dart-define=env=dev
```

### Production
```bash
# Run in production mode
flutter run --dart-define=env=prod

# Build for production
./build_prod_apk.sh      # Android APK
./build_prod_bundle.sh   # Android Bundle
./build_web.sh           # Web
```

### Utilities
```bash
# Clean and rebuild
./clean_rebuild.sh

# Update Flutter
./update_flutter.sh

# Get SHA fingerprints (for Firebase)
./get_sha_fingerprints.sh
```

## 🤝 Contributing

1. Create a feature branch from `features/update_ui_merge_code`
2. Make your changes
3. Write/update tests as needed
4. Ensure all tests pass
5. Submit a pull request

## 📄 License

[Add your license information here]

## 👥 Team

[Add team information here]

## 📞 Support

For issues and questions, please [create an issue](link-to-issues) or contact the development team.

---

**Note**: Make sure to configure Firebase and environment variables before running the application. Refer to the documentation files for detailed setup instructions.
