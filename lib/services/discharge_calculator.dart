class DischargeCalculator {
  /// -------------------------------
  /// POWER HOUSE DISCHARGE
  /// -------------------------------
  static double calculatePHDischarge({
    required double previousRL,
    required double currentRL,
    required double averageLoad,
  }) {
    double divisor;

    bool prevAbove = previousRL >= 1264.0;
    bool currAbove = currentRL >= 1264.0;

    if (prevAbove && currAbove) {
      divisor = 0.82;
    } else if (!prevAbove && !currAbove) {
      divisor = 0.75;
    } else {
      divisor = (0.82 + 0.75) / 2;
    }

    return averageLoad / divisor;
  }

  /// -------------------------------
  /// FACTOR
  /// -------------------------------
  static double getFactor(double rl) {
    if (rl >= 1261 && rl < 1263) {
      return 9.06;
    }

    if (rl >= 1263 && rl < 1265) {
      return 11.74;
    }

    if (rl >= 1265 && rl <= 1267) {
      return 15.25;
    }

    return 0;
  }

  /// -------------------------------
  /// AVERAGE FACTOR
  /// -------------------------------
  static double calculateFactor({
    required double previousRL,
    required double currentRL,
  }) {
    double f1 = getFactor(previousRL);
    double f2 = getFactor(currentRL);

    if (f1 == f2) {
      return f1;
    }

    return (f1 + f2) / 2;
  }

  /// -------------------------------
  /// LEVEL CORRECTION (X)
  /// -------------------------------
  static double calculateX({
    required double previousRL,
    required double currentRL,
  }) {
    double factor = calculateFactor(
      previousRL: previousRL,
      currentRL: currentRL,
    );

    return (currentRL - previousRL).abs() * factor;
  }

  /// -------------------------------
  /// TOTAL E-FLOW
  /// -------------------------------
  static double totalEFlow({
    required double radial1,
    required double radial2,
    required double radial3,
    required double fdrg,
    required double eFlowPipe,
    required double eFlowChannel,
  }) {
    return radial1 +
        radial2 +
        radial3 +
        fdrg +
        eFlowPipe +
        eFlowChannel;
  }

  /// -------------------------------
  /// TOTAL OUTFLOW
  /// -------------------------------
  static double totalOutflow({
    required double previousRL,
    required double currentRL,
    required double phDischarge,
    required double totalEFlow,
  }) {
    double x = calculateX(
      previousRL: previousRL,
      currentRL: currentRL,
    );

    if (currentRL >= previousRL) {
      return phDischarge + totalEFlow + x;
    }

    return phDischarge + totalEFlow - x;
  }
}