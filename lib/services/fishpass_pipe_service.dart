class FishpassPipeService {
  static const List<double> reservoirLevels = [
    1261.00,
    1261.20,
    1261.40,
    1261.60,
    1261.80,
    1262.00,
    1262.20,
    1262.40,
    1262.60,
    1262.80,
    1263.00,
    1263.20,
    1263.40,
    1263.60,
    1263.80,
    1264.00,
    1264.20,
    1264.40,
    1264.60,
    1264.80,
    1265.00,
    1265.20,
    1265.40,
    1265.60,
    1265.80,
    1266.00,
    1266.20,
    1266.40,
    1266.60,
    1266.80,
    1267.00,
  ];

  static const List<double> discharge = [
    0.48,
    0.58,
    0.67,
    0.75,
    0.82,
    0.89,
    0.95,
    1.01,
    1.06,
    1.11,
    1.16,
    1.21,
    1.26,
    1.30,
    1.34,
    1.39,
    1.43,
    1.46,
    1.50,
    1.54,
    1.58,
    1.61,
    1.65,
    1.68,
    1.71,
    1.75,
    1.78,
    1.81,
    1.84,
    1.87,
    1.90,
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