import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class DailySummaryScreen extends StatefulWidget {
  const DailySummaryScreen({super.key});

  @override
  State<DailySummaryScreen> createState() => _DailySummaryScreenState();
}

class _DailySummaryScreenState extends State<DailySummaryScreen> {
  DateTime _selectedDate = DateTime.now();

  String get _formattedDateString {
    return "${_selectedDate.day.toString().padLeft(2, '0')}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.year}";
  }

  // Enforce 2-Decimal Precision Formatter
  String format2Dec(dynamic value) {
    if (value == null) return "0.00";
    if (value is num) return value.toStringAsFixed(2);
    double? parsed = double.tryParse(value.toString());
    return parsed != null ? parsed.toStringAsFixed(2) : "0.00";
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _exportToCsv(List<Map<String, dynamic>> records) {
    if (records.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No records available to export.")),
      );
      return;
    }

    // CSV Headers
    List<List<dynamic>> rows = [
      [
        "Date",
        "Time (Hrs)",
        "Reservoir Level (m)",
        "Desilting Level (m)",
        "Inflow (m3/s)",
        "Barrage Outflow (m3/s)",
        "Powerhouse Discharge (m3/s)",
        "RG-1",
        "RG-2",
        "RG-3",
        "SFT Total",
        "Fishpass Total",
        "E-Flow",
        "FDRG",
        "Avg Load (MW)",
        "Concentration (ppm)",
        "Weather"
      ]
    ];

    // CSV Data Rows
    for (var r in records) {
      double sftTotal = ((r['sft1'] as num?)?.toDouble() ?? 0.0) +
          ((r['sft2'] as num?)?.toDouble() ?? 0.0);
      double fishTotal = ((r['fishpassPipe'] as num?)?.toDouble() ?? 0.0) +
          ((r['fishpassChannel'] as num?)?.toDouble() ?? 0.0);

      rows.add([
        r['date'] ?? _formattedDateString,
        r['time'] ?? "",
        format2Dec(r['currentLevel']),
        format2Dec(r['desiltingLevel']),
        format2Dec(r['inflow']),
        format2Dec(r['barrageOutflow']),
        format2Dec(r['powerHouseDischarge']),
        format2Dec(r['rg1']),
        format2Dec(r['rg2']),
        format2Dec(r['rg3']),
        format2Dec(sftTotal),
        format2Dec(fishTotal),
        format2Dec(r['eflow']),
        format2Dec(r['fdrg']),
        format2Dec(r['avgLoad']),
        format2Dec(r['concentration']),
        r['weather'] ?? "",
      ]);
    }

    // Direct RFC 4180 CSV generation
    String csvData = rows.map((row) {
      return row.map((cell) {
        String val = cell.toString().replaceAll('"', '""');
        return '"$val"';
      }).join(',');
    }).join('\r\n');

    if (kIsWeb) {
      final bytes = utf8.encode(csvData);
      final blob = html.Blob([bytes], 'text/csv');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "Barrage_Log_$_formattedDateString.csv")
        ..click();
      html.Url.revokeObjectUrl(url);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Exported Barrage_Log_$_formattedDateString.csv successfully!"),
        backgroundColor: Colors.green.shade700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Daily Summary & Logs",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('barrage_readings')
            .where('date', isEqualTo: _formattedDateString)
            .snapshots(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? [];
          List<Map<String, dynamic>> records = docs
              .map((d) => d.data() as Map<String, dynamic>)
              .toList();
          records.sort((a, b) => (a['time'] ?? "").compareTo(b['time'] ?? ""));

          return Column(
            children: [
              // Top Action Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Colors.blue.shade50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.event, color: Color(0xFF1E3A8A)),
                        const SizedBox(width: 8),
                        Text(
                          "Date: $_formattedDateString",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: _pickDate,
                          icon: const Icon(Icons.edit_calendar, size: 18),
                          label: const Text("Change Date"),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade700,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: records.isEmpty ? null : () => _exportToCsv(records),
                          icon: const Icon(Icons.file_download, size: 18),
                          label: const Text("Export CSV"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Content View
              if (snapshot.connectionState == ConnectionState.waiting)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else if (records.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_open, size: 60, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          "No readings logged for $_formattedDateString",
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      // 1. KPI Cards
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: _buildKpis(records),
                      ),

                      // 2. 24-Hour Hydrograph Chart
                      _buildHydrograph(records),

                      const SizedBox(height: 12),

                      // 3. Hourly Data Table
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(const Color(0xFF1E3A8A)),
                          headingTextStyle: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                          dataRowMinHeight: 40,
                          dataRowMaxHeight: 48,
                          columns: const [
                            DataColumn(label: Text("Time")),
                            DataColumn(label: Text("Level (m)")),
                            DataColumn(label: Text("Inflow (m³/s)")),
                            DataColumn(label: Text("Outflow (m³/s)")),
                            DataColumn(label: Text("RG Total")),
                            DataColumn(label: Text("Load (MW)")),
                            DataColumn(label: Text("Weather")),
                          ],
                          rows: records.map((record) {
                            double rgTotal =
                                ((record['rg1'] as num?)?.toDouble() ?? 0.0) +
                                    ((record['rg2'] as num?)?.toDouble() ?? 0.0) +
                                    ((record['rg3'] as num?)?.toDouble() ?? 0.0);

                            return DataRow(
                              cells: [
                                DataCell(Text("${record['time']}",
                                    style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataCell(Text(format2Dec(record['currentLevel']))),
                                DataCell(Text(
                                  format2Dec(record['inflow']),
                                  style: const TextStyle(
                                      color: Colors.blue, fontWeight: FontWeight.w600),
                                )),
                                DataCell(Text(format2Dec(record['barrageOutflow']))),
                                DataCell(Text(format2Dec(rgTotal))),
                                DataCell(Text(format2Dec(record['avgLoad']))),
                                DataCell(Text("${record['weather'] ?? '-'}")),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHydrograph(List<Map<String, dynamic>> records) {
    List<FlSpot> inflowSpots = [];
    List<FlSpot> outflowSpots = [];
    List<FlSpot> powerhouseSpots = [];

    for (var r in records) {
      String timeStr = r['time'] ?? "00:00";
      double hour = double.tryParse(timeStr.split(':')[0]) ?? 0.0;

      double inflow = (r['inflow'] is num)
          ? (r['inflow'] as num).toDouble()
          : (double.tryParse("${r['inflow']}") ?? 0.0);

      double outflow = (r['barrageOutflow'] is num)
          ? (r['barrageOutflow'] as num).toDouble()
          : (double.tryParse("${r['barrageOutflow']}") ?? 0.0);

      double powerhouse = (r['powerHouseDischarge'] is num)
          ? (r['powerHouseDischarge'] as num).toDouble()
          : (double.tryParse("${r['powerHouseDischarge']}") ?? 0.0);

      inflowSpots.add(FlSpot(hour, inflow));
      outflowSpots.add(FlSpot(hour, outflow));
      powerhouseSpots.add(FlSpot(hour, powerhouse));
    }

    // Dynamic Upper Y-bound calculation
    double maxY = 10.0;
    for (var s in [...inflowSpots, ...outflowSpots, ...powerhouseSpots]) {
      if (s.y > maxY) maxY = s.y;
    }
    maxY = (maxY * 1.25).ceilToDouble();

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "24-Hour Hydrograph (m³/s)",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A)),
                ),
                Row(
                  children: [
                    _chartLegendIndicator(Colors.blue, "Inflow"),
                    const SizedBox(width: 10),
                    _chartLegendIndicator(Colors.redAccent, "Barrage Outflow"),
                    const SizedBox(width: 10),
                    _chartLegendIndicator(Colors.green, "Powerhouse"),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: 23,
                  minY: 0,
                  maxY: maxY,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval:
                        maxY > 20 ? (maxY / 5).roundToDouble() : 5,
                    verticalInterval: 4,
                    getDrawingHorizontalLine: (val) =>
                        FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                    getDrawingVerticalLine: (val) =>
                        FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 26,
                        interval: 4,
                        getTitlesWidget: (val, meta) => Text(
                          "${val.toInt().toString().padLeft(2, '0')}:00",
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade700),
                        ),
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                        getTitlesWidget: (val, meta) => Text(
                          val.toStringAsFixed(0),
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade700),
                        ),
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: inflowSpots,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                    ),
                    LineChartBarData(
                      spots: outflowSpots,
                      isCurved: true,
                      color: Colors.redAccent,
                      barWidth: 2.5,
                      dotData: const FlDotData(show: true),
                    ),
                    LineChartBarData(
                      spots: powerhouseSpots,
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 2,
                      dashArray: [4, 4],
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chartLegendIndicator(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(text,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildKpis(List<Map<String, dynamic>> records) {
    double maxInflow = 0.0;
    double sumInflow = 0.0;
    double sumBarrageOutflow = 0.0;
    double sumLoad = 0.0;

    for (var r in records) {
      double inflow = (r['inflow'] is num)
          ? (r['inflow'] as num).toDouble()
          : (double.tryParse("${r['inflow']}") ?? 0.0);
      double outflow = (r['barrageOutflow'] is num)
          ? (r['barrageOutflow'] as num).toDouble()
          : (double.tryParse("${r['barrageOutflow']}") ?? 0.0);
      double load = (r['avgLoad'] is num)
          ? (r['avgLoad'] as num).toDouble()
          : (double.tryParse("${r['avgLoad']}") ?? 0.0);

      if (inflow > maxInflow) maxInflow = inflow;
      sumInflow += inflow;
      sumBarrageOutflow += outflow;
      sumLoad += load;
    }

    double avgInflow = records.isNotEmpty ? (sumInflow / records.length) : 0.0;
    double avgLoad = records.isNotEmpty ? (sumLoad / records.length) : 0.0;

    return Row(
      children: [
        _buildKpiCard("Peak Inflow", "${format2Dec(maxInflow)} m³/s", Colors.orange),
        const SizedBox(width: 8),
        _buildKpiCard("Avg Inflow", "${format2Dec(avgInflow)} m³/s", Colors.blue),
        const SizedBox(width: 8),
        _buildKpiCard("Avg Gen Load", "${format2Dec(avgLoad)} MW", Colors.green),
      ],
    );
  }

  Widget _buildKpiCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}