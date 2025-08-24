import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RobotStatusPage extends StatefulWidget {
  const RobotStatusPage({Key? key}) : super(key: key);

  @override
  _RobotStatusPageState createState() => _RobotStatusPageState();
}

class _RobotStatusPageState extends State<RobotStatusPage> {
  final String _statusUrl = 'http://192.168.158.48/status'; // ESP32 IP

  String status = "Unknown";
  int cleanedArea = 0;
  int distance = 0;
  String _lastFirebaseStatus = "Unknown"; // Track last status sent to Firebase

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    fetchStatus();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => fetchStatus());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> fetchStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final response = await http.get(Uri.parse(_statusUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        String newStatus = data['status'] ?? 'Unknown';
        String firebaseStatus = newStatus;

        if (newStatus == "Stopped") {
          firebaseStatus = "Idle";
        }

        setState(() {
          status = newStatus;
          cleanedArea = (data['cleaned_area'] as num?)?.toInt() ?? 0;
          distance = (data['distance'] as num?)?.toInt() ?? 0;
        });

        if (firebaseStatus != _lastFirebaseStatus) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({
            'robotStatus': firebaseStatus,
          });
          _lastFirebaseStatus = firebaseStatus;
          print(" Firebase updated: $firebaseStatus");
        }
      }
    } catch (e) {
      print("Error fetching status: $e");
    }
  }

  Widget buildCard({
    required IconData icon,
    required String title,
    required String value,
    bool isLarge = false,
  }) {
    return Container(
      width: isLarge ? 200 : 150,
      height: isLarge ? 200 : 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 8,
              offset: const Offset(2, 4)
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.blueAccent, size: isLarge ? 40 : 30),
          const SizedBox(height: 10),
          Text(title,
              style: TextStyle(
                  fontSize: isLarge ? 20 : 16,
                  fontWeight: FontWeight.w600
              )),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: isLarge ? 18 : 14,
                  color: Colors.grey[700]
              )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String displayStatus = status == "Stopped" ? "Complete Cleaning" : status;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Robot Status'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              buildCard(
                icon: Icons.info_outline,
                title: "Statut",
                value: displayStatus,
                isLarge: true,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  buildCard(
                    icon: Icons.cleaning_services_outlined,
                    title: "cleaned Area",
                    value: "$cleanedArea cm²",
                  ),
                  const SizedBox(width: 16),
                  buildCard(
                    icon: Icons.social_distance,
                    title: "Distance",
                    value: "$distance cm",
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}