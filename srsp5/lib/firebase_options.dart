// File generated from Firebase project srsp5-46432 (FlutterFire format).
// ignore_for_file: type=lint
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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform - '
          'run `flutterfire configure` to add it.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCiYmgzwgWvMgpkoluYgpAsFgCr_MjXKeE',
    appId: '1:559956229005:web:a0809f6eb5d23c0bb1dbc4',
    messagingSenderId: '559956229005',
    projectId: 'srsp5-46432',
    authDomain: 'srsp5-46432.firebaseapp.com',
    storageBucket: 'srsp5-46432.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBs0so87edePkzna5FEv3ikE-b-5mF0h7s',
    appId: '1:559956229005:android:b6724e0e419863fbb1dbc4',
    messagingSenderId: '559956229005',
    projectId: 'srsp5-46432',
    storageBucket: 'srsp5-46432.firebasestorage.app',
  );
}
