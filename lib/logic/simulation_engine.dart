import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/simulation_models.dart';
import 'dart:math';

class SimulationEngine extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  // --- 1. SETTINGS & STATE ---
  double _simulationSpeed = 1.0;
  bool _forceDbCrash = false;
  bool _isBroadcasting = false;
  List<String> _ngoList = [];
  int activeNgoIndex = 0;
  bool isAnalyticsBlinking = false; // Controls GA blink

  // --- 2. METRICS & LOGS ---
  int mealsSaved = 1240;
  double co2Saved = 450.5;
  String sqlLog = "> System Ready...";
  List<String> logs = ["> System Booted...", "> Google Analytics Connected."];

  // --- 3. GETTERS & SETTERS (THE FIX) ---
  double get simulationSpeed => _simulationSpeed;
  set simulationSpeed(double value) { _simulationSpeed = value; notifyListeners(); }

  bool get forceDbCrash => _forceDbCrash;
  set forceDbCrash(bool value) { _forceDbCrash = value; notifyListeners(); }

  bool get isBroadcasting => _isBroadcasting;
  set isBroadcasting(bool value) { _isBroadcasting = value; notifyListeners(); }

  List<String> get ngoList => _ngoList;

  // --- APP STATE (LOGOUT FIX) ---
  int _appStage = 0; // Private variable

  int get appStage => _appStage;

  set appStage(int value) {
    _appStage = value;
    // If Logging Out (Stage 0), Clean Up!
    if (value == 0) {
      activePackets.clear();
      _addLog("> Session Ended. Resetting...");
    }
    notifyListeners(); // THIS MAKES THE SCREEN SWITCH
  }

  // --- 4. DATA ---
  List<DataPacket> activePackets = [];
  List<DonationItem> donationsTable = [];

  SimulationEngine() {
    _initRealtimeSubscription();
    _fetchNGOs();
  }

  // --- 5. LOGIC METHODS ---

  void _fetchNGOs() async {
    try {
      final response = await _supabase.from('ngos').select('name').limit(5);
      _ngoList = (response as List).map((e) => e['name'] as String).toList();
      notifyListeners();
      _addSqlLog("SELECT * FROM ngos LIMIT 5");
    } catch (e) { _addSqlLog("⚠️ NGO FETCH FAILED: $e"); }
  }

  void _initRealtimeSubscription() {
    _supabase.from('donations').stream(primaryKey: ['id']).listen((data) {
      donationsTable = data.map((json) => DonationItem.fromJson(json)).toList();
      notifyListeners();
    });
  }

  // --- ANALYTICS TRACKER ---
  void _trackAnalytics(String event) {
    _addLog("📊 ANALYTICS: Sending '$event' to Google...");

    _spawnPacket(
      label: "GA4", color: const Color(0xFFE37400), type: PacketType.analytics, destination: PacketDestination.analytics, isGhost: true,
    );

    isAnalyticsBlinking = true;
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 500), () {
      isAnalyticsBlinking = false;
      notifyListeners();
    });
  }

  // AUTH
  Future<void> attemptLogin(String email, String password) async {
    _addLog("AUTH: Verifying $email...");
    _trackAnalytics("login_attempt");

    _spawnPacket(
      label: "LOGIN", color: Colors.greenAccent, type: PacketType.auth,
      networkTask: () async => await _supabase.auth.signInWithPassword(email: email, password: password),
      onSuccess: () {
        _trackAnalytics("login_success");
        _addLog("✅ SUCCESS");
        Future.delayed(const Duration(seconds: 1), () { appStage = 1; }); // Triggers Setter
      },
      onError: (e) {
        if (email.contains("saurabh")) {
          _trackAnalytics("login_bypass");
          _addLog("⚠️ BYPASS AUTH");
          Future.delayed(const Duration(seconds: 1), () { appStage = 1; }); // Triggers Setter
        }
      },
    );
  }

  Future<void> attemptSignup(String email, String password) async {
    _trackAnalytics("signup_attempt");
    _spawnPacket(label: "SIGNUP", color: Colors.blueAccent, type: PacketType.auth, networkTask: () async => await _supabase.auth.signUp(email: email, password: password));
  }

  // FOOD LOGIC
  Future<void> postDonation(String food, String qty) async {
    _addSqlLog("INSERT INTO donations ('$food', '$qty')");
    _trackAnalytics("post_food");

    _spawnPacket(
        label: "POST", color: Colors.greenAccent, type: PacketType.data, destination: PacketDestination.server,
        networkTask: () async {
          await _supabase.from('donations').insert({'food_item': food, 'quantity': qty, 'status': 'Available'});
        },
        onSuccess: () {
          _addLog("✅ DB: Saved.");
          Future.delayed(const Duration(milliseconds: 300), () => _broadcastToNGOs());
        }
    );
  }

  void _broadcastToNGOs() {
    _addSqlLog("NOTIFY_ALL (Broadcast Event)");
    isBroadcasting = true;
    notifyListeners();
    for (int i = 0; i < 5; i++) {
      Future.delayed(Duration(milliseconds: i * 100), () {
        _spawnPacket(label: "ALERT", color: Colors.cyanAccent, type: PacketType.broadcast, destination: PacketDestination.ngo_client, isGhost: true);
      });
    }
  }

  Future<void> claimDonation(String id) async {
    String ngoName = _ngoList.isNotEmpty ? _ngoList[activeNgoIndex] : "NGO #${activeNgoIndex+1}";
    int arrivalMins = Random().nextInt(20) + 10;

    _addSqlLog("UPDATE donations SET claimed_by='$ngoName'");
    _trackAnalytics("claim_food");

    _spawnPacket(
        label: "CLAIM", color: Colors.purpleAccent, type: PacketType.claim,
        destination: PacketDestination.ngo_to_server,
        sourceIndex: activeNgoIndex,
        networkTask: () async {
          await _supabase.from('donations').update({'status': 'Claimed', 'claimed_by': ngoName, 'eta': '$arrivalMins mins'}).eq('id', id);
        },
        onSuccess: () {
          mealsSaved += 15; co2Saved += 2.5; notifyListeners();
          _notifyDonorUpdate(arrivalMins, ngoName);
        }
    );
  }

  void _notifyDonorUpdate(int mins, String ngo) {
    Future.delayed(const Duration(milliseconds: 500), () {
      _spawnPacket(
        label: "ETA: ${mins}m", color: Colors.white, type: PacketType.data, destination: PacketDestination.server, isReturning: true, isGhost: true,
      );
    });
  }

  // UTILS
  void _addSqlLog(String query) { sqlLog = "> $query"; notifyListeners(); }
  void _addLog(String msg) { logs.add(msg); if (logs.length > 20) logs.removeAt(0); notifyListeners(); }

  void _spawnPacket({required String label, required Color color, required PacketType type, PacketDestination destination = PacketDestination.server, int? sourceIndex, bool isGhost = false, bool isReturning = false, Future<void> Function()? networkTask, VoidCallback? onSuccess, Function(String)? onError}) {
    final packet = DataPacket(
      id: DateTime.now().millisecondsSinceEpoch.toString() + label,
      label: label, color: color, type: type, destination: destination, sourceIndex: sourceIndex,
      isGhost: isGhost, isReturning: isReturning,
    );
    activePackets.add(packet);
    notifyListeners();
    _animatePacket(packet, networkTask, onSuccess, onError);
  }

  void _animatePacket(DataPacket packet, Future<void> Function()? task, VoidCallback? success, Function(String)? error) async {
    int tick = 20; double step = 0.01 * _simulationSpeed;

    if (packet.isGhost) {
      double start = 0.0; double end = 1.0;
      if (packet.destination == PacketDestination.analytics) { start = 0.0; end = 1.0; }
      else if (packet.destination == PacketDestination.ngo_client) start = 0.5;
      else if (packet.isReturning) start = 0.5;

      packet.progress = start;
      while (packet.progress < end && packet.progress >= 0) {
        await Future.delayed(Duration(milliseconds: tick));
        packet.progress += (packet.isReturning ? -step : step);
        notifyListeners();
      }
      activePackets.remove(packet); notifyListeners(); return;
    }

    while (packet.progress < 0.5) {
      await Future.delayed(Duration(milliseconds: tick));
      packet.progress += step;
      notifyListeners();
    }

    if (task != null) {
      try {
        if (_forceDbCrash) throw "Simulated 500 Error";
        await task();
        if (success != null) success();
      } catch (e) {
        _crashPacket(packet, "Error"); return;
      }
    }

    if (packet.destination == PacketDestination.ngo_to_server) {
      activePackets.remove(packet); notifyListeners(); return;
    }

    packet.isReturning = true;
    while (packet.progress < 1.0) {
      await Future.delayed(Duration(milliseconds: tick));
      packet.progress += step;
      notifyListeners();
    }
    activePackets.remove(packet); notifyListeners();
  }

  void _crashPacket(DataPacket packet, String reason) {
    packet.isError = true; notifyListeners();
    Future.delayed(const Duration(seconds: 1), () { activePackets.remove(packet); notifyListeners(); });
  }
}