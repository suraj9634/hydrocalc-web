import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _savedReadings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReadings();
  }

  Future<void> _loadReadings() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> readingsList = prefs.getStringList('hourly_readings') ?? [];

    setState(() {
      _savedReadings = readingsList
          .map((item) => jsonDecode(item) as Map<String, dynamic>)
          .toList()
          .reversed
          .toList();
      _isLoading = false;
    });
  }

  Future<void> _deleteSingleReading(int index) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> readingsList = prefs.getStringList('hourly_readings') ?? [];
    
    List<Map<String, dynamic>> decodedList = readingsList
        .map((item) => jsonDecode(item) as Map<String, dynamic>)
        .toList()
        .reversed
        .toList();

    decodedList.removeAt(index);

    List<String> updatedList = decodedList.reversed
        .map((item) => jsonEncode(item))
        .toList();

    await prefs.setStringList('hourly_readings', updatedList);
    
    setState(() {
      _savedReadings = decodedList;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Reading deleted successfully")),
    );
  }

  Future<void> _clearAllHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('hourly_readings');
    setState(() {
      _savedReadings = [];
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("All saved history cleared")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Saved Hourly Readings"),
        centerTitle: true,
        actions: [
          // 🗑️ Clear All Button always visible in AppBar as a clear text/emoji option
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: InkWell(
              onTap: () {
                if (_savedReadings.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("No history to clear!")),
                  );
                  return;
                }
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Clear All History"),
                    content: const Text("Are you sure you want to delete all saved readings?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _clearAllHistory();
                        },
                        child: const Text("Delete All", style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
              child: const Center(
                child: Text(
                  "🗑️ Clear All",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 245, 53, 5)),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _savedReadings.isEmpty
              ? const Center(
                  child: Text(
                    "No saved readings found yet.\nGo to calculator and press 'SAVE READING'.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _savedReadings.length,
                  itemBuilder: (context, index) {
                    final reading = _savedReadings[index];
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "📅 Date: ${reading['date']}",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      "⏰ ${reading['time']} Hrs",
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 16),
                                    ),
                                    const SizedBox(width: 8),
                                    // 🗑️ Individual Delete Button
                                    InkWell(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text("Delete Reading"),
                                            content: Text("Delete reading for ${reading['date']} at ${reading['time']}?"),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text("Cancel"),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  _deleteSingleReading(index);
                                                },
                                                child: const Text("Delete", style: TextStyle(color: Colors.red)),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        child: const Text(
                                          "🗑️",
                                          style: TextStyle(fontSize: 20),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                           const Divider(height: 20),
        Text("Current Level: ${reading['currentLevel']} m"),
        Text("Average Load: ${reading['avgLoad']} MW"),
        Text("Power House Discharge: ${reading['powerHouseDischarge']} m³/s"),
        const Divider(height: 10),
        Text("RG-1: ${reading['rg1']} | RG-2: ${reading['rg2']} | RG-3: ${reading['rg3']} m³/s"),
        Text("SFT-1: ${reading['sft1']} | SFT-2: ${reading['sft2']} | E-Flow: ${reading['eflow']} | FDRG: ${reading['fdrg']} m³/s"),
        const Divider(height: 10),
        Text("Barrage Outflow: ${reading['barrageOutflow']} m³/s"),
        Text("Total Outflow: ${reading['totalOutflow']} m³/s"),

                            const SizedBox(height: 5),
                            Text(
                              "Inflow Discharge: ${reading['inflow']} m³/s",
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}