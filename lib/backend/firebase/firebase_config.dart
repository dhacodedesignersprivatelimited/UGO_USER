import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

Future initFirebase() async {
  if (kIsWeb) {
    await Firebase.initializeApp(
        options: FirebaseOptions(
            apiKey: "AIzaSyDXCmCA8cMZTuvLa2APiuy22wpzP1Ugy2E",
            authDomain: "ugocabs-789f3.firebaseapp.com",
            projectId: "ugocabs-789f3",
            storageBucket: "ugocabs-789f3.firebasestorage.app",
            messagingSenderId: "987401672169",
            appId: "1:987401672169:web:8086ba89df46507403e778",
            measurementId: "G-4TJNJT99PY"));
  } else {
    await Firebase.initializeApp();
  }
}
