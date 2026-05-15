// File generated manually from google-services.json.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // ── Android ──────────────────────────────────────────────────────────────
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDkBHOBpLwBGnUOkEIQreH87dX_rRRIWT8',
    appId: '1:1011784425825:android:c80ecf8086d84192a82520',
    messagingSenderId: '1011784425825',
    projectId: 'event-app-928aa',
    storageBucket: 'event-app-928aa.firebasestorage.app',
  );

  // ── Web (placeholder — add your web app config from Firebase Console) ────
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDkBHOBpLwBGnUOkEIQreH87dX_rRRIWT8',
    appId: '1:1011784425825:web:REPLACE_WITH_YOUR_WEB_APP_ID',
    messagingSenderId: '1011784425825',
    projectId: 'event-app-928aa',
    storageBucket: 'event-app-928aa.firebasestorage.app',
    authDomain: 'event-app-928aa.firebaseapp.com',
  );

  // ── iOS (placeholder — add your iOS app config if needed) ────────────────
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDkBHOBpLwBGnUOkEIQreH87dX_rRRIWT8',
    appId: '1:1011784425825:ios:REPLACE_WITH_YOUR_IOS_APP_ID',
    messagingSenderId: '1011784425825',
    projectId: 'event-app-928aa',
    storageBucket: 'event-app-928aa.firebasestorage.app',
    iosBundleId: 'com.example.eventify',
  );

  // ── macOS (placeholder) ───────────────────────────────────────────────────
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDkBHOBpLwBGnUOkEIQreH87dX_rRRIWT8',
    appId: '1:1011784425825:ios:REPLACE_WITH_YOUR_MACOS_APP_ID',
    messagingSenderId: '1011784425825',
    projectId: 'event-app-928aa',
    storageBucket: 'event-app-928aa.firebasestorage.app',
    iosBundleId: 'com.example.eventify',
  );

  // ── Windows (placeholder) ─────────────────────────────────────────────────
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDkBHOBpLwBGnUOkEIQreH87dX_rRRIWT8',
    appId: '1:1011784425825:web:REPLACE_WITH_YOUR_WEB_APP_ID',
    messagingSenderId: '1011784425825',
    projectId: 'event-app-928aa',
    storageBucket: 'event-app-928aa.firebasestorage.app',
    authDomain: 'event-app-928aa.firebaseapp.com',
  );
}
