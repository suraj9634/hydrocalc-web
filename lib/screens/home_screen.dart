import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'hourly_calculator_screen.dart';
import 'history_screen.dart';
import 'daily_summary_screen.dart';
import 'analytics_screen.dart';
import 'login_screen.dart';

class HomePage extends StatelessWidget {
  final String currentRole;

  const HomePage({super.key, this.currentRole = 'Group A'});

  Future<void> _handleLogout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text(
          "HydroCalc Pro",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            tooltip: "Logout",
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  
                  // Header Card with NMHPS & Active Role
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const CircleAvatar(
                          radius: 36,
                          backgroundColor: Color(0xFFE0E7FF),
                          child: Icon(Icons.water, size: 42, color: Color(0xFF1E3A8A)),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "NMHPS",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Chip(
                          avatar: const Icon(Icons.shield_outlined, size: 18, color: Colors.white),
                          label: Text(
                            "Logged in: $currentRole",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          backgroundColor: const Color(0xFF1E3A8A),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action Navigation Buttons
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildNavButton(
                          context: context,
                          title: "HOURLY CALCULATOR",
                          subtitle: "Record barrage levels & calculate discharge",
                          icon: Icons.calculate_outlined,
                          color: const Color(0xFF1E3A8A),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HourlyCalculatorScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        _buildNavButton(
                          context: context,
                          title: "HISTORY LOGS",
                          subtitle: "Review past hourly discharge submissions",
                          icon: Icons.history_rounded,
                          color: const Color(0xFF2563EB),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HistoryScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        _buildNavButton(
                          context: context,
                          title: "DAILY SUMMARY",
                          subtitle: "Aggregated discharge and day totals",
                          icon: Icons.analytics_outlined,
                          color: const Color(0xFF0F766E),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const DailySummaryScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        _buildNavButton(
                          context: context,
                          title: "TREND ANALYTICS",
                          subtitle: "Discharge patterns and level trends",
                          icon: Icons.show_chart_rounded,
                          color: const Color(0xFF0D9488),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AnalyticsScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Text(
                    "HydroCalc Pro • Version 1.0",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: color.withOpacity(0.12),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}