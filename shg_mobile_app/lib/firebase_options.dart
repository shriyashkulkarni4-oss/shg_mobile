// File generated based on Firebase project "trustledger-a1ca1"
// This file is auto-configured for both Android and Web platforms.

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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for iOS - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macOS - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        return web; // Use web config for Windows desktop too
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for Linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  /// Web Firebase configuration (also used for Windows desktop)
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAW1A8-uiE4oKYcNvopW8_nY8T-mymvoHo',
    authDomain: 'trustledger-a1ca1.firebaseapp.com',
    projectId: 'trustledger-a1ca1',
    storageBucket: 'trustledger-a1ca1.firebasestorage.app',
    messagingSenderId: '696142795555',
    appId: '1:696142795555:web:b709f8d0b8e5593ffd3296',
  );

  /// Android Firebase configuration (from google-services.json)
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDXWsedVzbxxbJy0YZ0pCG_otV9O1U_B8g',
    appId: '1:696142795555:android:7cbb8d678b389d38fd3296',
    messagingSenderId: '696142795555',
    projectId: 'trustledger-a1ca1',
    storageBucket: 'trustledger-a1ca1.firebasestorage.app',
  );
}
