import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DailySummaryScreen extends StatefulWidget {
  const DailySummaryScreen({super.key});

  @override
  State<DailySummaryScreen> createState() => _DailySummaryScreenState();
}

class _DailySummaryScreenState extends State<DailySummaryScreen> {
  Map<String, List<Map<String, dynamic>>> _groupedReadings = {};
  bool _isLoading = true;

  // IMPORTANT: Paste your exact Google Apps Script URL here again
  final String webAppUrl = "https://script.google.com/macros/s/AKfycbxyd30kmNaKX-BzRx187Rf7Si4hGgA9qdIxUgvUOw9xOW0letGpOCVTxpH2en9ALAXo4A/exec"; 

  @override
  void initState() {
    super.initState();
    _fetchAndGroupCloudReadings();
  }

  Future<void> _fetchAndGroupCloudReadings() async {
    try {
      final response = await http.get(Uri.parse(webAppUrl));
      if (response.statusCode == 200) {
        List<dynamic> decoded = jsonDecode(response.body);
        
        Map<String, List<Map<String, dynamic>>> grouped = {};

        for (var item in decoded) {
          Map<String, dynamic> reading = item as Map<String, dynamic>;
          // Assuming the date is stored in a format like "DD-MM-YYYY"
          String date = reading['date']?.toString() ?? 'Unknown Date';
          
          if (!grouped.containsKey(date)) {
            grouped[date] = [];
          }
          grouped[date]!.add(reading);
        }

        setState(() {
          _groupedReadings = grouped;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching summary data: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Daily Summary", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E3A8A),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: "Refresh Summary",
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchAndGroupCloudReadings();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _groupedReadings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.insert_chart_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      const Text(
                        "No data available to summarize yet.",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: _groupedReadings.entries.map((entry) {
                    
                    // Safely parse double values, defaulting to 0.0 if empty/invalid
                    double totalDailyInflow = entry.value.fold(0.0, (sum, item) {
                      return sum + (double.tryParse(item['inflow'].toString()) ?? 0.0);
                    });

                    double totalDailyOutflow = entry.value.fold(0.0, (sum, item) {
                      return sum + (double.tryParse(item['totalOutflow'].toString()) ?? 0.0);
                    });
                    
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.date_range, color: Color(0xFF1E3A8A)),
                                const SizedBox(width: 8),
                                Text(
                                  "Date: ${entry.key}", 
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E3A8A)),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Total Hourly Readings:", style: TextStyle(fontSize: 14)),
                                Text("${entry.value.length}", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("Total Daily Outflow:", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                                  Text("${totalDailyOutflow.toStringAsFixed(2)} m³/s", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
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
                                  const Text("Total Daily Inflow:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                  Text("${totalDailyInflow.toStringAsFixed(2)} m³/s", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
    );
  }
}