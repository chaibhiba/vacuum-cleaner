import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({Key? key}) : super(key: key);

  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController robotNameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController(); // for re-auth

  void _saveInfo() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'username': nameController.text.trim(),
        'robotName': robotNameController.text.trim(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Information updated')),
      );
    }
  }

  void _deleteAccount() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return;

    final passwordController = TextEditingController();

    // 1️⃣ Prompt for password
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogCtx) {
        // **Here we name the builder parameter `dialogCtx`**
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Enter your password to confirm account deletion:'),
              SizedBox(height: 8),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(labelText: 'Password'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Use the builder’s context to pop the dialog
                Navigator.of(dialogCtx).pop(false);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogCtx).pop(true);
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    // 2️⃣ Re-authenticate and complete deletion...
    try {
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: passwordController.text.trim(),
      );
      await user.reauthenticateWithCredential(cred);
      await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
      await user.delete();
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Account deleted')),
      );
    } on FirebaseAuthException catch (e) {
      String msg;
      if (e.code == 'wrong-password') {
        msg = 'Incorrect password.';
      } else if (e.code == 'requires-recent-login') {
        msg = 'Please log out and log back in before deleting your account.';
      } else {
        msg = e.message ?? 'Error deleting account.';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting account: $e')),
      );
    }
  }



  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        nameController.text = data['username'] ?? '';
        robotNameController.text = data['robotName'] ?? '';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: BackButton(),
        title: Text("Edit profile"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: AssetImage('assets/profile1.png'),
                  ),
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.add, size: 16, color: Colors.blue),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Edit your name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: robotNameController,
              decoration: InputDecoration(
                labelText: 'Make robot name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: _saveInfo,
              child: Text("Save Information"),
              style: ElevatedButton.styleFrom(
                minimumSize: Size.fromHeight(50),
                backgroundColor: Colors.blue,
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _deleteAccount,
              child: Text("Delete Account"),
              style: ElevatedButton.styleFrom(
                minimumSize: Size.fromHeight(50),
                backgroundColor: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
