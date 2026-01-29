import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'logic/simulation_engine.dart';
import 'ui/dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. INITIALIZE SUPABASE
  await Supabase.initialize(
    url: 'https://cfpjmpnnnvadiilkmihb.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNmcGptcG5ubnZhZGlpbGttaWhiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk2MTU4OTAsImV4cCI6MjA4NTE5MTg5MH0.sOvuOoSN85zbXcJpSn2f1zAK7xNbpk3WtHyjraDBqmA',
  );

  runApp(const FoodLinkApp());
}

class FoodLinkApp extends StatelessWidget {
  const FoodLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SimulationEngine()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'FoodLink Simulation',
        theme: ThemeData.dark(),
        home: const DashboardScreen(),
      ),
    );
  }
}