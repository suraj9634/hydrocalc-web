class FreeflowService {
  // Gate opening heights from your table (in metres)
  static const List<double> gateOpenings = [
    2.0, 2.2, 2.4, 2.6, 2.8, 3.0, 3.2, 3.4, 3.6, 3.8, 4.0, 
    4.2, 4.4, 4.6, 4.8, 5.0, 5.2, 5.4, 5.6, 5.8, 6.0, 
    6.2, 6.4, 6.6, 6.8, 7.0, 7.2, 7.4, 7.6, 7.8, 8.0
  ];

  // Corresponding 'Q (Cumecs) for one gate' from your freeflow table
  static const List<double> discharge = [
    46, 53, 61, 68, 76, 84, 93, 102, 111, 120, 130, 
    140, 150, 160, 171, 181, 192, 209, 221, 232, 244, 
    256, 269, 281, 294, 307, 320, 333, 346, 360, 373
  ];

  static double getDischarge({required double gateOpeningMm}) {
    // Convert mm to metres to match the table format
    double openingMeters = gateOpeningMm / 1000.0;

    if (openingMeters <= gateOpenings.first) {
      return discharge.first;
    }
    if (openingMeters >= gateOpenings.last) {
      return discharge.last;
    }

    for (int i = 0; i < gateOpenings.length - 1; i++) {
      if (openingMeters >= gateOpenings[i] &&
          openingMeters <= gateOpenings[i + 1]) {
        double x1 = gateOpenings[i];
        double x2 = gateOpenings[i + 1];
        double y1 = discharge[i];
        double y2 = discharge[i + 1];
        
        // Linear interpolation
        return y1 + ((openingMeters - x1) / (x2 - x1)) * (y2 - y1);
      }
    }
    return 0.0;
  }
}