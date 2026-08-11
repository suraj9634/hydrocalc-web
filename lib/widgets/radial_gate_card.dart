import 'package:flutter/material.dart';
import 'input_field.dart';

class RadialGateCard extends StatelessWidget {
  final String label;
  final TextEditingController openingController;
  final TextEditingController gatedMinsController;
  final TextEditingController freeflowOpeningController; // Freeflow opening input
  final TextEditingController freeflowMinsController;
  final double totalDischarge;
  final VoidCallback onChanged;

  const RadialGateCard({
    super.key,
    required this.label,
    required this.openingController,
    required this.gatedMinsController,
    required this.freeflowOpeningController,
    required this.freeflowMinsController,
    required this.totalDischarge,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          // Row 1: Gated Opening & Gated Minutes
          Row(
            children: [
              Expanded(
                child: InputField(
                  label: "Opening (mm)",
                  controller: openingController,
                  onChanged: (val) => onChanged(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InputField(
                  label: "Gated (mins)",
                  controller: gatedMinsController,
                  onChanged: (val) => onChanged(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Row 2: Freeflow Opening & Freeflow Minutes
          Row(
            children: [
              Expanded(
                child: InputField(
                  label: "Freeflow Opening (mm)",
                  controller: freeflowOpeningController,
                  onChanged: (val) => onChanged(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InputField(
                  label: "Freeflow (mins)",
                  controller: freeflowMinsController,
                  onChanged: (val) => onChanged(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              "Discharge: ${totalDischarge.toStringAsFixed(2)} Cumecs",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}