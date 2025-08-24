import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class SlidingAuthPage extends StatefulWidget {
  final bool showLogin;
  SlidingAuthPage({this.showLogin = true});

  @override
  _SlidingAuthPageState createState() => _SlidingAuthPageState();
}

class _SlidingAuthPageState extends State<SlidingAuthPage> {
  late PageController _pageController;
  late bool isLogin;

  // Controllers
  final TextEditingController loginEmailController = TextEditingController();
  final TextEditingController loginPasswordController = TextEditingController();
  final TextEditingController signupUsernameController = TextEditingController();
  final TextEditingController signupEmailController = TextEditingController();
  final TextEditingController signupPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    isLogin = widget.showLogin;
    _pageController = PageController(initialPage: isLogin ? 0 : 1);
  }

  void togglePage() {
    setState(() {
      isLogin = !isLogin;
    });
    _pageController.animateToPage(
      isLogin ? 0 : 1,
      duration: Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  Future<void> login(String email, String password) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      Navigator.pushReplacementNamed(context, '/profile'); // Go to Profile
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
      );
    }
  }

  Future<void> signUp(String email, String password) async {
    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get the current user's UID
      String uid = credential.user!.uid;

      // Save user info to Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'username': signupUsernameController.text.trim(),
        'email': email,
        'robotName': '',
        'photoUrl': '',
        'robotStatus': 'Idle',
      });

      Navigator.pushReplacementNamed(context, '/profile'); // Go to Profile
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signup failed: $e')),
      );
    }
  }



  Widget buildLoginPage() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 60),
            Image.asset('assets/login.png', height: 200),
            SizedBox(height: 20),
            Text("Login", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            TextField(
              controller: loginEmailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: loginPasswordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                login(
                  loginEmailController.text.trim(),
                  loginPasswordController.text.trim(),
                );
              },
              child: Text('Login'),
            ),
            TextButton(
              onPressed: togglePage,
              child: Text("Don't have an account? Sign up"),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSignupPage() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 60),
            Image.asset('assets/signup.png', height: 200),
            SizedBox(height: 20),
            Text("Sign Up", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            TextField(
              controller: signupUsernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: signupEmailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: signupPasswordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                signUp(
                  signupEmailController.text.trim(),
                  signupPasswordController.text.trim(),
                );
              },
              child: Text('Sign Up'),
            ),
            TextButton(
              onPressed: togglePage,
              child: Text("Already have an account? Login"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: NeverScrollableScrollPhysics(),
        children: [
          buildLoginPage(),
          buildSignupPage(),
        ],
      ),
    );
  }
}
