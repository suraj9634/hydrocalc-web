class SFTService {

  static const List<double> waterLevels = [
    1261.00,
    1261.50,
    1262.00,
    1262.50,
    1263.00,
    1263.50,
    1264.00,
    1264.50,
    1265.00,
    1265.50,
    1266.00,
    1266.50,
    1267.00,
  ];

  static final Map<double,List<double>> dischargeTable = {

    0.15:[
      1.43,1.45,1.48,1.50,1.52,1.54,1.56,
      1.58,1.60,1.62,1.64,1.66,1.68
    ],

    0.30:[
      2.86,2.90,2.95,2.99,3.03,3.07,3.12,
      3.16,3.20,3.24,3.28,3.32,3.35
    ],

    0.45:[
      4.28,4.34,4.41,4.47,4.54,4.60,4.66,
      4.73,4.79,4.85,4.91,4.96,5.02
    ],

    0.60:[
      5.69,5.78,5.86,5.95,6.04,6.12,6.21,
      6.29,6.37,6.45,6.53,6.61,6.69
    ],

    0.75:[
      7.09,7.20,7.31,7.42,7.53,7.64,7.74,
      7.85,7.95,8.05,8.15,8.25,8.34
    ],

    0.90:[
      8.49,8.62,8.76,8.89,9.02,9.15,9.27,
      9.40,9.52,9.64,9.76,9.88,9.99
    ],

    1.05:[
      9.88,10.04,10.19,10.35,10.50,10.65,10.80,
      10.94,11.08,11.22,11.36,11.50,11.64
    ],

    1.20:[
      11.26,11.45,11.62,11.80,11.97,12.14,12.31,
      12.48,12.64,12.80,12.96,13.12,13.28
    ],

    1.35:[
      12.64,12.85,13.05,13.25,13.44,13.63,13.82,
      14.01,14.20,14.38,14.56,14.74,14.91
    ],

    1.50:[
      14.01,14.24,14.46,14.68,14.90,15.12,15.33,
      15.54,15.74,15.94,16.15,16.34,16.54
    ],

  };
    static double interpolate(
      double x,
      double x1,
      double x2,
      double y1,
      double y2) {

    if (x1 == x2) return y1;

    return y1 +
        ((x - x1) / (x2 - x1)) *
            (y2 - y1);
  }

  static double getDischarge({

    required double waterLevel,
    required double gateOpeningMm,

  }) {

    double opening = gateOpeningMm / 1000;

    if (opening < 0.15 || opening > 1.50) {
      return 0;
    }

    if (waterLevel < waterLevels.first ||
        waterLevel > waterLevels.last) {
      return 0;
    }

    List<double> openings =
        dischargeTable.keys.toList()..sort();

    double lowerOpening = openings.first;
    double upperOpening = openings.last;

    for (int i = 0; i < openings.length - 1; i++) {

      if (opening >= openings[i] &&
          opening <= openings[i + 1]) {

        lowerOpening = openings[i];
        upperOpening = openings[i + 1];
        break;
      }
    }

    double lowerLevel = waterLevels.first;
    double upperLevel = waterLevels.last;

    for (int i = 0; i < waterLevels.length - 1; i++) {

      if (waterLevel >= waterLevels[i] &&
          waterLevel <= waterLevels[i + 1]) {

        lowerLevel = waterLevels[i];
        upperLevel = waterLevels[i + 1];
        break;
      }
    }

    int li = waterLevels.indexOf(lowerLevel);
    int ui = waterLevels.indexOf(upperLevel);

    double q11 = dischargeTable[lowerOpening]![li];
    double q12 = dischargeTable[lowerOpening]![ui];

    double q21 = dischargeTable[upperOpening]![li];
    double q22 = dischargeTable[upperOpening]![ui];

    double lowerResult = interpolate(
      waterLevel,
      lowerLevel,
      upperLevel,
      q11,
      q12,
    );

    double upperResult = interpolate(
      waterLevel,
      lowerLevel,
      upperLevel,
      q21,
      q22,
    );

    double singleSFT = interpolate(
      opening,
      lowerOpening,
      upperOpening,
      lowerResult,
      upperResult,
    );

    return singleSFT ;
  }

}