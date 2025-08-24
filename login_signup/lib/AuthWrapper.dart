import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'home_page.dart';            // login/welcome/signup entry
import 'sliding_auth_page.dart';    // sliding auth UI
import 'profile_page.dart';         // <- your new post-login screen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Robot Vacuum App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: AuthWrapper(),
      routes: {
        '/home': (_) => HomePage(),
        '/auth': (_) => SlidingAuthPage(),
        '/profile': (_) => const ProfilePage(), // optional route
        // other routes...
      },
    );
  }
}

// Determines which screen to show based on authentication state
class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == null) {
          return HomePage();
        }

        return const ProfilePage(); // <--- replaced ModePage
      },
    );
  }
}
