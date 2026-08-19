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
      SnackBar(
        content: const Text("Reading deleted successfully"),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
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
      SnackBar(
        content: const Text("All saved history cleared"),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Saved Hourly Readings", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E3A8A),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Clear All text button for explicit web visibility
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
            label: const Text("Clear All", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            onPressed: () {
              if (_savedReadings.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("No history to clear!")),
                );
                return;
              }
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: const Text("Clear All History"),
                  content: const Text("Are you sure you want to delete all saved hourly readings?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _clearAllHistory();
                      },
                      child: const Text("Delete All"),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _savedReadings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_toggle_off, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      const Text(
                        "No saved readings found yet.\nGo to calculator and press 'SAVE READING'.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 16, color: Color(0xFF1E3A8A)),
                                    const SizedBox(width: 6),
                                    Text(
                                      "${reading['date']}",
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.blue.shade200),
                                      ),
                                      child: Text(
                                        "⏰ ${reading['time']} Hrs",
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), fontSize: 13),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Visible Text/Icon Delete Button for Web & Mobile
                                    InkWell(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                            title: const Text("Delete Reading"),
                                            content: Text("Delete reading for ${reading['date']} at ${reading['time']}?"),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text("Cancel"),
                                              ),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red.shade700,
                                                  foregroundColor: Colors.white,
                                                ),
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  _deleteSingleReading(index);
                                                },
                                                child: const Text("Delete"),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: Colors.red.shade200),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete_outline, color: Colors.red.shade700, size: 16),
                                            const SizedBox(width: 4),
                                            Text(
                                              "Delete",
                                              style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold, fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Current Level: ${reading['currentLevel']} m", style: const TextStyle(fontSize: 13)),
                                Text("Avg Load: ${reading['avgLoad']} MW", style: const TextStyle(fontSize: 13)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text("Power House Discharge: ${reading['powerHouseDischarge']} m³/s", style: const TextStyle(fontSize: 13)),
                            const Divider(height: 16),
                            Text("RG-1: ${reading['rg1']} | RG-2: ${reading['rg2']} | RG-3: ${reading['rg3']} m³/s", style: const TextStyle(fontSize: 12, color: Colors.black87)),
                            const SizedBox(height: 4),
                            Text("SFT-1: ${reading['sft1']} | SFT-2: ${reading['sft2']} | E-Flow: ${reading['eflow']} | FDRG: ${reading['fdrg']} m³/s", style: const TextStyle(fontSize: 12, color: Colors.black87)),
                            const Divider(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Barrage Outflow: ${reading['barrageOutflow']} m³/s", style: const TextStyle(fontSize: 13)),
                                Text("Total Outflow: ${reading['totalOutflow']} m³/s", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green.shade200),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Inflow Discharge:",
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 13),
                                  ),
                                  Text(
                                    "${reading['inflow']} m³/s",
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 14),
                                  ),
                                ],
                              ),
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