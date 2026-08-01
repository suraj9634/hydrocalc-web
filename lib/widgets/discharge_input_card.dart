import 'package:flutter/material.dart';
import 'input_field.dart';

class DischargeInputCard extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final double discharge;
  final bool readOnly;
  final ValueChanged<String>? onChanged;

  const DischargeInputCard({
    super.key,
    required this.label,
    required this.controller,
    required this.discharge,
    this.readOnly = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [

        Expanded(
          flex: 3,
          child: InputField(
            label: label,
            controller: controller,
            readOnly: readOnly,
            onChanged: onChanged,
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          flex: 2,
          child: Container(
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "${discharge.toStringAsFixed(2)}\nCumecs",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }
}