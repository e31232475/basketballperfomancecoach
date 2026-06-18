import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

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
          'DefaultFirebaseOptions are only configured for web and Android.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC__wtCINygXd4zLtx5e_jVjZsL2WZqJDY',
    appId: '1:316813096816:android:51136db55b01a400eb41b5',
    messagingSenderId: '316813096816',
    projectId: 'basketballperformancecoa-feaf6',
    authDomain: 'basketballperformancecoa-feaf6.firebaseapp.com',
    storageBucket: 'basketballperformancecoa-feaf6.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC__wtCINygXd4zLtx5e_jVjZsL2WZqJDY',
    appId: '1:316813096816:android:51136db55b01a400eb41b5',
    messagingSenderId: '316813096816',
    projectId: 'basketballperformancecoa-feaf6',
    storageBucket: 'basketballperformancecoa-feaf6.firebasestorage.app',
  );
}
