# In Bento Cake Kiosk

A Flutter-based kiosk application for ordering custom bento cakes.

## Overview

Brief description of what the application does and its main purpose.

## Features

- Feature 1 (e.g., Browse cake designs)
- Feature 2 (e.g., Customize cake orders)
- Feature 3 (e.g., Process payments)
- Feature 4 (e.g., Order tracking)

## Screenshots

Include screenshots of your app here.

## Prerequisites

- Flutter SDK (version 3.1.0 or higher)
- Dart SDK (version 3.1.0 or higher)
- VSCode or Android Studio (for both web and mobile development)
- Xcode (for ios build, macOS only)

## Installation

1. Clone the repository:
   ```bash
   git clone [repository-url]
   ```

2. Navigate to the project directory:
   ```bash
   cd in-bento-cake-kiosk/in_bento_kiosk
   ```

3. Install dependencies:
   ```bash
   flutter pub get
   ```

4. Configure Firebase:
   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Add your app to the Firebase project
   - Download and add `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Enable Cloud Firestore in your Firebase project

5. Configure ImgBB API:
   - Get your API key from [ImgBB API](https://api.imgbb.com/)
   - Add your API key to the project configuration

6. Run the app:
   ```bash
   flutter run
   ```

## Project Structure

```
assets/
├── cake_layers/     # Contains 3d model of the cake
├── icons/           # Icon that used on the app
└── images/          # screen and menu cake images

lib/
├── screens/         # UI screens
├── utils/           # Utility functions
├── theme/           # Overall theme of the app
└── main.dart        # App entry point
```

## Configuration

### Firebase Setup
- `google-services.json` (Android): Place in `android/app/`
- `GoogleService-Info.plist` (iOS): Place in `ios/Runner/`

### API Keys
- **ImgBB API**: Used for image hosting and storage
- **Firebase**: Used for backend data storage and real-time database

## Usage

Provide instructions on how to use the application.


## Technologies Used

- Flutter SDK (3.1.0+)
- Dart (3.1.0+)
- **Firebase Core** (^2.24.2) - Firebase integration
- **Cloud Firestore** (^4.13.5) - NoSQL cloud database
- **ImgBB API** - Image hosting service
- Google Fonts (^6.2.0)
- Model Viewer Plus (^1.7.0) - 3D model rendering
- FL Chart (^0.66.0) - Charts and graphs
- QR Flutter (^4.1.0) - QR code generation
- Shimmer (^3.0.0) - Loading animations
- Flutter SVG (^2.1.0) - SVG rendering
- URL Launcher (^6.2.6) - External URL handling
- File Picker (^8.1.4) - File selection
- HTTP (^1.6.0) - Network requests
- Intl (^0.18.0) - Internationalization

## Building for Production

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

## Contributing

Guidelines for contributing to the project (if applicable).

## License

Specify your license here.

## Contact

Your contact information or support channels.

## Acknowledgments

Credit any resources, libraries, or individuals who helped.
