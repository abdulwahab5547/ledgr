// Firebase project configuration.
//
// PLACEHOLDERS — replace each `PASTE_HERE` value with the matching field
// from Firebase Console → Project Settings → Your apps → Web app SDK
// snippet. Copy/pasting the JS object will give you exactly the names below.
//
// Once filled in, this file can be checked into source control (these
// values aren't secrets — Firebase relies on Firestore Security Rules and
// App Check, not config secrecy). If you ever rotate the project, run
// `flutterfire configure` to regenerate this file automatically.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.android:
        return android;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'DefaultFirebaseOptions has not been configured for '
          '$defaultTargetPlatform — add it here and rerun.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC--xcVM9zrxfGd8BAaDHeoOEXa2EVpb9c',
    appId: '1:933456092668:web:46c8a82ddafa846dde6679',
    messagingSenderId: '933456092668',
    projectId: 'ledgr-38f32',
    authDomain: 'ledgr-38f32.firebaseapp.com',
    storageBucket: 'ledgr-38f32.firebasestorage.app',
    measurementId: 'G-QGJQGDNBEQ',
  );

  // iOS / Android / macOS configs are filled in later when those platforms
  // are wired. For now the web app drives the demo and these stay placeholders.
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'PASTE_HERE_IOS_apiKey',
    appId: 'PASTE_HERE_IOS_appId',
    messagingSenderId: 'PASTE_HERE_IOS_messagingSenderId',
    projectId: 'PASTE_HERE_projectId',
    storageBucket: 'PASTE_HERE_storageBucket',
    iosBundleId: 'PASTE_HERE_IOS_bundleId',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'PASTE_HERE_ANDROID_apiKey',
    appId: 'PASTE_HERE_ANDROID_appId',
    messagingSenderId: 'PASTE_HERE_ANDROID_messagingSenderId',
    projectId: 'PASTE_HERE_projectId',
    storageBucket: 'PASTE_HERE_storageBucket',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'PASTE_HERE_MACOS_apiKey',
    appId: 'PASTE_HERE_MACOS_appId',
    messagingSenderId: 'PASTE_HERE_MACOS_messagingSenderId',
    projectId: 'PASTE_HERE_projectId',
    storageBucket: 'PASTE_HERE_storageBucket',
    iosBundleId: 'PASTE_HERE_MACOS_bundleId',
  );
}
