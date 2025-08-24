import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ManualModePage extends StatefulWidget {
  const ManualModePage({Key? key}) : super(key: key);

  @override
  _ManualModePageState createState() => _ManualModePageState();
}

class _ManualModePageState extends State<ManualModePage> {
  final String _baseUrl = 'http://192.168.158.48'; // Replace with your ESP32 IP
  double _speed = 0.5;

  Future<void> _sendCommand(String cmd) async {
    final uri = Uri.parse('$_baseUrl/control?cmd=$cmd&speed=${_speed.toStringAsFixed(2)}');
    try {
      final resp = await http.get(uri).timeout(const Duration(seconds: 3));
      if (resp.statusCode == 200) {
        debugPrint('Command "$cmd" sent successfully');
      } else {
        debugPrint('ESP32 error: ${resp.statusCode}');
      }
    } catch (e) {
      debugPrint('Error sending command: $e');
    }
  }

  Widget _arrowButton(double angle, String cmd) {
    return InkWell(
      onTap: () => _sendCommand(cmd),
      borderRadius: BorderRadius.circular(50),
      child: Container(
        width: 60,
        height: 60,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Center(
          child: Transform.rotate(
            angle: angle,
            child: const Icon(Icons.arrow_upward, size: 28),
          ),
        ),
      ),
    );
  }

  Widget _stopButton() {
    return InkWell(
      onTap: () => _sendCommand('stop'),
      borderRadius: BorderRadius.circular(50),
      child: Container(
        width: 60,
        height: 60,
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
        ),
        child: const Center(
          child: Icon(Icons.stop, size: 28, color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manual Mode'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Press the buttons to move the robot',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 24),

            // Direction Control Section
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text('Direction Control', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 240,
                      child: GridView.count(
                        shrinkWrap: true,
                        crossAxisCount: 3,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        children: [
                          _arrowButton(-pi / 4, 'forward_left'),
                          _arrowButton(0, 'forward'),
                          _arrowButton(pi / 4, 'forward_right'),
                          _arrowButton(-pi / 2, 'left'),
                          _stopButton(),
                          _arrowButton(pi / 2, 'right'),
                          _arrowButton(-3 * pi / 4, 'backward_left'),
                          _arrowButton(pi, 'backward'),
                          _arrowButton(3 * pi / 4, 'backward_right'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Speed Control Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Speed', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Row(
                  children: const [
                    Text('Slow'),
                    Spacer(),
                    Text('Fast'),
                  ],
                ),
                Slider(
                  value: _speed,
                  min: 0.0,
                  max: 1.0,
                  divisions: 20,
                  label: _speed <= 0.33
                      ? 'Slow'
                      : _speed >= 0.66
                      ? 'Fast'
                      : 'Medium',
                  onChanged: (v) {
                    setState(() => _speed = v);
                    debugPrint('Speed changed to ${_speed.toStringAsFixed(2)}');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
