import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'splash_screen.dart'; // तुझी पहिली स्क्रीन

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase इनिशिअलाइज करणे
  await Firebase.initializeApp();

  // Firestore लोकल कॅशिंग/पर्सिस्टन्स सेटिंग (फक्त मोबाईलसाठी)
  if (!kIsWeb) {
    try {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    } catch (e) {
      debugPrint('Firestore Settings Error: $e');
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Site Management',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        useMaterial3: true,
      ),
      home: const SplashScreen(), // ॲप सुरु झाल्यावर SplashScreen वर जाईल
    );
  }
}