# Vistarak (HighFly)

A comprehensive real estate management Flutter application that enables property visits, bookings, and visitor management for real estate professionals.

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
- **Push Notifications**: Firebase Cloud Messaging (FCM) integration
- **Analytics**: Firebase Analytics for user behavior tracking
- **Location Services**: Geolocation for visit tracking
- **Image Picker**: Capture and upload images for visits
- **Multi-platform Support**: Android, iOS, and Web

## 🛠️ Tech Stack

### Core Framework
- **Flutter**: `^3.8.1` - Cross-platform UI framework
- **Dart**: SDK `^3.8.1`

### State Management & Navigation
- **flutter_riverpod**: `^3.0.0` - State management
- **go_router**: `^16.2.2` - Declarative routing and navigation

### Networking
- **dio**: `^5.9.0` - HTTP client for API calls
- **talker_dio_logger**: `^5.0.1` - Network request logging

### Firebase Services
- **firebase_core**: `^3.8.0` - Firebase initialization
- **firebase_auth**: `^5.3.3` - Authentication
- **firebase_messaging**: `^15.1.5` - Push notifications
- **firebase_analytics**: `^11.3.3` - Analytics

### Storage & Security
- **flutter_secure_storage**: `^9.2.4` - Secure token storage
- **flutter_dotenv**: `^6.0.0` - Environment configuration

### UI & Utilities
- **intl**: `^0.20.2` - Internationalization and date formatting
- **dotted_border**: `^3.1.0` - UI components
- **image_picker**: `^1.0.4` - Image selection
- **file_picker**: `^8.0.0+1` - File selection
- **geolocator**: `^13.0.1` - Location services
- **permission_handler**: `^11.3.1` - Runtime permissions
- **webview_flutter**: `^4.9.0` - WebView support
- **url_launcher**: `^6.3.1` - URL launching

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
   
   Create environment configuration files in `assets/env/`:
   - `.env.dev` - Development environment
   - `.env.prod` - Production environment
   
   Example `.env.dev`:
   ```env
   ENVIRONMENT=dev
   BASE_URL=https://your-api-url.com/api/v1/
   ```

4. **Firebase Setup**
   
   - **Android**: Place `google-services.json` in `android/app/`
   - **iOS**: Configure Firebase in `ios/Runner/Info.plist` and run `pod install`
   - **Web**: Firebase configuration is handled in `web/index.html`

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
flutter build apk --release --dart-define=env=prod
# or for app bundle
flutter build appbundle --release --dart-define=env=prod
```

### iOS
```bash
flutter build ios --release --dart-define=env=prod
```

### Web
```bash
flutter build web --release --dart-define=env=prod
```

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
- CORS configuration may be required for API calls

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
- `TESTING_GUIDE.md` - Testing guidelines
- `IOS_PHONE_AUTH_FIX.md` - iOS phone authentication fixes

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
