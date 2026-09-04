import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../widgets/input_field.dart';
import '../services/gate_rating_service.dart';
import 'package:hydrocalc/services/fishpass_pipe_service.dart';
import 'package:hydrocalc/services/fishpass_channel_service.dart';
import '../services/eflow_service.dart';
import '../services/sft_service.dart';
import '../services/fdrg_service.dart';
import 'package:hydrocalc/widgets/discharge_input_card.dart';
import '../services/freeflow_service.dart';
import '../widgets/radial_gate_card.dart';
import 'package:hydrocalc/services/whatsapp_report_service.dart';
import 'package:http/http.dart' as http;

class HourlyCalculatorScreen extends StatefulWidget {
  const HourlyCalculatorScreen({super.key});

  @override
  State<HourlyCalculatorScreen> createState() =>
      _HourlyCalculatorScreenState();
}

class _HourlyCalculatorScreenState extends State<HourlyCalculatorScreen> {
  @override
  void initState() {
    super.initState();
    autoFetchPreviousLevel();
    _startHourlyAlarmChecker();
  }

  Timer? _hourlyCheckTimer;
  int _lastAlertedHour = -1;
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  DateTime concentrationDate = DateTime.now();
  TimeOfDay concentrationTime = TimeOfDay.now();

  List<String> _generateHourlyTimeSlots() {
    List<String> slots = [];
    for (int i = 0; i < 24; i++) {
      String hourStr = i.toString().padLeft(2, '0');
      slots.add("$hourStr:00");
    }
    return slots;
  }

  String selectedWeather = 'cloudy';

  // 2-Decimal Precision Helper
  double round2Dec(dynamic value) {
    if (value == null) return 0.00;
    if (value is num) return double.parse(value.toStringAsFixed(2));
    double? parsed = double.tryParse(value.toString());
    return parsed != null ? double.parse(parsed.toStringAsFixed(2)) : 0.00;
  }

  Future<void> autoFetchPreviousLevel() async {
    DateTime prevDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
    ).subtract(const Duration(hours: 1));

