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

class _HourlyCalculatorScreenState
    extends State<HourlyCalculatorScreen> {
      
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

  void _showWhatsAppReportDialog(BuildContext context) {
    
// 1. Hourly report time (hours only for the main body)
String hourlyTimeString = "${selectedTime.hour.toString().padLeft(2, '0')}:00";

// 2. Exact concentration date and time from your separate pickers
String concDateStr = "${concentrationDate.day.toString().padLeft(2, '0')}-${concentrationDate.month.toString().padLeft(2, '0')}-${concentrationDate.year}";
String concTimeStr = "${concentrationTime.hour.toString().padLeft(2, '0')}:${concentrationTime.minute.toString().padLeft(2, '0')}";
String finalConcDateTime = "$concDateStr (${concTimeStr}Hrs)";
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                
                // FIXED: Passing actual calculated variables instead of 0.0
                String report = WhatsappReportService.formatReport1(
                  date: selectedDate,
                  time: hourlyTimeString,
                  reservoirLevel: double.tryParse(currentLevelController.text) ?? 0.0,
                  desiltingLevel: double.tryParse(desiltingLevelController.text) ?? 0.0,
                  downstreamLevel: 0.0,
                  netHeadLoss: desiltingLevelDifference,
                  averageHourlyLoad: double.tryParse(loadController.text) ?? 0.0,
                  inflow: inflowDischarge,
                  totalBarrageOutflow: barrageWaterRelease,
                  rg1Discharge: rg1Discharge,
                  rg2Discharge: rg2Discharge,
                  rg3Discharge: rg3Discharge,
                  fdrgDischarge: fdrg,
                  sftDischarge: sft+sft,
                  fishPassDischarge: fishpassChannel + fishpassPipe,
                  eflowPipeDischarge: eflow,
                  finalConcDateTime: finalConcDateTime, // Pass the formatted concentration date and time
                  concentrationController: concentrationController, // Pass the controller
                  weather: selectedWeather,
                );
                _copyToClipboard(context, report, "Format 1");
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.water_drop_outlined, color: Colors.blue),
              title: const Text("Format 2: UPSTREAM & DOWNSTREAM DISCHARGE REPORT"),
              subtitle: const Text("River discharge, outflow, machine discharge"),
              onTap: () {
                Navigator.pop(context);
                
                // FIXED: Passing actual calculated variables
                String report2 = WhatsappReportService.formatReport2(
                  date: selectedDate,
                  time: hourlyTimeString,
                  riverDischarge: inflowDischarge, 
                  totalBarrageOutflow: barrageWaterRelease, 
                  powerhouseDischarge: powerHouseDischarge, 
                  reservoirLevel: double.tryParse(currentLevelController.text) ?? 0.0,
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
                
                // FIXED: Passing actual calculated variables
                String report3 = WhatsappReportService.formatReport3(
                  date: selectedDate,
                  time: hourlyTimeString,
                  reservoirLevel: double.tryParse(currentLevelController.text) ?? 0.0,
                  inflow: inflowDischarge, 
                  barrageOutflow: barrageWaterRelease, 
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
        content: Text("$formatName copied to clipboard! Ready to paste in WhatsApp."),
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
  final concentrationController = TextEditingController(); // Default value if needed

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
  double sft = 0.0;

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

    return ((gatedDischarge * gatedMins) + (freeflowDischarge * freeflowMins)) / 60.0;
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
    final previous = double.tryParse(previousLevelController.text) ?? 0.0;
    final current = double.tryParse(currentLevelController.text) ?? 0.0;
    final currentLevel = double.tryParse(currentLevelController.text) ?? 0.0;
    final desiltingLevel = double.tryParse(desiltingLevelController.text) ?? 0.0;

    desiltingLevelDifference = (currentLevel - desiltingLevel);


    double gateReservoirLevel = double.tryParse(reservoirLevelController.text) ?? 0;
    
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

    final load = double.tryParse(loadController.text) ?? 0.0;

    double divisor;
    if (previous >= 1264 && current >= 1264) {
      divisor = 0.82;
    } else if (previous < 1264 && current < 1264) {
      divisor = 0.75;
    } else {
      divisor = 0.785;
    }
    powerHouseDischarge = divisor == 0 ? 0 : load / divisor;

    rg1Discharge = calculateRadialGateDischarge(
      rg1Controller, rg1GatedMinsController, rg1FreeflowOpeningController, rg1FreeflowMinsController, gateReservoirLevel
    );
    rg2Discharge = calculateRadialGateDischarge(
      rg2Controller, rg2GatedMinsController, rg2FreeflowOpeningController, rg2FreeflowMinsController, gateReservoirLevel
    );
    rg3Discharge = calculateRadialGateDischarge(
      rg3Controller, rg3GatedMinsController, rg3FreeflowOpeningController, rg3FreeflowMinsController, gateReservoirLevel
    );

    if (fishpassPipeAuto) {
      fishpassPipe = FishpassPipeService.getDischarge(reservoirLevel: gateReservoirLevel);
      if (fishpassPipeController.text != fishpassPipe.toStringAsFixed(2)) {
        fishpassPipeController.text = fishpassPipe.toStringAsFixed(2);
      }
    } else {
      fishpassPipe = double.tryParse(fishpassPipeController.text) ?? 0;
    }

    if (fishpassChannelAuto) {
      fishpassChannel = FishpassChannelService.getDischarge(reservoirLevel: gateReservoirLevel);
      fishpassChannelController.text = fishpassChannel.toStringAsFixed(2);
    } else {
      fishpassChannel = double.tryParse(fishpassChannelController.text) ?? 0;
    }

    if (eflowAuto) {
      eflow = EFlowService.getDischarge(reservoirLevel: gateReservoirLevel);
      eflowController.text = eflow.toStringAsFixed(2);
    } else {
      eflow = double.tryParse(eflowController.text) ?? 0;
    }
    
    if (sft1Auto) {
      sft = SFTService.getDischarge(
        waterLevel: gateReservoirLevel,
        gateOpeningMm: double.tryParse(sft1Controller.text) ?? 0,
      );
    } else {
      sft = double.tryParse(sft1Controller.text) ?? 0;
    }

    if (sft2Auto) {
      sft = SFTService.getDischarge(
        waterLevel: gateReservoirLevel,
        gateOpeningMm: double.tryParse(sft2Controller.text) ?? 0,
      );
    } else {
      sft = double.tryParse(sft2Controller.text) ?? 0;
    }

    fdrg = FDRGService.getDischarge(
      gateOpeningMm: double.tryParse(fdrgController.text) ?? 0,
    );

    double levelDifference = (current - previous).abs();
    storageCorrection = levelDifference * factorF;

    barrageWaterRelease = rg1Discharge +
        rg2Discharge +
        rg3Discharge +
        fishpassPipe +
        fishpassChannel +
        eflow +
        sft+
        sft +
        fdrg;
        
    totalOutflowDischarge = powerHouseDischarge + barrageWaterRelease;

    if (current > previous) {
      inflowDischarge = totalOutflowDischarge + storageCorrection;
    } else if (current < previous) {
      inflowDischarge = totalOutflowDischarge - storageCorrection;
    } else {
      inflowDischarge = totalOutflowDischarge;
    }
    
    setState(() {});
  }

Future<void> saveReading() async {
  final prefs = await SharedPreferences.getInstance();
  List<String> readings = prefs.getStringList('hourly_readings') ?? [];

  String hourlyTimeString = "${selectedTime.hour.toString().padLeft(2, '0')}:00";

  // FIXED: Using selectedDate instead of DateTime.now() for the date string
  final reading = {
    "date": "${selectedDate.day.toString().padLeft(2, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.year}",
    "time": hourlyTimeString,
    "currentLevel": currentLevelController.text,
    "avgLoad": loadController.text,
    "powerHouseDischarge": powerHouseDischarge.toStringAsFixed(2),
    "rg1": rg1Discharge.toStringAsFixed(2),
    "rg2": rg2Discharge.toStringAsFixed(2),
    "rg3": rg3Discharge.toStringAsFixed(2),
    "sft1": sft.toStringAsFixed(2),
    "sft2": sft.toStringAsFixed(2),
    "eflow": eflow.toStringAsFixed(2),
    "fdrg": fdrg.toStringAsFixed(2),
    "barrageOutflow": barrageWaterRelease.toStringAsFixed(2),
    "totalOutflow": totalOutflowDischarge.toStringAsFixed(2),
    "inflow": inflowDischarge.toStringAsFixed(2),
  };
  
  // Rest of your save/sync code...

  // 1. Save locally to SharedPreferences
  readings.add(jsonEncode(reading));
  await prefs.setStringList('hourly_readings', readings);

  // 2. Export/Sync directly to Google Sheet via GET parameters
  try {
    // PASTE YOUR LATEST DEPLOYMENT URL BELOW
    final uri = Uri.parse("https://script.google.com/macros/s/AKfycbxyd30kmNaKX-BzRx187Rf7Si4hGgA9qdIxUgvUOw9xOW0letGpOCVTxpH2en9ALAXo4A/exec").replace(
      queryParameters: reading.map((key, value) => MapEntry(key, value.toString())),
    );

    final response = await http.get(uri);
    
    if (response.statusCode == 200) {
      debugPrint("Successfully synced to Google Sheet!");
    } else {
      debugPrint("Sync failed with status code: ${response.statusCode}");
    }
  } catch (e) {
    debugPrint("Google Sheet sync failed: $e");
  }

  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Reading Saved Successfully & Synced!")),
  );
}

Widget sectionTitle(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      text,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    ),
  );
}

