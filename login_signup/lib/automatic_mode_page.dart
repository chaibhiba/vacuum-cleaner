import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AutomaticModePage extends StatefulWidget {
  const AutomaticModePage({Key? key}) : super(key: key);

  @override
  _AutomaticModePageState createState() => _AutomaticModePageState();
}

class _AutomaticModePageState extends State<AutomaticModePage> {
  final String _baseUrl = 'http://192.168.158.48'; // Your ESP32 IP
  final TextEditingController _timeController = TextEditingController(text: '5');
  double _speed = 0.5;
  bool _isRunning = false;
  String _selectedPattern = 'Square';

  final List<String> _patterns = ['Square', 'Circle', 'Line', 'Random'];

  Future<void> _startCleaning() async {
    final duration = int.tryParse(_timeController.text) ?? 0;
    if (duration < 1 || duration > 120) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a duration between 1 and 120 minutes.')),
      );
      return;
    }

    setState(() => _isRunning = true);

    final uri = Uri.parse(
      '$_baseUrl/automatic?duration=$duration&speed=${_speed.toStringAsFixed(2)}&pattern=$_selectedPattern',
    );

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Automatic cleaning started.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start: $e')),
      );
    } finally {
      setState(() => _isRunning = false);
    }
  }

  @override
  void dispose() {
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Automatic Mode')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Duration input
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.access_time),
                        SizedBox(width: 8),
                        Text("Set Duration", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _timeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Enter a valid duration (minutes)',
                        helperText: 'Duration must be between 1-120 minutes',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Speed slider
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Speed", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Slider(
                      value: _speed,
                      min: 0.0,
                      max: 1.0,
                      divisions: 10,
                      label: _speed < 0.33
                          ? 'Slow'
                          : _speed < 0.66
                          ? 'Medium'
                          : 'Fast',
                      onChanged: (v) => setState(() => _speed = v),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Movement pattern
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Movement Pattern", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      children: _patterns.map((pattern) {
                        final isSelected = _selectedPattern == pattern;
                        return ChoiceChip(
                          label: Text(pattern),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() => _selectedPattern = pattern);
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Start Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isRunning ? null : _startCleaning,
                icon: const Icon(Icons.play_arrow),
                label: _isRunning
                    ? const CircularProgressIndicator()
                    : const Text('Start', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
