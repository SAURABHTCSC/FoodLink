import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/simulation_engine.dart';
import 'auth_simulation.dart';
import 'food_simulation.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final engine = Provider.of<SimulationEngine>(context);

    // AUTOMATICALLY SWITCH FILES BASED ON STATE
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 800),
        child: engine.appStage == 0
            ? const AuthSimulationView() // FILE 1: The "Blue" Login
            : const FoodSimulationView(), // FILE 2: The "Advanced" Food App
      ),
    );
  }
}