Widget resultRow(String title, double value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title),
        Text("${value.toStringAsFixed(2)} m³/s"),
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hourly Calculator"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButton<String>(
                    value: _generateHourlyTimeSlots().contains("${selectedTime.hour.toString().padLeft(2, '0')}:00") 
                        ? "${selectedTime.hour.toString().padLeft(2, '0')}:00" 
                        : "00:00",
                    isExpanded: true,
                    items: _generateHourlyTimeSlots().map((String timeSlot) {
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
                      }
                    },
                  ),
                ),
              ],
            ),
            // Add this inside your Column children list where you want the weather picker to appear:
Padding(
  padding: const EdgeInsets.symmetric(vertical: 10),
  child: DropdownButtonFormField<String>(
    initialValue: selectedWeather,
    decoration: const InputDecoration(
      labelText: "Weather Condition",
      border: OutlineInputBorder(),
    ),
    items: const [
      DropdownMenuItem(value: 'Clear', child: Text("clear ☀️")),
      DropdownMenuItem(value: 'cloudy', child: Text("Cloudy ☁️")),
      DropdownMenuItem(value: 'rainy', child: Text("Rainy 🌧️")),
      DropdownMenuItem(value: 'heavy rainy', child: Text("heavy rainy ⛈️")),
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
            InputField(
              label: "Previous Reservoir Level (m)",
              controller: previousLevelController,
            ),
            const SizedBox(height: 15),
            InputField(
              label: "Current Reservoir Level (m)",
              controller: currentLevelController,
            ),
            const SizedBox(height: 15),
            InputField(
              label: "Desilting Level (m)",
              controller: desiltingLevelController,
            ),
             const SizedBox(height: 15),
            InputField(
              label: "Average Load (MW)",
              controller: loadController,
            ),
            const SizedBox(height: 15),
            InputField(
              label: "Reservoir Level for Other Discharges (m)",
              controller: reservoirLevelController,
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
                        calculateDischarge();
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
              const SizedBox(height: 30),
            Row(
  children: [
    // Date Picker Button
    Expanded(
      child: OutlinedButton.icon(
        icon: const Icon(Icons.calendar_today),
        label: Text("${concentrationDate.day.toString().padLeft(2, '0')}-${concentrationDate.month.toString().padLeft(2, '0')}-${concentrationDate.year}"),
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
    
    // Time Picker Button
    Expanded(
      child: OutlinedButton.icon(
        icon: const Icon(Icons.access_time),
        label: Text("${concentrationTime.hour.toString().padLeft(2, '0')}:${concentrationTime.minute.toString().padLeft(2, '0')} Hrs"),
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
                icon: const Icon(Icons.save),
                label: const Text(
                  "SAVE READING",
                  style: TextStyle(fontSize: 18),
                ),
                onPressed: saveReading,
              ),
            ),
            const SizedBox(height: 30),
            
            const SizedBox(height: 15),
            Card(
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      "Calculation Result",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const Divider(),
                    resultRow("POWER HOUSE DISCHARGE", powerHouseDischarge),
                    resultRow("RG-1", rg1Discharge),
                    resultRow("RG-2", rg2Discharge),
                    resultRow("RG-3", rg3Discharge),
                    const Divider(),
                    resultRow(
                      "Total RG Discharge",
                      rg1Discharge + rg2Discharge + rg3Discharge,
                    ),
                    const Divider(),
                    resultRow("FISHPASS PIPE DISCHARGE", fishpassPipe),
                    resultRow("FISHPASS CHANNEL DISCHARGE", fishpassChannel),
                    const Divider(),
                    resultRow(
                      "TOTAL FISHPASS DISCHARGE",
                      fishpassChannel + fishpassPipe,
                    ),
                    
                    const Divider(),
                    resultRow("E-FLOW DISCHARGE", eflow),
                    const Divider(),
                    resultRow("SFT-1 DISCHARGE", sft),
                    resultRow("SFT-2 DISCHARGE", sft),
                     const Divider(),
                     resultRow(
                      "TOTAL SFT DISCHARGE",
                      sft + sft,
                    ),
                     const Divider(),
                    resultRow("FDRG Discharge", fdrg),
                    const Divider(),
                    resultRow("Desilting Level Difference", desiltingLevelDifference),
                     const Divider(),
                    resultRow("BARRAGE OUTFLOW DISCHARGE", barrageWaterRelease),
                    resultRow(
                      "TOTAL OUTFLOW DISCHARGE",
                      barrageWaterRelease + powerHouseDischarge,
                    ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                icon: const Icon(Icons.share),
                label: const Text("Generate WhatsApp Report", style: TextStyle(fontSize: 16)),
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