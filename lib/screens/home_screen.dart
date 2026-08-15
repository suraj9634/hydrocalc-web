import 'package:flutter/material.dart';
import 'hourly_calculator_screen.dart';
import 'history_screen.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("HydroCalc Pro"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            const Icon(
              Icons.water,
              size: 80,
              color: Colors.blue,
            ),

            const SizedBox(height: 15),

            const Text(
              "NMHPS",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
               onPressed: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const HourlyCalculatorScreen(),
    ),
  );
},
                child: const Text("Hourly Calculator"),
              ),
            ),

            const SizedBox(height: 15),

           SizedBox(
            width: double.infinity,
            height: 55,
          child: ElevatedButton(
            onPressed: () {
            Navigator.push(
            context,
           MaterialPageRoute(builder: (context) => const HistoryScreen()),
             );
              },
             child: const Text(
              "History",
              style: TextStyle(fontSize: 18),
             ),
              ),
              ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text("Daily Summary"),
              ),
            ),

            const Spacer(),

            const Text(
              "HydroCalc Pro Version 1.0",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}