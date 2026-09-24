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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAbeX_rEXBEyJlCOx4W0SdPBBAdUvyI3Es',
    appId: '1:1084970177493:web:b55c28403ac6555e32635c',
    messagingSenderId: '1084970177493',
    projectId: 'cesa-dues-9a267',
    authDomain: 'cesa-dues-9a267.firebaseapp.com',
    storageBucket: 'cesa-dues-9a267.firebasestorage.app',
    measurementId: 'G-8PSCP11KHC',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBPAZXJG3cGq1vC68YtQJvj_25_lKJNT6k',
    appId: '1:1084970177493:android:0122550bf852e6f732635c',
    messagingSenderId: '1084970177493',
    projectId: 'cesa-dues-9a267',
    storageBucket: 'cesa-dues-9a267.firebasestorage.app',
  );
}