    String prevDateStr =
        "${prevDateTime.day.toString().padLeft(2, '0')}-${prevDateTime.month.toString().padLeft(2, '0')}-${prevDateTime.year}";
    String prevTimeStr =
        "${prevDateTime.hour.toString().padLeft(2, '0')}:00";
    String prevDocId = "${prevDateStr}_$prevTimeStr";

    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('barrage_readings')
          .doc(prevDocId)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('currentLevel')) {
          setState(() {
            previousLevelController.text =
                round2Dec(data['currentLevel']).toStringAsFixed(2);
          });
          calculateDischarge();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    "Auto-loaded previous level ($prevTimeStr): ${previousLevelController.text} m"),
                duration: const Duration(seconds: 2),
                backgroundColor: Colors.blueGrey,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Could not fetch previous reading: $e");
    }
  }

  void _showWhatsAppReportDialog(BuildContext context) {
    String hourlyTimeString =
        "${selectedTime.hour.toString().padLeft(2, '0')}:00";
    String concDateStr =
        "${concentrationDate.day.toString().padLeft(2, '0')}-${concentrationDate.month.toString().padLeft(2, '0')}-${concentrationDate.year}";
    String concTimeStr =
        "${concentrationTime.hour.toString().padLeft(2, '0')}:${concentrationTime.minute.toString().padLeft(2, '0')}";
    String finalConcDateTime = "$concDateStr (${concTimeStr}Hrs)";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Select WhatsApp Report"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.assignment_outlined, color: Colors.blue),
              title: const Text("Format 1: O&M Hourly Report"),
              subtitle: const Text("Includes all gates, fish pass, e-flow, etc."),
              onTap: () {
                Navigator.pop(context);
                String report = WhatsappReportService.formatReport1(
                  date: selectedDate,
                  time: hourlyTimeString,
                  reservoirLevel:
                      round2Dec(currentLevelController.text),
                  desiltingLevel:
                      round2Dec(desiltingLevelController.text),
                  downstreamLevel: 0.0,
                  netHeadLoss: round2Dec(desiltingLevelDifference),
                  averageHourlyLoad: round2Dec(loadController.text),
                  inflow: round2Dec(inflowDischarge),
                  totalBarrageOutflow: round2Dec(barrageWaterRelease),
                  rg1Discharge: round2Dec(rg1Discharge),
                  rg2Discharge: round2Dec(rg2Discharge),
                  rg3Discharge: round2Dec(rg3Discharge),
                  fdrgDischarge: round2Dec(fdrg),
                  sftDischarge: round2Dec(sft1Discharge + sft2Discharge),
                  fishPassDischarge: round2Dec(fishpassChannel + fishpassPipe),
                  eflowPipeDischarge: round2Dec(eflow),
                  finalConcDateTime: finalConcDateTime,
                  concentrationController: concentrationController,
                  weather: selectedWeather,
                );
                _copyToClipboard(context, report, "Format 1");
              },
            ),
            const Divider(),
            ListTile(
              leading:
                  const Icon(Icons.water_drop_outlined, color: Colors.blue),
              title:
                  const Text("Format 2: UPSTREAM & DOWNSTREAM DISCHARGE REPORT"),
              subtitle:
                  const Text("River discharge, outflow, machine discharge"),
              onTap: () {
                Navigator.pop(context);
                String report2 = WhatsappReportService.formatReport2(
                  date: selectedDate,
                  time: hourlyTimeString,
                  riverDischarge: round2Dec(inflowDischarge),
                  totalBarrageOutflow: round2Dec(barrageWaterRelease),
                  powerhouseDischarge: round2Dec(powerHouseDischarge),
                  reservoirLevel:
                      round2Dec(currentLevelController.text),
                  weather: selectedWeather,
                );
                _copyToClipboard(context, report2, "Format 2");
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.analytics_outlined, color: Colors.blue),
              title: const Text("Format 3: BARRAGE INFO"),
              subtitle: const Text("Naitwar Mori HPS site info & design limits"),
              onTap: () {
                Navigator.pop(context);
                String report3 = WhatsappReportService.formatReport3(
                  date: selectedDate,
                  time: hourlyTimeString,
                  reservoirLevel:
                      round2Dec(currentLevelController.text),
                  inflow: round2Dec(inflowDischarge),
                  barrageOutflow: round2Dec(barrageWaterRelease),
                  weather: selectedWeather,
                );
                _copyToClipboard(context, report3, "Format 3");
              },
            ),
          ],
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text, String formatName) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            "$formatName copied to clipboard! Ready to paste in WhatsApp."),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Controllers
  final previousLevelController = TextEditingController();
  final currentLevelController = TextEditingController();
  final desiltingLevelController = TextEditingController();
  final loadController = TextEditingController();
  final reservoirLevelController = TextEditingController();
  final rg1Controller = TextEditingController();
  final rg2Controller = TextEditingController();
  final rg3Controller = TextEditingController();

  final rg1GatedMinsController = TextEditingController(text: "60");
  final rg1FreeflowMinsController = TextEditingController(text: "0");
  final rg2GatedMinsController = TextEditingController(text: "60");
  final rg2FreeflowMinsController = TextEditingController(text: "0");
  final rg3GatedMinsController = TextEditingController(text: "60");
  final rg3FreeflowMinsController = TextEditingController(text: "0");

  final fishpassPipeController = TextEditingController();
  final fishpassChannelController = TextEditingController();
  final eflowController = TextEditingController();
  final sft1Controller = TextEditingController();
  final sft2Controller = TextEditingController();
  final fdrgController = TextEditingController();

  final rg1FreeflowOpeningController = TextEditingController();
  final rg2FreeflowOpeningController = TextEditingController();
  final rg3FreeflowOpeningController = TextEditingController();
  final concentrationController = TextEditingController();

  // Results
  double desiltingLevelDifference = 0.0;
  double powerHouseDischarge = 0.0;
  double factorF = 0.0;
  double storageCorrection = 0.0;
  double rg1Discharge = 0.0;
  double rg2Discharge = 0.0;
  double rg3Discharge = 0.0;
  double fishpassPipe = 0.0;
  double fishpassChannel = 0.0;
  double eflow = 0.0;
  double sft1Discharge = 0.0;
  double sft2Discharge = 0.0;
  double fdrg = 0.0;

  double calculateRadialGateDischarge(
    TextEditingController openingCtrl,
    TextEditingController gatedMinsCtrl,
    TextEditingController freeflowOpeningCtrl,
    TextEditingController freeflowMinsCtrl,
    double reservoirLevel,
  ) {
    double openingMm = double.tryParse(openingCtrl.text) ?? 0.0;
    int gatedMins = int.tryParse(gatedMinsCtrl.text) ?? 0;
    double freeflowOpeningMm = double.tryParse(freeflowOpeningCtrl.text) ?? 0.0;
    int freeflowMins = int.tryParse(freeflowMinsCtrl.text) ?? 0;

    if (gatedMins + freeflowMins > 60) {
      return 0.0;
    }

    double gatedDischarge = GateRatingService.getDischarge(
      reservoirLevel: reservoirLevel,
      gateOpeningMm: openingMm,
    );

    double freeflowDischarge = FreeflowService.getDischarge(
      gateOpeningMm: freeflowOpeningMm,
    );

    double discharge = ((gatedDischarge * gatedMins) +
            (freeflowDischarge * freeflowMins)) /
        60.0;
    return round2Dec(discharge);
  }

  double barrageWaterRelease = 0.0;
  double totalOutflowDischarge = 0.0;
  double inflowDischarge = 0.0;

  bool fishpassPipeAuto = false;
  bool fishpassChannelAuto = false;
  bool eflowAuto = false;
  bool sft1Auto = false;
  bool sft2Auto = false;

  @override
  void dispose() {
    _hourlyCheckTimer?.cancel();
    previousLevelController.dispose();
    currentLevelController.dispose();
    desiltingLevelController.dispose();
    reservoirLevelController.dispose();
    loadController.dispose();
    rg1Controller.dispose();
    rg2Controller.dispose();
    rg3Controller.dispose();
    rg1GatedMinsController.dispose();
    rg1FreeflowMinsController.dispose();
    rg2GatedMinsController.dispose();
    rg2FreeflowMinsController.dispose();
    rg3GatedMinsController.dispose();
    rg3FreeflowMinsController.dispose();
    fishpassPipeController.dispose();
    fishpassChannelController.dispose();
    eflowController.dispose();
    sft1Controller.dispose();
    sft2Controller.dispose();
    fdrgController.dispose();
    rg1FreeflowOpeningController.dispose();
    rg2FreeflowOpeningController.dispose();
    rg3FreeflowOpeningController.dispose();
    concentrationController.dispose();
    super.dispose();
  }

  void calculateDischarge() {
    final previous = round2Dec(previousLevelController.text);
    final current = round2Dec(currentLevelController.text);
    final currentLevel = round2Dec(currentLevelController.text);
    final desiltingLevel = round2Dec(desiltingLevelController.text);

    desiltingLevelDifference = round2Dec(currentLevel - desiltingLevel);

    double gateReservoirLevel =
        round2Dec(reservoirLevelController.text);

    if (gateReservoirLevel < 1263) {
      factorF = 9.06;
    } else if (gateReservoirLevel == 1263) {
      factorF = (9.06 + 11.74) / 2;
    } else if (gateReservoirLevel < 1265) {
      factorF = 11.74;
    } else if (gateReservoirLevel == 1265) {
      factorF = (11.74 + 15.25) / 2;
    } else {
      factorF = 15.25;
    }

    final load = round2Dec(loadController.text);

    double divisor;
    if (previous >= 1264 && current >= 1264) {
      divisor = 0.82;
    } else if (previous < 1264 && current < 1264) {
      divisor = 0.75;
    } else {
      divisor = 0.785;
    }
    powerHouseDischarge = divisor == 0 ? 0.0 : round2Dec(load / divisor);

    rg1Discharge = calculateRadialGateDischarge(
        rg1Controller,
        rg1GatedMinsController,
        rg1FreeflowOpeningController,
        rg1FreeflowMinsController,
        gateReservoirLevel);
    rg2Discharge = calculateRadialGateDischarge(
        rg2Controller,
        rg2GatedMinsController,
        rg2FreeflowOpeningController,
        rg2FreeflowMinsController,
        gateReservoirLevel);
    rg3Discharge = calculateRadialGateDischarge(
        rg3Controller,
        rg3GatedMinsController,
        rg3FreeflowOpeningController,
        rg3FreeflowMinsController,
        gateReservoirLevel);

    if (fishpassPipeAuto) {
      fishpassPipe = round2Dec(
          FishpassPipeService.getDischarge(reservoirLevel: gateReservoirLevel));
      if (fishpassPipeController.text != fishpassPipe.toStringAsFixed(2)) {
        fishpassPipeController.text = fishpassPipe.toStringAsFixed(2);
      }
    } else {
      fishpassPipe = round2Dec(fishpassPipeController.text);
    }

    if (fishpassChannelAuto) {
      fishpassChannel = round2Dec(
          FishpassChannelService.getDischarge(reservoirLevel: gateReservoirLevel));
      fishpassChannelController.text = fishpassChannel.toStringAsFixed(2);
    } else {
      fishpassChannel = round2Dec(fishpassChannelController.text);
    }

    if (eflowAuto) {
      eflow = round2Dec(
          EFlowService.getDischarge(reservoirLevel: gateReservoirLevel));
      eflowController.text = eflow.toStringAsFixed(2);
    } else {
      eflow = round2Dec(eflowController.text);
    }

    if (sft1Auto) {
      double opening1 = round2Dec(sft1Controller.text);
      sft1Discharge = round2Dec(SFTService.getDischarge(
        waterLevel: gateReservoirLevel,
        gateOpeningMm: opening1,
      ));
    } else {
      sft1Discharge = round2Dec(sft1Controller.text);
    }

    if (sft2Auto) {
      double opening2 = round2Dec(sft2Controller.text);
      sft2Discharge = round2Dec(SFTService.getDischarge(
        waterLevel: gateReservoirLevel,
        gateOpeningMm: opening2,
      ));
    } else {
      sft2Discharge = round2Dec(sft2Controller.text);
    }
    fdrg = round2Dec(FDRGService.getDischarge(
      gateOpeningMm: round2Dec(fdrgController.text),
    ));

    double levelDifference = (current - previous).abs();
    storageCorrection = round2Dec(levelDifference * factorF);

    barrageWaterRelease = round2Dec(rg1Discharge +
        rg2Discharge +
        rg3Discharge +
        fishpassPipe +
        fishpassChannel +
        eflow +
        sft1Discharge +
        sft2Discharge +
        fdrg);

    totalOutflowDischarge = round2Dec(powerHouseDischarge + barrageWaterRelease);

    if (current > previous) {
      inflowDischarge = round2Dec(totalOutflowDischarge + storageCorrection);
    } else if (current < previous) {
      inflowDischarge = round2Dec(totalOutflowDischarge - storageCorrection);
    } else {
      inflowDischarge = totalOutflowDischarge;
    }

    setState(() {});
  }

  Future<void> saveReading() async {
    calculateDischarge();

    String hourlyTimeString =
        "${selectedTime.hour.toString().padLeft(2, '0')}:00";
    String formattedDate =
        "${selectedDate.day.toString().padLeft(2, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.year}";
    String docId = "${formattedDate}_$hourlyTimeString";

    final readingData = {
      "date": formattedDate,
      "time": hourlyTimeString,
      "timestamp": DateTime.now().toIso8601String(),
      "currentLevel": round2Dec(currentLevelController.text),
      "previousLevel": round2Dec(previousLevelController.text),
      "desiltingLevel": round2Dec(desiltingLevelController.text),
      "avgLoad": round2Dec(loadController.text),
      "powerHouseDischarge": round2Dec(powerHouseDischarge),
      "rg1": round2Dec(rg1Discharge),
      "rg2": round2Dec(rg2Discharge),
      "rg3": round2Dec(rg3Discharge),
      "sft1": round2Dec(sft1Discharge),
      "sft2": round2Dec(sft2Discharge),
      "fishpassPipe": round2Dec(fishpassPipe),
      "fishpassChannel": round2Dec(fishpassChannel),
      "eflow": round2Dec(eflow),
      "fdrg": round2Dec(fdrg),
      "barrageOutflow": round2Dec(barrageWaterRelease),
      "totalOutflow": round2Dec(totalOutflowDischarge),
      "inflow": round2Dec(inflowDischarge),
      "weather": selectedWeather,
      "concentration": round2Dec(concentrationController.text),
    };

    try {
      await FirebaseFirestore.instance
          .collection('barrage_readings')
          .doc(docId)
          .set(readingData, SetOptions(merge: true));

      final prefs = await SharedPreferences.getInstance();
      List<String> readings = prefs.getStringList('hourly_readings') ?? [];
      readings.add(jsonEncode(readingData));
      await prefs.setStringList('hourly_readings', readings);

      _sendToGoogleSheetSafely(readingData);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Reading saved successfully for $hourlyTimeString!"),
          backgroundColor: Colors.teal.shade700,
        ),
      );
    } catch (e) {
      debugPrint("Save error: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Save failed: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _sendToGoogleSheetSafely(Map<String, dynamic> data) async {
    try {
      final uri = Uri.parse(
        "https://script.google.com/macros/s/AKfycbxyd30kmNaKX-BzRx187Rf7Si4hGgA9qdIxUgvUOw9xOW0letGpOCVTxpH2en9ALAXo4A/exec",
      ).replace(
        queryParameters: data.map((key, value) => MapEntry(key, value.toString())),
      );

      await http.get(uri).timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint("Google Sheets sync bypassed or timed out: $e");
    }
  }

  Widget sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E3A8A),
        ),
      ),
    );
  }

  void _startHourlyAlarmChecker() {
    _hourlyCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      final now = DateTime.now();
      if (now.minute == 0 && now.hour != _lastAlertedHour) {
        _lastAlertedHour = now.hour;
        _triggerHourlyAlert();
      }
    });
  }

  void _triggerHourlyAlert() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.alarm, color: Colors.orange, size: 30),
            SizedBox(width: 10),
            Text("Hourly Log Reminder!"),
          ],
        ),
        content: Text(
          "It is now ${nowFormattedHour()}. Time to record and save the hourly barrage reading!",
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK, Logging Now"),
          ),
        ],
      ),
    );
  }

  String nowFormattedHour() {
    final now = DateTime.now();
    return "${now.hour.toString().padLeft(2, '0')}:00 Hrs";
  }

  Widget resultRow(String title, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text("${round2Dec(value).toStringAsFixed(2)} m³/s"),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hourly Calculator",
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.analytics, color: Colors.white, size: 32),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      "Enter hourly parameters for discharge & head computation.",
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        icon: const Icon(Icons.calendar_today),
                        label: Text("${selectedDate.toLocal()}".split(' ')[0]),
                        onPressed: () async {
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2025),
                            lastDate: DateTime(2030),
                          );
                          if (pickedDate != null) {
                            setState(() {
                              selectedDate = pickedDate;
                            });
                            autoFetchPreviousLevel();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButton<String>(
                        value: _generateHourlyTimeSlots().contains(
                                "${selectedTime.hour.toString().padLeft(2, '0')}:00")
                            ? "${selectedTime.hour.toString().padLeft(2, '0')}:00"
                            : "00:00",
                        isExpanded: true,
                        items:
                            _generateHourlyTimeSlots().map((String timeSlot) {
                          return DropdownMenuItem<String>(
                            value: timeSlot,
                            child: Text("$timeSlot Hrs"),
                          );
                        }).toList(),
                        onChanged: (String? newTime) {
                          if (newTime != null) {
                            final parts = newTime.split(':');
                            setState(() {
                              selectedTime = TimeOfDay(
                                hour: int.parse(parts[0]),
                                minute: 0,
                              );
                            });
                            autoFetchPreviousLevel();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: DropdownButtonFormField<String>(
                initialValue: selectedWeather,
                decoration: const InputDecoration(
                  labelText: "Weather Condition",
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Clear', child: Text("Clear ☀️")),
                  DropdownMenuItem(value: 'cloudy', child: Text("Cloudy ☁️")),
                  DropdownMenuItem(value: 'rainy', child: Text("Rainy 🌧️")),
                  DropdownMenuItem(
                      value: 'heavy rainy', child: Text("Heavy Rainy ⛈️")),
                ],
                onChanged: (String? newWeather) {
                  if (newWeather != null) {
                    setState(() {
                      selectedWeather = newWeather;
                    });
                  }
                },
              ),
            ),
            sectionTitle("Reservoir Levels"),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: InputField(
                            label: "Previous Reservoir Level (m)",
                            controller: previousLevelController,
                            onChanged: (value) => calculateDischarge(),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.sync, color: Color(0xFF1E3A8A)),
                          tooltip: "Fetch last hour's level from Firestore",
                          onPressed: autoFetchPreviousLevel,
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    InputField(
                      label: "Current Reservoir Level (m)",
                      controller: currentLevelController,
                      onChanged: (value) => calculateDischarge(),
                    ),
                    const SizedBox(height: 15),
                    InputField(
                      label: "Desilting Level (m)",
                      controller: desiltingLevelController,
                      onChanged: (value) => calculateDischarge(),
                    ),
                    const SizedBox(height: 15),
                    InputField(
                      label: "Average Load (MW)",
                      controller: loadController,
                      onChanged: (value) => calculateDischarge(),
                    ),
                    const SizedBox(height: 15),
                    InputField(
                      label: "Reservoir Level for Other Discharges (m)",
                      controller: reservoirLevelController,
                      onChanged: (value) => calculateDischarge(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            sectionTitle("Radial Gates"),
            const Text(
              "Radial Gate Discharge",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            RadialGateCard(
              label: "RG-1 Status",
              openingController: rg1Controller,
              gatedMinsController: rg1GatedMinsController,
              freeflowOpeningController: rg1FreeflowOpeningController,
              freeflowMinsController: rg1FreeflowMinsController,
              totalDischarge: rg1Discharge,
              onChanged: calculateDischarge,
            ),
            const SizedBox(height: 15),
            RadialGateCard(
              label: "RG-2 Status",
              openingController: rg2Controller,
              gatedMinsController: rg2GatedMinsController,
              freeflowOpeningController: rg2FreeflowOpeningController,
              freeflowMinsController: rg2FreeflowMinsController,
              totalDischarge: rg2Discharge,
              onChanged: calculateDischarge,
            ),
            const SizedBox(height: 15),
            RadialGateCard(
              label: "RG-3 Status",
              openingController: rg3Controller,
              gatedMinsController: rg3GatedMinsController,
              freeflowOpeningController: rg3FreeflowOpeningController,
              freeflowMinsController: rg3FreeflowMinsController,
              totalDischarge: rg3Discharge,
              onChanged: calculateDischarge,
            ),
            const SizedBox(height: 30),
            sectionTitle("Other Discharges"),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DischargeInputCard(
                            label: "Fishpass pipe Discharge (Cumecs)",
                            controller: fishpassPipeController,
                            discharge: fishpassPipe,
                            readOnly: fishpassPipeAuto,
                            onChanged: (value) {
                              if (!fishpassPipeAuto) {
                                calculateDischarge();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          children: [
                            const Text("Auto"),
                            Switch(
                              value: fishpassPipeAuto,
                              onChanged: (value) {
                                setState(() {
                                  fishpassPipeAuto = value;
                                });
                                calculateDischarge();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: DischargeInputCard(
                            label: "Fishpass Channel Discharge (Cumecs)",
                            controller: fishpassChannelController,
                            discharge: fishpassChannel,
                            readOnly: fishpassChannelAuto,
                            onChanged: (value) {
                              if (!fishpassChannelAuto) {
                                calculateDischarge();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          children: [
                            const Text("Auto"),
                            Switch(
                              value: fishpassChannelAuto,
                              onChanged: (value) {
                                setState(() {
                                  fishpassChannelAuto = value;
                                });
                                calculateDischarge();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: InputField(
                            label: "E-Flow",
                            controller: eflowController,
                            readOnly: eflowAuto,
                            onChanged: (value) {
                              calculateDischarge();
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          children: [
                            const Text("Auto"),
                            Switch(
                              value: eflowAuto,
                              onChanged: (value) {
                                setState(() {
                                  eflowAuto = value;
                                });
                                calculateDischarge();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: InputField(
                            label: sft1Auto
                                ? "SFT-1 Gate Opening (mm)"
                                : "SFT-1 Discharge (m³/s)",
                            controller: sft1Controller,
                            readOnly: false,
                            onChanged: (value) {
                              calculateDischarge();
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          children: [
                            const Text("Auto"),
                            Switch(
                              value: sft1Auto,
                              onChanged: (value) {
                                setState(() {
                                  sft1Auto = value;
                                });
                                calculateDischarge();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: InputField(
                            label: sft2Auto
                                ? "SFT-2 Gate Opening (mm)"
                                : "SFT-2 Discharge (m³/s)",
                            controller: sft2Controller,
                            readOnly: false,
                            onChanged: (value) {
                              calculateDischarge();
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          children: [
                            const Text("Auto"),
                            Switch(
                              value: sft2Auto,
                              onChanged: (value) {
                                setState(() {
                                  sft2Auto = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    DischargeInputCard(
                      label: "FDRG Gate Opening (mm)",
                      controller: fdrgController,
                      discharge: fdrg,
                      onChanged: (value) {
                        calculateDischarge();
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                        "${concentrationDate.day.toString().padLeft(2, '0')}-${concentrationDate.month.toString().padLeft(2, '0')}-${concentrationDate.year}"),
                    onPressed: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: concentrationDate,
                        firstDate: DateTime(2025),
                        lastDate: DateTime(2030),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          concentrationDate = pickedDate;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 30),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.access_time),
                    label: Text(
                        "${concentrationTime.hour.toString().padLeft(2, '0')}:${concentrationTime.minute.toString().padLeft(2, '0')} Hrs"),
                    onPressed: () async {
                      TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: concentrationTime,
                      );
                      if (pickedTime != null) {
                        setState(() {
                          concentrationTime = pickedTime;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            InputField(
              label: "Concentration (ppm)",
              controller: concentrationController,
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                ),
                onPressed: calculateDischarge,
                child: const Text(
                  "CALCULATE",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade700,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.save),
                label: const Text(
                  "SAVE READING",
                  style: TextStyle(fontSize: 18),
                ),
                onPressed: saveReading,
              ),
            ),
            const SizedBox(height: 30),
            Card(
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      "Calculation Result",
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const Divider(),
                    resultRow("POWER HOUSE DISCHARGE", powerHouseDischarge),
                    resultRow("RG-1", rg1Discharge),
                    resultRow("RG-2", rg2Discharge),
                    resultRow("RG-3", rg3Discharge),
                    const Divider(),
                    resultRow("Total RG Discharge",
                        rg1Discharge + rg2Discharge + rg3Discharge),
                    const Divider(),
                    resultRow("FISHPASS PIPE DISCHARGE", fishpassPipe),
                    resultRow("FISHPASS CHANNEL DISCHARGE", fishpassChannel),
                    const Divider(),
                    resultRow("TOTAL FISHPASS DISCHARGE",
                        fishpassChannel + fishpassPipe),
                    const Divider(),
                    resultRow("E-FLOW DISCHARGE", eflow),
                    const Divider(),
                    resultRow("SFT-1 DISCHARGE", sft1Discharge),
                    resultRow("SFT-2 DISCHARGE", sft2Discharge),
                    const Divider(),
                    resultRow("TOTAL SFT DISCHARGE", sft1Discharge + sft2Discharge),
                    const Divider(),
                    resultRow("FDRG Discharge", fdrg),
                    const Divider(),
                    resultRow(
                        "Desilting Level Difference", desiltingLevelDifference),
                    const Divider(),
                    resultRow(
                        "BARRAGE OUTFLOW DISCHARGE", barrageWaterRelease),
                    resultRow(
                        "TOTAL OUTFLOW DISCHARGE",
                        barrageWaterRelease + powerHouseDischarge),
                    const Divider(),
                    resultRow("Reservoir calculation", storageCorrection),
                    const Divider(),
                    Text(
                      "INFLOW DISCHARGE = ${inflowDischarge.toStringAsFixed(2)} m³/s",
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                icon: const Icon(Icons.share),
                label: const Text("Generate WhatsApp Report",
                    style: TextStyle(fontSize: 16)),
                onPressed: () => _showWhatsAppReportDialog(context),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}