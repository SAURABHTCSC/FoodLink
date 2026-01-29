import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../logic/simulation_engine.dart';
import 'visual_components.dart';

class AuthSimulationView extends StatefulWidget {
  const AuthSimulationView({super.key});
  @override
  State<AuthSimulationView> createState() => _AuthSimulationViewState();
}

class _AuthSimulationViewState extends State<AuthSimulationView> {
  bool isLogin = true;
  String selectedRole = 'donor';
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final engine = Provider.of<SimulationEngine>(context);
    final size = MediaQuery.of(context).size;

    return Row(
      children: [
        // --- LEFT PANEL ---
        Container(
          width: 400,
          color: const Color(0xFF1E293B),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Text("SECURE ACCESS", style: GoogleFonts.getFont('Fira Code', color: Colors.blueAccent, letterSpacing: 2, fontSize: 20)),
                      const SizedBox(height: 30),
                      Container(
                        width: 280, height: 580,
                        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.5), width: 4)),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(26),
                          child: Scaffold(
                            backgroundColor: const Color(0xFF0F172A),
                            body: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.shield, size: 60, color: Colors.blueAccent),
                                  const SizedBox(height: 10),
                                  Text(isLogin ? "Welcome Back" : "Join the Network", style: const TextStyle(color: Colors.white, fontSize: 16)),
                                  const SizedBox(height: 20),
                                  TextField(controller: _emailCtrl, style: const TextStyle(color: Colors.white), decoration: _buildInputDeco("Email", Icons.email)),
                                  const SizedBox(height: 10),
                                  TextField(controller: _passCtrl, obscureText: true, style: const TextStyle(color: Colors.white), decoration: _buildInputDeco("Password", Icons.lock)),
                                  const SizedBox(height: 20),
                                  ElevatedButton(
                                    onPressed: () => isLogin ? engine.attemptLogin(_emailCtrl.text, _passCtrl.text) : engine.attemptSignup(_emailCtrl.text, _passCtrl.text),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, minimumSize: const Size(double.infinity, 50)),
                                    child: Text(isLogin ? "AUTHENTICATE" : "REGISTER", style: const TextStyle(color: Colors.white)),
                                  ),
                                  TextButton(
                                    onPressed: () => setState(() => isLogin = !isLogin),
                                    child: Text(isLogin ? "Create Account" : "Back to Login", style: const TextStyle(color: Colors.grey)),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20), color: Colors.black26,
                child: Row(children: [const Icon(Icons.speed, color: Colors.blueAccent), Expanded(child: Slider(value: engine.simulationSpeed, min: 0.1, max: 3.0, activeColor: Colors.blueAccent, onChanged: (v) => engine.simulationSpeed = v))]),
              ),
            ],
          ),
        ),

        // --- RIGHT PANEL (SIMULATION) ---
        Expanded(
          child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final h = constraints.maxHeight;

                // FIXED: Define the positions here to pass to PacketWidget
                final donorPos = Offset(100, h / 2);
                final dbPos = Offset(w - 100, h / 2);

                return Stack(
                  children: [
                    Positioned.fill(child: Opacity(opacity: 0.05, child: Image.network("https://img.freepik.com/free-vector/hud-background-interface_1152-97.jpg", fit: BoxFit.cover, errorBuilder: (_,__,___) => Container()))),

                    Positioned(left: donorPos.dx - 40, top: donorPos.dy - 40, child: const NodeWidget(icon: Icons.smartphone, label: "CLIENT", color: Colors.blueAccent)),
                    Positioned(left: dbPos.dx - 40, top: dbPos.dy - 40, child: const NodeWidget(icon: FontAwesomeIcons.database, label: "SUPABASE AUTH", color: Colors.purpleAccent)),

                    Center(child: Container(width: w, height: 2, color: Colors.white10)),

                    // FIXED: Passing the required positions to PacketWidget
                    ...engine.activePackets.map((p) => PacketWidget(
                      packet: p,
                      dbPos: dbPos,
                      donorPos: donorPos,
                      ngoPositions: const [], // Empty for Auth screen
                    )),

                    Positioned(top: 50, left: 0, right: 0, child: Center(child: Text("WAITING FOR VERIFICATION...", style: GoogleFonts.getFont('Fira Code', color: Colors.white24, fontSize: 24)))),

                    // FIXED: logs getter is now available in Engine
                    Positioned(
                      bottom: 20, left: 20, right: 20, height: 150,
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3))),
                        child: ListView.builder(
                          itemCount: engine.logs.length,
                          itemBuilder: (ctx, i) => Text(engine.logs[engine.logs.length - 1 - i], style: GoogleFonts.getFont('Fira Code', color: Colors.blueAccent, fontSize: 12)),
                        ),
                      ),
                    )
                  ],
                );
              }
          ),
        )
      ],
    );
  }

  InputDecoration _buildInputDeco(String hint, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: Colors.blueAccent),
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
      filled: true, fillColor: Colors.white.withValues(alpha: 0.1),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
    );
  }
}