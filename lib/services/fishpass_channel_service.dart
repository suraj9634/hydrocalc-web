class FishpassChannelService {
  static const List<double> reservoirLevels = [
    1266.20,
    1266.30,
    1266.40,
    1266.50,
    1266.60,
    1266.70,
    1266.80,
    1266.90,
    1267.00,
  ];

  static const List<double> discharge = [
    0.00,
    0.13,
    0.38,
    0.71,
    1.09,
    1.51,
    1.96,
    2.43,
    2.93,
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