import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:device_apps/device_apps.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LimitAppUsageScreen extends StatefulWidget {
  const LimitAppUsageScreen({super.key});

  @override
  State<LimitAppUsageScreen> createState() => _LimitAppUsageScreenState();
}

class _LimitAppUsageScreenState extends State<LimitAppUsageScreen> {
  List<Application> _apps = [];
  List<Application> _filteredApps = [];
  int _selectedMinutes = 60;

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    final apps = await DeviceApps.getInstalledApplications(
      includeSystemApps: false,
      includeAppIcons: true,
    );

    apps.sort((a, b) => a.appName.toLowerCase().compareTo(b.appName.toLowerCase()));

    setState(() {
      _apps = apps;
      _filteredApps = apps;
    });
  }

  void _showLimitDialog(Application app) async {
    _selectedMinutes = 60;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Set usage limit for "${app.appName}"',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Slider(
                    min: 1,
                    max: 1440,
                    divisions: 1439,
                    label: _formatDuration(_selectedMinutes),
                    value: _selectedMinutes.toDouble(),
                    onChanged: (value) {
                      setModalState(() {
                        _selectedMinutes = value.toInt();
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _formatDuration(_selectedMinutes),
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setInt('limit_${app.packageName}', _selectedMinutes);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text('Save Limit'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}min';
  }

  void _filterApps(String query) {
    setState(() {
      _filteredApps = _apps.where((app) => app.appName.toLowerCase().contains(query.toLowerCase())).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        title: Text(
          'Limit App Usage',
          style: GoogleFonts.playfairDisplay(
            color: Colors.black87,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: _filterApps,
              decoration: InputDecoration(
                hintText: 'Search apps...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _filteredApps.isEmpty
                ? const Center(child: Text('No apps found'))
                : ListView.builder(
                    itemCount: _filteredApps.length,
                    itemBuilder: (context, index) {
                      final app = _filteredApps[index];
                      return ListTile(
                        leading: app is ApplicationWithIcon
                            ? CircleAvatar(
                                backgroundImage: MemoryImage(app.icon),
                              )
                            : const CircleAvatar(child: Icon(Icons.android)),
                        title: Text(app.appName),
                        onTap: () => _showLimitDialog(app),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
