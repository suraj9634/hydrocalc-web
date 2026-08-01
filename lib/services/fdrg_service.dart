class FDRGService {
  static const List<double> openings = [
    0,
    100,
    200,
    300,
    400,
    500,
    600,
    700,
    800,
    900,
    1000,
    1100,
    1200,
    1300,
    1400,
    1500,
    1600,
    1700,
    1800,
    1900,
    2000,
  ];

  static const List<double> discharge = [
    0.00,
    0.36,
    1.03,
    1.88,
    2.89,
    4.02,
    5.27,
    6.62,
    8.06,
    9.59,
    11.20,
    12.88,
    14.63,
    16.45,
    18.32,
    20.25,
    22.24,
    24.28,
    26.37,
    28.51,
    30.69,
  ];

  static double getDischarge({
    required double gateOpeningMm,
  }) {
    if (gateOpeningMm <= openings.first) {
      return discharge.first;
    }

    if (gateOpeningMm >= openings.last) {
      return discharge.last;
    }

    for (int i = 0; i < openings.length - 1; i++) {
      if (gateOpeningMm >= openings[i] &&
          gateOpeningMm <= openings[i + 1]) {
        double x1 = openings[i];
        double x2 = openings[i + 1];

        double y1 = discharge[i];
        double y2 = discharge[i + 1];

        return y1 +
            ((gateOpeningMm - x1) / (x2 - x1)) *
                (y2 - y1);
      }
    }

    return 0.0;
  }
}