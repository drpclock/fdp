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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBBWmbMmL8pnVN_cbzbZZ5bX9SwCsnQ3cI',
    appId: '1:155793524909:web:225b459f6aeb1763729e24',
    messagingSenderId: '155793524909',
    projectId: 'dpclock-f212e',
    authDomain: 'dpclock-f212e.firebaseapp.com',
    databaseURL: 'https://dpclock-f212e-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'dpclock-f212e.firebasestorage.app',
    measurementId: 'G-J76TYJLTN2',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB10MaK_xD8KzaDfOpfTs18FqseiCK7zcA',
    appId: '1:155793524909:android:bb76b8d12645944a729e24',
    messagingSenderId: '155793524909',
    projectId: 'dpclock-f212e',
    databaseURL: 'https://dpclock-f212e-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'dpclock-f212e.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAH7iqA0785FPysgngElQg50TrTS4ChLH4',
    appId: '1:155793524909:ios:28bc97b244bc4154729e24',
    messagingSenderId: '155793524909',
    projectId: 'dpclock-f212e',
    databaseURL: 'https://dpclock-f212e-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'dpclock-f212e.firebasestorage.app',
    iosBundleId: 'com.example.dpclock',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAH7iqA0785FPysgngElQg50TrTS4ChLH4',
    appId: '1:155793524909:ios:28bc97b244bc4154729e24',
    messagingSenderId: '155793524909',
    projectId: 'dpclock-f212e',
    databaseURL: 'https://dpclock-f212e-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'dpclock-f212e.firebasestorage.app',
    iosBundleId: 'com.example.dpclock',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBBWmbMmL8pnVN_cbzbZZ5bX9SwCsnQ3cI',
    appId: '1:155793524909:web:96ff4f624090b13a729e24',
    messagingSenderId: '155793524909',
    projectId: 'dpclock-f212e',
    authDomain: 'dpclock-f212e.firebaseapp.com',
    databaseURL: 'https://dpclock-f212e-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'dpclock-f212e.firebasestorage.app',
    measurementId: 'G-K8NKJBJ6VY',
  );

} 