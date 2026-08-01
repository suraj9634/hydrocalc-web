class EFlowService {
  static const List<double> reservoirLevels = [
    1261.00,1261.10,1261.20,1261.30,1261.40,
    1261.50,1261.60,1261.70,1261.80,1261.90,
    1262.00,1262.10,1262.20,1262.30,1262.40,
    1262.50,1262.60,1262.70,1262.80,1262.90,
    1263.00,1263.10,1263.20,1263.30,1263.40,
    1263.50,1263.60,1263.70,1263.80,1263.90,
    1264.00,1264.10,1264.20,1264.30,1264.40,
    1264.50,1264.60,1264.70,1264.80,1264.90,
    1265.00,1265.10,1265.20,1265.30,1265.40,
    1265.50,1265.60,1265.70,1265.80,1265.90,
    1266.00,1266.10,1266.20,1266.30,1266.40,
    1266.50,1266.60,1266.70,1266.80,1266.90,
    1267.00,
  ];

  static const List<double> discharge = [
    5.94,5.97,6.00,6.02,6.05,
    6.08,6.10,6.13,6.16,6.18,
    6.21,6.24,6.26,6.29,6.32,
    6.34,6.37,6.39,6.42,6.44,
    6.47,6.49,6.52,6.54,6.57,
    6.59,6.62,6.64,6.67,6.69,
    6.72,6.74,6.77,6.79,6.82,
    6.84,6.86,6.89,6.91,6.93,
    6.96,6.98,7.01,7.03,7.05,
    7.08,7.10,7.12,7.14,7.17,
    7.19,7.21,7.24,7.26,7.28,
    7.30,7.33,7.35,7.37,7.39,
    7.42,
  ];

  static double getDischarge({
    required double reservoirLevel,
  }) {
    if (reservoirLevel <= reservoirLevels.first) {
      return discharge.first;
    }

    if (reservoirLevel >= reservoirLevels.last) {
      return discharge.last;
    }

    for (int i = 0; i < reservoirLevels.length - 1; i++) {
      if (reservoirLevel >= reservoirLevels[i] &&
          reservoirLevel <= reservoirLevels[i + 1]) {

        double x1 = reservoirLevels[i];
        double x2 = reservoirLevels[i + 1];

        double y1 = discharge[i];
        double y2 = discharge[i + 1];

        return y1 +
            ((reservoirLevel - x1) / (x2 - x1)) *
                (y2 - y1);
      }
    }

    return 0.0;
  }
}