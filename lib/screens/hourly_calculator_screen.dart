import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../widgets/input_field.dart';
import '../services/gate_rating_service.dart';
import 'package:hydrocalc/services/fishpass_pipe_service.dart';
import '../services/fishpass_channel_service.dart';
import '../services/eflow_service.dart';
import '../services/sft_service.dart';
import '../services/fdrg_service.dart';
import 'package:hydrocalc/widgets/discharge_input_card.dart';
class HourlyCalculatorScreen extends StatefulWidget {
  const HourlyCalculatorScreen({super.key});

  @override
  State<HourlyCalculatorScreen> createState() =>
      _HourlyCalculatorScreenState();
}

class _HourlyCalculatorScreenState
    extends State<HourlyCalculatorScreen> {
  // Controllers
  final previousLevelController = TextEditingController();
  final currentLevelController = TextEditingController();
  final loadController = TextEditingController();
  final reservoirLevelController = TextEditingController();
  final rg1Controller = TextEditingController();
  final rg2Controller = TextEditingController();
  final rg3Controller = TextEditingController();

  final fishpassPipeController = TextEditingController();
  final fishpassChannelController = TextEditingController();
  final eflowController = TextEditingController();
  final sftController = TextEditingController();
  final fdrgController = TextEditingController();

  // Results
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
 
 
 double barrageWaterRelease = 0.0;
 double totalOutflowDischarge = 0.0;
 double inflowDischarge = 0.0;

 bool fishpassPipeAuto = false;
 bool fishpassChannelAuto = false;
 bool eflowAuto = false;
 bool sftAuto = false;
 

  @override
  void dispose() {
    previousLevelController.dispose();
    currentLevelController.dispose();
    reservoirLevelController.dispose();
    loadController.dispose();
    rg1Controller.dispose();
    rg2Controller.dispose();
    rg3Controller.dispose();
    fishpassPipeController.dispose();
    fishpassChannelController.dispose();
    eflowController.dispose();
    sftController.dispose();
    fdrgController.dispose();
    super.dispose();
  }

  void calculateDischarge() {
    final previous =
        double.tryParse(previousLevelController.text) ?? 0.0;

    final current =
        double.tryParse(currentLevelController.text) ?? 0.0;
        double gateReservoirLevel =
        double.tryParse(reservoirLevelController.text) ?? 0;
        // Factor based on reservoir level
if (gateReservoirLevel < 1263) {
  factorF = 9.06;
} else if (gateReservoirLevel == 1263) {
  factorF = (9.06 + 11.74) / 2; // 10.40
} else if (gateReservoirLevel < 1265) {
  factorF = 11.74;
} else if (gateReservoirLevel == 1265) {
  factorF = (11.74 + 15.25) / 2; // 13.50
} else {
  factorF = 15.25;
}

    final load =
        double.tryParse(loadController.text) ?? 0.0;


    double divisor;

    if (previous >= 1264 && current >= 1264) {
      divisor = 0.82;
    } else if (previous < 1264 && current < 1264) {
      divisor = 0.75;
    } else {
      divisor = 0.785;
    }
    powerHouseDischarge =
        divisor == 0 ? 0 : load / divisor;

    // Temporary RG formula
  rg1Discharge = GateRatingService.getDischarge(
  reservoirLevel: gateReservoirLevel,
  gateOpeningMm: double.tryParse(rg1Controller.text) ?? 0,
);

print("RG1 = $rg1Discharge");
print("Reservoir = $gateReservoirLevel");
print("Opening = ${double.tryParse(rg1Controller.text) ?? 0}");
  rg2Discharge = GateRatingService.getDischarge(
  reservoirLevel: gateReservoirLevel,
  gateOpeningMm:
      double.tryParse(rg2Controller.text) ?? 0,
      );
  rg3Discharge = GateRatingService.getDischarge(
  reservoirLevel: gateReservoirLevel,
  gateOpeningMm:
      double.tryParse(rg3Controller.text) ?? 0,
      );

    // Fishpass pipe
if (fishpassPipeAuto) {
  fishpassPipe = FishpassPipeService.getDischarge(
    reservoirLevel: gateReservoirLevel,
  );

  if (fishpassPipeController.text !=
      fishpassPipe.toStringAsFixed(2)) {
    fishpassPipeController.text =
        fishpassPipe.toStringAsFixed(2);
  }
} else {
  fishpassPipe =
      double.tryParse(fishpassPipeController.text) ?? 0;
}

    // Fishpass Channel
if (fishpassChannelAuto) {
  fishpassChannel = FishpassChannelService.getDischarge(
    reservoirLevel: gateReservoirLevel,
  );

  fishpassChannelController.text =
      fishpassChannel.toStringAsFixed(2);

} else {
  // Operator enters discharge directly
  fishpassChannel =
      double.tryParse(fishpassChannelController.text) ?? 0;
}

    if (eflowAuto) {
      eflow = EFlowService.getDischarge(
        reservoirLevel: gateReservoirLevel,
        );
        eflowController.text =
        eflow.toStringAsFixed(2);
        } else {
          eflow =
          double.tryParse(eflowController.text) ?? 0;
        }
         if (sftAuto) {
  sft = SFTService.getDischarge(
    waterLevel: gateReservoirLevel,
    gateOpeningMm: double.tryParse(sftController.text) ?? 0,
  );

  sftController.text =
      (double.tryParse(sftController.text) ?? 0).toStringAsFixed(0);
} else {
  sft = double.tryParse(sftController.text) ?? 0;
}
fdrg = FDRGService.getDischarge(
  gateOpeningMm:
      double.tryParse(fdrgController.text) ?? 0,
);


double levelDifference = (current - previous).abs();

storageCorrection = levelDifference * factorF;


    barrageWaterRelease =
    rg1Discharge +
    rg2Discharge +
    rg3Discharge +
    fishpassPipe +
    fishpassChannel +
    eflow +
    sft+fdrg;
    inflowDischarge =
    powerHouseDischarge +
    barrageWaterRelease;

    if (current > previous) {
  inflowDischarge =
      powerHouseDischarge +
      barrageWaterRelease +
      storageCorrection;
} else if (current < previous) {
  inflowDischarge =
      powerHouseDischarge +
      barrageWaterRelease -
      storageCorrection;
} else {
  inflowDischarge =
      powerHouseDischarge +
      barrageWaterRelease;
}
totalOutflowDischarge =
    powerHouseDischarge +
    barrageWaterRelease;
    
    setState(() {});
  }
  Future<void> saveReading() async {
  final prefs = await SharedPreferences.getInstance();

  List<String> readings =
      prefs.getStringList('hourly_readings') ?? [];

  final now = DateTime.now();

  final reading = {
    "date":
        "${now.day.toString().padLeft(2, '0')}-"
        "${now.month.toString().padLeft(2, '0')}-"
        "${now.year}",

    "time":
        "${now.hour.toString().padLeft(2, '0')}:"
        "${now.minute.toString().padLeft(2, '0')}",

    "currentLevel": currentLevelController.text,

    "barrageOutflow":
        barrageWaterRelease.toStringAsFixed(2),

    "totalOutflow":
        totalOutflowDischarge.toStringAsFixed(2),

    "inflow":
        inflowDischarge.toStringAsFixed(2),
  };

  readings.add(jsonEncode(reading));

  await prefs.setStringList(
    'hourly_readings',
    readings,
  );

  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("Reading Saved Successfully"),
    ),
  );
}

  Widget sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget resultRow(String title, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
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
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
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
  style: TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
  ),
),


