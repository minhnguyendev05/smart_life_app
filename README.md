# SmartLife App

SmartLife is a Flutter mobile app for students with learning planner, finance tracking,
notes, community chat, maps, smart notifications, and AI assistant.

## Implemented Integrations

- Firebase Core + Email/Password Auth + Firestore realtime chat + FCM foreground/background open-route
- Google Maps + GPS (geolocator + map markers)
- AI assistant with LLM API (when key is provided) and offline rule-based fallback

## Setup

### 1. Install packages

Run:

flutter pub get

### 2. Firebase setup

FlutterFire is already configured for project:

smart-life-17183

Generated with command:

dart pub global run flutterfire_cli:flutterfire configure --project=smart-life-17183 --platforms=android,ios --android-package-name=com.example.smart_life_app --ios-bundle-id=com.example.smartLifeApp --yes

Generated files:

- lib/firebase_options.dart
android/app/google-services.json
ios/Runner/GoogleService-Info.plist

You only need to ensure your Firebase console has Auth/Firestore/FCM enabled.

### 3. Google Maps setup

Add your key in `android/local.properties`:

MAPS_API_KEY=YOUR_ANDROID_MAPS_KEY

This key is read by Gradle and injected into Android manifest placeholder.

### 4. LLM setup (optional)

Pass runtime defines when running app:

flutter run --dart-define=LLM_API_KEY=YOUR_KEY --dart-define=LLM_MODEL=gpt-4o-mini --dart-define=LLM_ENDPOINT=https://api.openai.com/v1/chat/completions

If not provided, assistant automatically falls back to local rule-based logic.

### 5. Web support setup

Firebase Web app is configured via FlutterFire (`lib/firebase_options.dart`).

For FCM on web, pass your VAPID key at runtime:

flutter run -d chrome --dart-define=FCM_WEB_VAPID_KEY=YOUR_VAPID_KEY --dart-define=LLM_API_KEY=YOUR_KEY

Notes for web:

- Auth Email/Password works on web. Ensure `localhost` is in Firebase Authentication authorized domains.
- Map screen on web uses OpenStreetMap fallback (no Google Maps key required on web path).
- Background web push uses `web/firebase-messaging-sw.js`.

### 6. Quick run commands

Mobile (Android):

flutter run -d android --dart-define=LLM_API_KEY=YOUR_KEY

Web (Chrome):

flutter run -d chrome --dart-define=FCM_WEB_VAPID_KEY=YOUR_VAPID_KEY --dart-define=LLM_API_KEY=YOUR_KEY

## Notes

- Firebase and LLM are implemented with safe fallback. App still runs even if keys/config are missing.
- Map screen requires location permission from user.
- Push notifications support foreground notice and click-to-route flow (`route` in FCM data).
