import 'package:intl/intl.dart';

class WhatsappReportService {
  
  // Format 1
  static String formatReport1({
    
    required DateTime date,
    required String time,
    required double reservoirLevel,
    required double desiltingLevel,
    required double downstreamLevel,
    required double netHeadLoss,
    required double averageHourlyLoad,
    required double inflow,
    required double totalBarrageOutflow,
    required double rg1Discharge,
    required double rg2Discharge,
    required double rg3Discharge,
    required double fdrgDischarge,
    required double sftDischarge,
    required double fishPassDischarge,
    required double eflowPipeDischarge,
     required String finalConcDateTime,
    required  concentrationController,
    required String weather, // Added weather parameter
  }) {
    String dateStr = DateFormat('dd-MM-yyyy').format(date);
    
//REPORT FORMAT 1

    return '''📆Date: *$dateStr*
⏰Time: *${time}Hrs*
🔹Reservoir Level: *${reservoirLevel.toStringAsFixed(2)}m*
🔹Desilting Level: *${desiltingLevel > 0 ? '${desiltingLevel.toStringAsFixed(2)}m' : ''}* 
🔹Downstream Level: *${downstreamLevel > 0 ? '${downstreamLevel.toStringAsFixed(2)}m' : ''}*
🔹Net Head Loss: *${netHeadLoss > 0 ? '${netHeadLoss.toStringAsFixed(2)}m' : ''}*
🔹Average Hourly Load: *${averageHourlyLoad.toStringAsFixed(2)} MW*
🔹Inflow (Calculated): *${inflow.toStringAsFixed(2)} cumecs* 
🔹Total E-Flow: *${totalBarrageOutflow.toStringAsFixed(2)} Cumecs*
RG1 : ${rg1Discharge.toStringAsFixed(2)} Cumecs
RG2 : ${rg2Discharge.toStringAsFixed(2)} Cumecs 
RG3 : ${rg3Discharge.toStringAsFixed(2)} Cumecs
FDRG: ${fdrgDischarge.toStringAsFixed(2)} Cumecs
SFT 1&2 : ${sftDischarge.toStringAsFixed(2)} Cumecs 
Fish Pass : ${fishPassDischarge.toStringAsFixed(2)} cumecs
E Flow pipe : ${eflowPipeDischarge.toStringAsFixed(2)} cumecs
🔹Last Year Maximum Discharge for the Month of August '2025 = 776.91 cumecs
🔹Visual Debris Near Trash Rack: ** 
🔹Last Silt Sample Taken : Barrage 
*$finalConcDateTime*
🔹Concentration:  *${concentrationController.text} ppm* 
◇Weather : *$weather*''';
  }

  // Format 2
  static String formatReport2({
    required DateTime date,
    required String time,
    required double riverDischarge,
    required double totalBarrageOutflow,
    required double powerhouseDischarge,
    required double reservoirLevel,
    required String weather,
  }) {
    String dateStr = DateFormat('dd-MM-yyyy').format(date);

    return '''*Naitwar Mori Hydro Power Station* *(SJVN)* *(2x30=60MW)*
*Location: Barrage* *(FRL 1267.00)* 
Date: *$dateStr*
*Time - $time Hrs*

1. *River Discharge Cumecs - ${riverDischarge.toStringAsFixed(2)}*
2. *Discharge (from gates, valves i/c, Fish pass) from Barrage - ${totalBarrageOutflow.toStringAsFixed(2)} cumecs*
3. *Discharge passing through machine - ${powerhouseDischarge.toStringAsFixed(2)} Cumecs* 
4. *Barrage Level - ${reservoirLevel.toStringAsFixed(2)} m* 
5. *Weather - $weather*''';
  }

  // Format 3
  static String formatReport3({
    required DateTime date,
    required String time,
    required double reservoirLevel,
    required double inflow,
    required double barrageOutflow,
    required String weather,
  }) {
    String dateStr = DateFormat('dd/MM/yyyy').format(date);

    return '''1. Site: Naitwar Mori HPS (SJVN)
2. Date: *$dateStr*
3. Time: *$time hrs*
4. River: Tons
5. Upstream River Level: *${reservoirLevel.toStringAsFixed(2)}m*
6. Full Reservoir Level (As per Design): 1267.00m
7. Maximum Water Level: 1268.00m
8. Barrage Top Level: 1269.50m
9. Current River Discharge (Inflow): *${inflow.toStringAsFixed(2)} cumecs*
10. *Outflow Through Barrage: ${barrageOutflow.toStringAsFixed(2)} cumecs* 
11. Last Year Maximum Discharge for the Month of August '2025 = 776.91 cumecs
12. Weather: *$weather*''';
  }
}