const SizedBox(height: 20),

DischargeInputCard(
  label: "RG-1 Opening (mm)",
  controller: rg1Controller,
  discharge: rg1Discharge,
  onChanged: (value) {
  calculateDischarge();
},
),
const SizedBox(height: 15),

DischargeInputCard(
  label: "RG-2 Opening (mm)",
  controller: rg2Controller,
  discharge: rg2Discharge,
  onChanged: (value) {
  calculateDischarge();
},
),

const SizedBox(height: 15),

DischargeInputCard(
  label: "RG-3 Opening (mm)",
  controller: rg3Controller,
  discharge: rg3Discharge,
  onChanged: (value) {
  calculateDischarge();
},
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
  label: sftAuto
      ? "SFT Gate Opening (mm)"
      : "SFT Discharge (m³/s)",
  controller: sftController,
  readOnly: false,
),
    ),
    const SizedBox(width: 10),
    Column(
      children: [
        const Text("Auto"),
        Switch(
          value: sftAuto,
          onChanged: (value) {
            setState(() {
              sftAuto = value;
            });
          },
        ),
      ],
    ),
  ],
),
DischargeInputCard(
  label: "FDRG Gate Opening (mm)",
  controller: fdrgController,
  discharge: fdrg,
onChanged: (value) {
  calculateDischarge();
},
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
//card for results
            Card(
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      "Calculation Result",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const Divider(),

                    resultRow(
                        "POWER HOUSE DISCHARGE",
                        powerHouseDischarge),

                    resultRow("RG-1", rg1Discharge),
                    resultRow("RG-2", rg2Discharge),
                    resultRow("RG-3", rg3Discharge),
                    const Divider(),
                    resultRow(
                      "Total RG Discharge",
                      rg1Discharge + rg2Discharge + rg3Discharge,
                      ),
                    const Divider(),
                    

                    resultRow(
                        "FISHPASS PIPE DISCHARGE",
                        fishpassPipe),

                    resultRow(
                        "FISHPASS CHANNEL DISCHARGE",
                        fishpassChannel ),
                    const Divider(),
                    resultRow(
                        "TOTAL FISHPASS DISCHARGE",
                        fishpassChannel+fishpassPipe ),
                    const Divider(),

                    resultRow(
                        "E-FLOW DISCHARGE",
                        eflow),

                    resultRow(
                      "SFT DISCHARGE", 
                      sft),
                      
                    resultRow(
                       "FDRG Discharge",
                       fdrg,
                       ),
                    const Divider(),
                    resultRow(
                      "BARRAGE OUTFLOW DISCHARGE",
                      barrageWaterRelease,
                      ),
                      resultRow(
                      "TOTAL OUTFLOW DISCHARGE",
                      barrageWaterRelease+powerHouseDischarge,
                      ),
                      const Divider(),
                      resultRow(
                      "Reservoir calculation",
                          
                      storageCorrection,
                      ),
                      
                      const Divider(),
                      
                      Text(
                        
                        "INFLOW DISCHARGE = ${inflowDischarge.toStringAsFixed(2)} m³/s",
                        style: const TextStyle(
                          fontSize: 24,
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          )
                          ),
                   
                      
                    
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}