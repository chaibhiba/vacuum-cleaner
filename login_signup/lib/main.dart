import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_page.dart';
import 'profile_page.dart';
import 'robot_status_page.dart';
import 'setting_page.dart';
import 'manual_mode_page.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // No options passed
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Robot Vacuum App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AuthWrapper(),
      routes: {
        '/home': (_) => HomePage(),
        '/profile': (_) => const ProfilePage(),
        '/robot_status': (_) => RobotStatusPage(),
        '/settings': (_) => SettingPage(),
        '/manual': (_) => ManualModePage(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        // If the user *is* signed in, go to the in-app HomePage
        if (snapshot.hasData) {
          return HomePage();
        }
        // If the user is not signed in, show your welcome HomePage
        return HomePage();  // ← also HomePage, not SlidingAuthPage
      },
    );
  }
}

