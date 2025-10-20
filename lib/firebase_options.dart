import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // WEB Configuration (from your Firebase Console)
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDnViokl86JWN2J8KPpO57bgMgAllXUknY',
    authDomain: 'foodfleet-7f4ae.firebaseapp.com',
    projectId: 'foodfleet-7f4ae',
    storageBucket: 'foodfleet-7f4ae.firebasestorage.app',
    messagingSenderId: '478293374891',
    appId: '1:478293374891:web:25c5147673687ffc1644ee',
    measurementId: 'G-7N2HLNQZ7K',
  );

  // ANDROID Configuration (for later when we register Android app)
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDnViokl86JWN2J8KPpO57bgMgAllXUknY',
    appId: '1:478293374891:android:c11cfd87146d4d261644ee', 
    messagingSenderId: '478293374891',
    projectId: 'foodfleet-7f4ae',
    storageBucket: 'foodfleet-7f4ae.firebasestorage.app',
  );

  // iOS Configuration (for later when we register iOS app)
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDnViokl86JWN2J8KPpO57bgMgAllXUknY',
    appId: '1:478293374891:ios:XXXXXX', // We'll update this later
    messagingSenderId: '478293374891',
    projectId: 'foodfleet-7f4ae',
    storageBucket: 'foodfleet-7f4ae.firebasestorage.app',
    iosBundleId: 'com.example.foodfleet',
  );
}