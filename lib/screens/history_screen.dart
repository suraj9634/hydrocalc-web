import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  String format2Dec(dynamic value) {
    if (value == null) return "0.00";
    if (value is num) return value.toStringAsFixed(2);
    double? parsed = double.tryParse(value.toString());
    return parsed != null ? parsed.toStringAsFixed(2) : "0.00";
  }

  Future<void> _deleteSingleReading(
      BuildContext context, String docId, String date, String time) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Delete Reading"),
        content: Text("Delete reading for $date at $time from Firestore?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('barrage_readings')
            .doc(docId)
            .delete();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Reading $time deleted successfully"),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to delete reading: $e")),
          );
        }
      }
    }
  }

  Future<void> _clearAllHistory(
      BuildContext context, List<QueryDocumentSnapshot> docs) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Clear All History"),
        content: const Text(
            "Are you sure you want to delete all saved hourly readings from Firestore? This cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete All"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final batch = FirebaseFirestore.instance.batch();
        for (var doc in docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("All saved history cleared"),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to clear history: $e")),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('barrage_readings')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];

        return Scaffold(
          appBar: AppBar(
            title: const Text("Saved Hourly Readings",
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white)),
            centerTitle: true,
            backgroundColor: const Color(0xFF1E3A8A),
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
                label: const Text("Clear All",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                onPressed: docs.isEmpty
                    ? null
                    : () => _clearAllHistory(context, docs),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: snapshot.connectionState == ConnectionState.waiting
              ? const Center(child: CircularProgressIndicator())
              : docs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history_toggle_off,
                              size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          const Text(
                            "No saved readings found in Firestore.\nGo to calculator and press 'SAVE READING'.",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final reading = doc.data() as Map<String, dynamic>;
                        final docId = doc.id;
                        final dateStr = reading['date'] ?? '-';
                        final timeStr = reading['time'] ?? '--:--';

                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today,
                                            size: 16,
                                            color: Color(0xFF1E3A8A)),
                                        const SizedBox(width: 6),
                                        Text(
                                          dateStr,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade50,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: Border.all(
                                                color: Colors.blue.shade200),
                                          ),
                                          child: Text(
                                            "⏰ $timeStr Hrs",
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF1E3A8A),
                                                fontSize: 13),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        InkWell(
                                          onTap: () => _deleteSingleReading(
                                              context,
                                              docId,
                                              dateStr,
                                              timeStr),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.red.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                  color: Colors.red.shade200),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(Icons.delete_outline,
                                                    color: Colors.red.shade700,
                                                    size: 16),
                                                const SizedBox(width: 4),
                                                Text(
                                                  "Delete",
                                                  style: TextStyle(
                                                      color:
                                                          Colors.red.shade700,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12),
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                        "Current Level: ${format2Dec(reading['currentLevel'])} m",
                                        style: const TextStyle(fontSize: 13)),
                                    Text(
                                        "Avg Load: ${format2Dec(reading['avgLoad'])} MW",
                                        style: const TextStyle(fontSize: 13)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                    "Power House Discharge: ${format2Dec(reading['powerHouseDischarge'])} m³/s",
                                    style: const TextStyle(fontSize: 13)),
                                const Divider(height: 16),
                                Text(
                                    "RG-1: ${format2Dec(reading['rg1'])} | RG-2: ${format2Dec(reading['rg2'])} | RG-3: ${format2Dec(reading['rg3'])} m³/s",
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.black87)),
                                const SizedBox(height: 4),
                                Text(
                                    "SFT-1: ${format2Dec(reading['sft1'])} | SFT-2: ${format2Dec(reading['sft2'])} | E-Flow: ${format2Dec(reading['eflow'])} | FDRG: ${format2Dec(reading['fdrg'])} m³/s",
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.black87)),
                                const Divider(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                        "Barrage Outflow: ${format2Dec(reading['barrageOutflow'])} m³/s",
                                        style: const TextStyle(fontSize: 13)),
                                    Text(
                                        "Total Outflow: ${format2Dec(reading['totalOutflow'])} m³/s",
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: Colors.green.shade200),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        "Inflow Discharge:",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                            fontSize: 13),
                                      ),
                                      Text(
                                        "${format2Dec(reading['inflow'])} m³/s",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                            fontSize: 14),
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
      },
    );
  }
}