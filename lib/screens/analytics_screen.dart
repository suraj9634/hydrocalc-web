import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'hourly_calculator_screen.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  
  // --- Multi-Date State ---
  final Map<String, List<Map<String, dynamic>>> _multiDateData = {};
  List<DateTime> _selectedDates = [DateTime(2026, 8, 19)];
  String _selectedParameter = 'inflow';

  // --- Particular Month Daily Trend State ---
  int _selectedMonthNumber = 8;
  int _selectedMonthYear = 2026;
  final Map<int, double> _dailyAggregatedData = {};
  bool _isDailyMonthLoading = false;

  // --- Multi-Month Comparison State ---
  // Storing items as "MM-YYYY" e.g. "08-2026"
  List<String> _selectedMultiMonths = ['08-2026', '09-2026'];
  final Map<String, Map<int, double>> _multiMonthData = {};
  bool _isMultiMonthLoading = false;

  // --- Multi-Year Comparison State ---
  List<int> _selectedYears = [2025, 2026];
  final Map<int, Map<String, double>> _multiYearData = {};
  bool _isMultiYearLoading = false;

  // --- Monthly / Yearly Single Trends State ---
  int _selectedYear = 2026;
  final Map<String, double> _monthlyAggregatedData = {};
  bool _isMonthlyLoading = false;

  final Map<String, String> _availableParameters = {
    'inflow': 'Inflow Discharge',
    'rg1': 'BRG-1 Discharge',
    'rg2': 'BRG-2 Discharge',
    'rg3': 'BRG-3 Discharge',
    'totalRg': 'Total RG Discharge',
    'sft1': 'SFT G-1',
    'sft2': 'SFT G-2',
    'eflow': 'Total Fishpass Discharge',
    'barrageOutflow': 'Barrage Outflow',
    'powerHouseDischarge': 'HRT/PH Discharge',
    'fdrg': 'FDRG Discharge',
    'avgLoad': 'Average Load (MW)',
  };

  final List<Color> _chartColors = [
    Colors.green,
    Colors.blue,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
    Colors.indigo,
    Colors.amber,
  ];

  final String webAppUrl = "https://script.google.com/macros/s/AKfycbxyd30kmNaKX-BzRx187Rf7Si4hGgA9qdIxUgvUOw9xOW0letGpOCVTxpH2en9ALAXo4A/exec";

  // ignore: strict_top_level_inference
  get $year => null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _fetchAllSelectedDatesData();
    _fetchParticularMonthData();
    _fetchMultiMonthData();
    _fetchMultiYearData();
    _fetchYearlyData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  double _extractParameterValue(Map<String, dynamic> row, String paramKey) {
    if (paramKey == 'totalRg') {
      double r1 = double.tryParse(row['rg1']?.toString() ?? '') ?? 0.0;
      double r2 = double.tryParse(row['rg2']?.toString() ?? '') ?? 0.0;
      double r3 = double.tryParse(row['rg3']?.toString() ?? '') ?? 0.0;
      return r1 + r2 + r3;
    }
    double val = double.tryParse(row[paramKey]?.toString() ?? '') ?? 0.0;
    return val < 0 ? 0.0 : val;
  }

  Future<void> _fetchAllSelectedDatesData() async {
    setState(() => _isLoading = true);
    _multiDateData.clear();
    try {
      for (var date in _selectedDates) {
        String formattedDate = DateFormat('dd-MM-yyyy').format(date);
        final response = await http.get(Uri.parse("$webAppUrl?date=$formattedDate"));
        if (response.statusCode == 200) {
          List<dynamic> decoded = jsonDecode(response.body);
          _multiDateData[formattedDate] = decoded.map((item) => item as Map<String, dynamic>).toList();
        }
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
    setState(() => _isLoading = false);
  }

  Future<void> _fetchParticularMonthData() async {
    setState(() => _isDailyMonthLoading = true);
    _dailyAggregatedData.clear();
    try {
      int daysInMonth = DateTime(_selectedMonthYear, _selectedMonthNumber + 1, 0).day;
      for (int day = 1; day <= daysInMonth; day++) {
        String targetDate = "${day.toString().padLeft(2, '0')}-${_selectedMonthNumber.toString().padLeft(2, '0')}-$_selectedMonthYear";
        final response = await http.get(Uri.parse("$webAppUrl?date=$targetDate"));
        if (response.statusCode == 200) {
          List<dynamic> decoded = jsonDecode(response.body);
          if (decoded.isNotEmpty) {
            double sum = 0;
            int count = 0;
            for (var item in decoded) {
              sum += _extractParameterValue(item, _selectedParameter);
              count++;
            }
            if (count > 0) _dailyAggregatedData[day] = sum / count;
          }
        }
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
    setState(() => _isDailyMonthLoading = false);
  }

  Future<void> _fetchMultiMonthData() async {
    setState(() => _isMultiMonthLoading = true);
    _multiMonthData.clear();
    List<String> monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    try {
      for (String monthYearStr in _selectedMultiMonths) {
        // format expected: "MM-YYYY" e.g. "08-2026"
        List<String> parts = monthYearStr.split('-');
        int mNum = int.parse(parts[0]);
        int year = int.parse(parts[1]);
        String mLabel = monthNames[mNum - 1];

        Map<int, double> monthDays = {};
        int daysInMonth = DateTime(year, mNum + 1, 0).day;

        for (int day = 1; day <= daysInMonth; day++) {
          // ignore: unnecessary_brace_in_string_interps
          String targetDate = "${day.toString().padLeft(2, '0')}-${mNum.toString().padLeft(2, '0')}-${year}";
          final response = await http.get(Uri.parse("$webAppUrl?date=$targetDate"));
          if (response.statusCode == 200) {
            List<dynamic> decoded = jsonDecode(response.body);
            if (decoded.isNotEmpty) {
              double sum = 0;
              int count = 0;
              for (var item in decoded) {
                sum += _extractParameterValue(item, _selectedParameter);
                count++;
              }
              if (count > 0) monthDays[day] = sum / count;
            }
          }
        }
        _multiMonthData["$mLabel $year"] = monthDays;
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
    setState(() => _isMultiMonthLoading = false);
  }

  Future<void> _fetchMultiYearData() async {
    setState(() => _isMultiYearLoading = true);
    _multiYearData.clear();
    List<String> months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    try {
      for (int year in _selectedYears) {
        Map<String, double> yearMonths = {};
        for (int i = 0; i < months.length; i++) {
          String sampleDate = "15-${(i + 1).toString().padLeft(2, '0')}-$year";
          final response = await http.get(Uri.parse("$webAppUrl?date=$sampleDate"));
          if (response.statusCode == 200) {
            List<dynamic> decoded = jsonDecode(response.body);
            if (decoded.isNotEmpty) {
              double sum = 0;
              int count = 0;
              for (var item in decoded) {
                sum += _extractParameterValue(item, _selectedParameter);
                count++;
              }
              if (count > 0) yearMonths[months[i]] = sum / count;
            }
          }
        }
        _multiYearData[year] = yearMonths;
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
    setState(() => _isMultiYearLoading = false);
  }

  Future<void> _fetchYearlyData() async {
    setState(() => _isMonthlyLoading = true);
    _monthlyAggregatedData.clear();
    List<String> months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    try {
      for (int i = 0; i < months.length; i++) {
        String sampleDate = "15-${(i + 1).toString().padLeft(2, '0')}-$_selectedYear";
        final response = await http.get(Uri.parse("$webAppUrl?date=$sampleDate"));
        if (response.statusCode == 200) {
          List<dynamic> decoded = jsonDecode(response.body);
          if (decoded.isNotEmpty) {
            double sum = 0;
            int count = 0;
            for (var item in decoded) {
              sum += _extractParameterValue(item, _selectedParameter);
              count++;
            }
            if (count > 0) _monthlyAggregatedData[months[i]] = sum / count;
          }
        }
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
    setState(() => _isMonthlyLoading = false);
  }

  Future<void> _addDateToComparison(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2025, 1, 1),
      lastDate: DateTime(2030, 12, 31),
    );
    if (picked != null) {
      setState(() {
        if (!_selectedDates.any((d) => d.year == picked.year && d.month == picked.month && d.day == picked.day)) {
          _selectedDates.add(picked);
        }
      });
      _fetchAllSelectedDatesData();
    }
  }

  void _removeDate(DateTime date) {
    if (_selectedDates.length > 1) {
      setState(() => _selectedDates.remove(date));
      _fetchAllSelectedDatesData();
    }
  }

  Future<void> _addMonthToComparison(BuildContext context) async {
    int tempMonth = 8;
    int tempYear = 2026;
    List<String> monthNames = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Select Month to Add"),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: tempMonth,
                    decoration: const InputDecoration(labelText: "Month"),
                    items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text(monthNames[i]))),
                    onChanged: (val) => setDialogState(() => tempMonth = val!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: tempYear,
                    decoration: const InputDecoration(labelText: "Year"),
                    items: [2025, 2026, 2027, 2028].map((y) => DropdownMenuItem(value: y, child: Text(y.toString()))).toList(),
                    onChanged: (val) => setDialogState(() => tempYear = val!),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                String key = "${tempMonth.toString().padLeft(2, '0')}-$tempYear";
                if (!_selectedMultiMonths.contains(key)) {
                  setState(() => _selectedMultiMonths.add(key));
                  _fetchMultiMonthData();
                }
                Navigator.pop(context);
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  void _removeMultiMonth(String monthKey) {
    if (_selectedMultiMonths.length > 1) {
      setState(() => _selectedMultiMonths.remove(monthKey));
      _fetchMultiMonthData();
    }
  }

  Future<void> _addYearToComparison(BuildContext context) async {
    int tempYear = 2026;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Select Year to Add"),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return DropdownButtonFormField<int>(
                initialValue: tempYear,
                decoration: const InputDecoration(labelText: "Year"),
                items: [2025, 2026, 2027, 2028].map((y) => DropdownMenuItem(value: y, child: Text(y.toString()))).toList(),
                onChanged: (val) => setDialogState(() => tempYear = val!),
              );
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                if (!_selectedYears.contains(tempYear)) {
                  setState(() => _selectedYears.add(tempYear));
                  _fetchMultiYearData();
                }
                Navigator.pop(context);
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  void _removeYear(int year) {
    if (_selectedYears.length > 1) {
      setState(() => _selectedYears.remove(year));
      _fetchMultiYearData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Comprehensive Analytics", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E3A8A),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.tealAccent,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.compare_arrows), text: "Multi-Date"),
            Tab(icon: Icon(Icons.calendar_month), text: "Daily (Month)"),
            Tab(icon: Icon(Icons.date_range), text: "Multi-Month"),
            Tab(icon: Icon(Icons.show_chart), text: "Single Year"),
            Tab(icon: Icon(Icons.trending_up), text: "Multi-Year"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMultiDateView(),
          _buildParticularMonthView(),
          _buildMultiMonthView(),
          _buildMonthlyYearlyView(),
          _buildMultiYearView(),
        ],
      ),
    );
  }

  // --- TAB 1: Multi-Date ---
  Widget _buildMultiDateView() {
    List<LineChartBarData> activeLines = [];
    int colorIndex = 0;

    _multiDateData.forEach((dateStr, rows) {
      Color lineColor = _chartColors[colorIndex % _chartColors.length];
      colorIndex++;
      activeLines.add(
        LineChartBarData(
          spots: rows.asMap().entries.map((entry) {
            return FlSpot(entry.key.toDouble(), _extractParameterValue(entry.value, _selectedParameter));
          }).toList(),
          isCurved: true,
          color: lineColor,
          barWidth: 3,
          dotData: const FlDotData(show: true),
        ),
      );
    });

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMetricDropdown(),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text("Dates: ", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 10),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _selectedDates.map((date) {
                      String dateStr = DateFormat('dd-MM-yyyy').format(date);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Chip(
                          label: Text(dateStr),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () => _removeDate(date),
                          backgroundColor: Colors.blue.shade50,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
                icon: const Icon(Icons.add, size: 18),
                label: const Text("Add Date"),
                onPressed: () => _addDateToComparison(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              icon: const Icon(Icons.edit_calendar, size: 18),
              label: const Text("Fill / Edit Hourly Data"),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const HourlyCalculatorScreen()))
                    .then((_) => _fetchAllSelectedDatesData());
              },
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _multiDateData.isEmpty
                    ? const Center(child: Text("No data found."))
                    : _buildLineChart(activeLines, 23, "Time of Day (Hours)"),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: _multiDateData.keys.toList().asMap().entries.map((entry) {
              return _buildLegendItem(entry.value, _chartColors[entry.key % _chartColors.length]);
            }).toList(),
          ),
        ],
      ),
    );
  }

  // --- TAB 2: Particular Month Daily Trend ---
  Widget _buildParticularMonthView() {
    List<String> monthNames = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    int daysInMonth = DateTime(_selectedMonthYear, _selectedMonthNumber + 1, 0).day;
    List<FlSpot> dailySpots = [];

    for (int day = 1; day <= daysInMonth; day++) {
      dailySpots.add(FlSpot(day.toDouble(), _dailyAggregatedData[day] ?? 0.0));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _selectedMonthNumber,
                  decoration: const InputDecoration(labelText: "Month", border: OutlineInputBorder()),
                  items: List.generate(12, (index) => DropdownMenuItem(value: index + 1, child: Text(monthNames[index]))),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedMonthNumber = val);
                      _fetchParticularMonthData();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _selectedMonthYear,
                  decoration: const InputDecoration(labelText: "Year", border: OutlineInputBorder()),
                  items: [2025, 2026, 2027, 2028].map((y) => DropdownMenuItem(value: y, child: Text(y.toString()))).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedMonthYear = val);
                      _fetchParticularMonthData();
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildMetricDropdown(),
          const SizedBox(height: 20),
          Expanded(
            child: _isDailyMonthLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildLineChart([
                    LineChartBarData(spots: dailySpots, isCurved: true, color: Colors.teal, barWidth: 3, dotData: const FlDotData(show: true))
                  ], daysInMonth.toDouble(), "Days of the Month"),
          ),
        ],
      ),
    );
  }

  // --- TAB 3: Multi-Month Comparison (Updated with Chips & Add Selector) ---
  Widget _buildMultiMonthView() {
    List<String> monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    List<LineChartBarData> activeLines = [];
    int colorIndex = 0;

    _multiMonthData.forEach((monthLabel, dayValues) {
      Color lineColor = _chartColors[colorIndex % _chartColors.length];
      colorIndex++;
      List<FlSpot> spots = [];
      for (int day = 1; day <= 31; day++) {
        spots.add(FlSpot(day.toDouble(), dayValues[day] ?? 0.0));
      }
      activeLines.add(
        LineChartBarData(spots: spots, isCurved: true, color: lineColor, barWidth: 2.5, dotData: const FlDotData(show: false)),
      );
    });

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMetricDropdown(),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text("Months: ", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 10),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _selectedMultiMonths.map((mKey) {
                      List<String> parts = mKey.split('-');
                      String label = "${monthNames[int.parse(parts[0]) - 1]} ${parts[1]}";
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Chip(
                          label: Text(label),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () => _removeMultiMonth(mKey),
                          backgroundColor: Colors.blue.shade50,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
                icon: const Icon(Icons.add, size: 18),
                label: const Text("Add Month"),
                onPressed: () => _addMonthToComparison(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isMultiMonthLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildLineChart(activeLines, 31, "Day of Month"),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: _multiMonthData.keys.toList().asMap().entries.map((entry) {
              return _buildLegendItem(entry.value, _chartColors[entry.key % _chartColors.length]);
            }).toList(),
          ),
        ],
      ),
    );
  }

  // --- TAB 4: Single Year Monthly Trend ---
  Widget _buildMonthlyYearlyView() {
    List<String> months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    List<FlSpot> yearlySpots = [];
    for (int i = 0; i < months.length; i++) {
      yearlySpots.add(FlSpot(i.toDouble(), _monthlyAggregatedData[months[i]] ?? 0.0));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Select Year:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              DropdownButton<int>(
                value: _selectedYear,
                items: [2025, 2026, 2027, 2028].map((y) => DropdownMenuItem(value: y, child: Text(y.toString()))).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedYear = val);
                    _fetchYearlyData();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildMetricDropdown(),
          const SizedBox(height: 20),
          Expanded(
            child: _isMonthlyLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildLineChart([
                    LineChartBarData(spots: yearlySpots, isCurved: true, color: Colors.indigo, barWidth: 3, dotData: const FlDotData(show: true))
                  ], 11, "Months of Year"),
          ),
        ],
      ),
    );
  }

  // --- TAB 5: Multi-Year Comparison (Updated with Chips & Add Selector) ---
  Widget _buildMultiYearView() {
    List<String> months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    List<LineChartBarData> activeLines = [];
    int colorIndex = 0;

    _multiYearData.forEach((year, monthMap) {
      Color lineColor = _chartColors[colorIndex % _chartColors.length];
      colorIndex++;
      List<FlSpot> spots = [];
      for (int i = 0; i < months.length; i++) {
        spots.add(FlSpot(i.toDouble(), monthMap[months[i]] ?? 0.0));
      }
      activeLines.add(
        LineChartBarData(spots: spots, isCurved: true, color: lineColor, barWidth: 3, dotData: const FlDotData(show: true)),
      );
    });

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMetricDropdown(),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text("Years: ", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 10),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _selectedYears.map((year) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Chip(
                          label: Text(year.toString()),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () => _removeYear(year),
                          backgroundColor: Colors.blue.shade50,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
                icon: const Icon(Icons.add, size: 18),
                label: const Text("Add Year"),
                onPressed: () => _addYearToComparison(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isMultiYearLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildLineChart(activeLines, 11, "Months of Year"),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: _multiYearData.keys.toList().asMap().entries.map((entry) {
              return _buildLegendItem(entry.value.toString(), _chartColors[entry.key % _chartColors.length]);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricDropdown() {
    return Row(
      children: [
        const Text("Compare Metric: ", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(8)),
            child: DropdownButton<String>(
              value: _selectedParameter,
              isExpanded: true,
              underline: const SizedBox(),
              items: _availableParameters.entries.map((entry) => DropdownMenuItem(value: entry.key, child: Text(entry.value))).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedParameter = val);
                  _fetchAllSelectedDatesData();
                  _fetchParticularMonthData();
                  _fetchMultiMonthData();
                  _fetchMultiYearData();
                  _fetchYearlyData();
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLineChart(List<LineChartBarData> lines, double maxX, String xTitle) {
    return Row(
      children: [
        RotatedBox(quarterTurns: 3, child: Text(_availableParameters[_selectedParameter]!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey))),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: true, drawVerticalLine: true),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: true, reservedSize: 32, interval: maxX > 15 ? 5 : 1, getTitlesWidget: (value, meta) {
                          return Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(value.toInt().toString(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)));
                        }),
                      ),
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 45)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    minX: 0,
                    maxX: maxX,
                    minY: 0,
                    borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.shade300)),
                    lineBarsData: lines,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(xTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 14, height: 14, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}