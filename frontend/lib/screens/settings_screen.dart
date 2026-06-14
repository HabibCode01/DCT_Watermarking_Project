import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Default Values
  double _alphaStrength = 0.5;
  bool _heavyVoting = true;
  int _tilingFactor = 4;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // Load settings from device memory
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _alphaStrength = prefs.getDouble('alphaStrength') ?? 0.5;
      _heavyVoting = prefs.getBool('heavyVoting') ?? true;
      _tilingFactor = prefs.getInt('tilingFactor') ?? 4;
      _isLoading = false;
    });
  }

  // Save settings instantly when changed
  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is double) {
      await prefs.setDouble(key, value);
    } else if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pro Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Algorithm Configuration', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          ListTile(
            leading: const Icon(Icons.tune),
            title: const Text('Payload Strength (Alpha)'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current: ${_alphaStrength.toStringAsFixed(2)} (Higher = More visible, More robust)'),
                Slider(
                  value: _alphaStrength,
                  min: 0.1,
                  max: 1.0,
                  divisions: 9,
                  activeColor: Colors.indigo,
                  onChanged: (val) {
                    setState(() => _alphaStrength = val);
                    _saveSetting('alphaStrength', val);
                  },
                ),
              ],
            ),
          ),
          const Divider(),
          SwitchListTile(
            activeColor: Colors.indigo,
            secondary: const Icon(Icons.calculate),
            title: const Text('Heavy Majority Voting'),
            subtitle: const Text('Increases extraction time but survives severe cropping.'),
            value: _heavyVoting,
            onChanged: (bool value) {
              setState(() => _heavyVoting = value);
              _saveSetting('heavyVoting', value);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.layers),
            title: const Text('Redundant Tiling Factor'),
            subtitle: const Text('How many times the logo is duplicated across the image.'),
            trailing: DropdownButton<int>(
              value: _tilingFactor,
              items: const [
                DropdownMenuItem(value: 2, child: Text('2x Tiling')),
                DropdownMenuItem(value: 4, child: Text('4x Tiling')),
                DropdownMenuItem(value: 8, child: Text('8x Tiling')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _tilingFactor = val);
                  _saveSetting('tilingFactor', val);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}