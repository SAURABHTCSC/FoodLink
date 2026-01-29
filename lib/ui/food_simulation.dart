import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../logic/simulation_engine.dart';
import 'visual_components.dart';

class FoodSimulationView extends StatefulWidget {
  const FoodSimulationView({super.key});
  @override
  State<FoodSimulationView> createState() => _FoodSimulationViewState();
}

class _FoodSimulationViewState extends State<FoodSimulationView> with SingleTickerProviderStateMixin {
  int _tab = 0;
  final _foodCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
  }

  @override
  void dispose() { _pulseController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final engine = Provider.of<SimulationEngine>(context);
    final size = MediaQuery.of(context).size;
    if (engine.isBroadcasting && !_pulseController.isAnimating) _pulseController.forward(from: 0).then((_) => engine.isBroadcasting = false);

    return Row(
      children: [
        // --- LEFT PANEL ---
        Container(
          width: 400, color: const Color(0xFF1E293B),
          child: Column(
            children: [
              const SizedBox(height: 30),
              Text("FOODLINK NETWORK", style: GoogleFonts.getFont('Fira Code', color: Colors.greenAccent, letterSpacing: 2, fontSize: 24)),
              const SizedBox(height: 10),
              Expanded(
                child: Container(
                  width: 320, margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.grey.shade800, width: 4)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: Scaffold(
                      backgroundColor: const Color(0xFF121212),
                      appBar: AppBar(
                        title: Text(_tab == 0 ? "Donor Portal" : "NGO Feed"),
                        backgroundColor: _tab == 0 ? Colors.green[800] : Colors.orange[800],
                        actions: [
                          // FIXED: CLEAR LOGOUT BUTTON
                          TextButton.icon(
                              icon: const Icon(Icons.logout, color: Colors.white),
                              label: const Text("LOGOUT", style: TextStyle(color: Colors.white, fontSize: 12)),
                              onPressed: () => engine.appStage = 0
                          )
                        ],
                      ),
                      body: _tab == 0 ? _buildDonorUI(engine) : _buildNGOUI(engine),
                      bottomNavigationBar: BottomNavigationBar(
                        backgroundColor: const Color(0xFF1E1E1E), selectedItemColor: _tab == 0 ? Colors.greenAccent : Colors.orangeAccent, unselectedItemColor: Colors.grey,
                        currentIndex: _tab, onTap: (i) => setState(() => _tab = i),
                        items: const [BottomNavigationBarItem(icon: Icon(Icons.volunteer_activism), label: "Donor"), BottomNavigationBarItem(icon: Icon(Icons.list), label: "NGO")],
                      ),
                    ),
                  ),
                ),
              ),
              _buildControlPanel(engine),

              // NEW: FOOTER
              Padding(
                padding: const EdgeInsets.all(10),
                child: Text("Made by CC 13B", style: GoogleFonts.firaCode(color: Colors.grey, fontSize: 10)),
              )
            ],
          ),
        ),

        // --- RIGHT PANEL ---
        Expanded(
          child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth; final h = constraints.maxHeight;
                final dbPos = Offset(w - 150, h / 2);
                final donorPos = Offset(100, h / 2);
                final gaPos = Offset(w - 60, 60); // ANALYTICS LOGO POSITION

                final ngoPositions = [
                  Offset(w * 0.4, h * 0.2), Offset(w * 0.5, h * 0.15), Offset(w * 0.6, h * 0.2),
                  Offset(w * 0.45, h * 0.8), Offset(w * 0.55, h * 0.8),
                ];

                return Stack(
                  children: [
                    Positioned.fill(child: Opacity(opacity: 0.05, child: Image.network("https://img.freepik.com/free-vector/hud-background-interface_1152-97.jpg", fit: BoxFit.cover, errorBuilder: (_,__,___) => Container()))),

                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (ctx, child) => CustomPaint(size: Size(w, h), painter: NetworkGridPainter(dbPosition: dbPos, ngoPositions: ngoPositions, pulseValue: _pulseController.value, isBroadcasting: _pulseController.isAnimating)),
                    ),

                    Positioned(left: donorPos.dx - 40, top: donorPos.dy - 40, child: const NodeWidget(icon: Icons.smartphone, label: "DONOR APP")),
                    Positioned(left: dbPos.dx - 40, top: dbPos.dy - 40, child: const NodeWidget(icon: FontAwesomeIcons.database, label: "SUPABASE", color: Colors.greenAccent)),

                    // NEW: GOOGLE ANALYTICS NODE
                    Positioned(
                        left: gaPos.dx - 30, top: gaPos.dy - 30,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                              color: const Color(0xFF1E293B), shape: BoxShape.circle,
                              border: Border.all(color: engine.isAnalyticsBlinking ? const Color(0xFFE37400) : Colors.grey.withValues(alpha: 0.3), width: 2),
                              boxShadow: [BoxShadow(color: (engine.isAnalyticsBlinking ? const Color(0xFFE37400) : Colors.transparent).withValues(alpha: 0.5), blurRadius: 20)]
                          ),
                          child: const Icon(FontAwesomeIcons.google, color: Color(0xFFE37400), size: 30),
                        )
                    ),
                    Positioned(top: 100, right: 30, child: Text("ANALYTICS", style: GoogleFonts.firaCode(color: const Color(0xFFE37400), fontSize: 10))),

                    for (int i = 0; i < ngoPositions.length; i++)
                      Positioned(
                        left: ngoPositions[i].dx - 25, top: ngoPositions[i].dy - 25,
                        child: GestureDetector(
                          onTap: () => setState(() => engine.activeNgoIndex = i),
                          child: NodeWidget(
                            icon: FontAwesomeIcons.handHoldingHeart,
                            label: engine.ngoList.isNotEmpty && i < engine.ngoList.length ? engine.ngoList[i] : "NGO ${i+1}",
                            color: Colors.cyan, isSmall: true, isActive: engine.activeNgoIndex == i,
                          ),
                        ),
                      ),

                    // UPDATE PACKET WIDGET TO HANDLE GA FLIGHT
                    ...engine.activePackets.map((p) => PacketWidget(packet: p, dbPos: dbPos, donorPos: donorPos, ngoPositions: ngoPositions, gaPos: gaPos)),

                    Positioned(top: 40, right: 120, child: _buildImpactStats(engine)),
                    Positioned(bottom: 20, left: 20, right: 20, height: 180, child: _buildCmdTerminal(engine)),
                  ],
                );
              }
          ),
        )
      ],
    );
  }

  // --- UI PARTS (Unchanged logic, just keeping structure) ---
  Widget _buildDonorUI(SimulationEngine engine) {
    final latestItem = engine.donationsTable.isNotEmpty ? engine.donationsTable.last : null;
    final isClaimed = latestItem != null && latestItem.status == 'Claimed';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Quick Add:", style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 5),
          Wrap(spacing: 8, runSpacing: 8, children: ["Rice (10kg)", "Bread (50)", "Curry (5L)", "Fruits"].map((t) => ActionChip(
            label: Text(t, style: const TextStyle(color: Colors.black)), backgroundColor: Colors.greenAccent,
            onPressed: () { _foodCtrl.text = t.split(' (')[0]; _qtyCtrl.text = t.contains('(') ? t.split('(')[1].replaceAll(')', '') : '10kg'; },
          )).toList()),
          const SizedBox(height: 20),
          TextField(controller: _foodCtrl, style: const TextStyle(color: Colors.white), decoration: _inputDeco("Food Item", Icons.fastfood)),
          const SizedBox(height: 10),
          TextField(controller: _qtyCtrl, style: const TextStyle(color: Colors.white), decoration: _inputDeco("Quantity", Icons.scale)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
              icon: const Icon(Icons.broadcast_on_personal), label: const Text("BROADCAST REQUEST"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () => engine.postDonation(_foodCtrl.text, _qtyCtrl.text)
          ),
          const SizedBox(height: 30),
          if (latestItem != null)
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: isClaimed ? Colors.green.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2), border: Border.all(color: isClaimed ? Colors.green : Colors.orange), borderRadius: BorderRadius.circular(10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [Icon(isClaimed ? Icons.check_circle : Icons.hourglass_top, color: isClaimed ? Colors.green : Colors.orange), const SizedBox(width: 10), Text(isClaimed ? "PICKUP CONFIRMED" : "WAITING FOR NGO...", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
                  const SizedBox(height: 10),
                  Text("Item: ${latestItem.foodItem} (${latestItem.quantity})", style: const TextStyle(color: Colors.white70)),
                  if (isClaimed) ...[
                    const Divider(color: Colors.white24),
                    Text("Claimed by: ${latestItem.claimedBy ?? 'Unknown'}", style: const TextStyle(color: Colors.greenAccent)),
                    Text("ETA: ${latestItem.eta ?? '15 mins'}", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                  ]
                ],
              ),
            )
        ],
      ),
    );
  }

  Widget _buildNGOUI(SimulationEngine engine) {
    return Column(children: [
      Container(width: double.infinity, padding: const EdgeInsets.all(10), color: Colors.orange[900], child: Text("Logged in as: NGO #${engine.activeNgoIndex + 1}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
      Expanded(child: ListView.builder(itemCount: engine.donationsTable.length, itemBuilder: (ctx, i) {
        final item = engine.donationsTable[i];
        bool isMine = item.claimedBy != null && item.claimedBy!.contains((engine.activeNgoIndex + 1).toString());
        return Card(
          color: const Color(0xFF2C2C2C), margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: ListTile(
            leading: const Icon(Icons.fastfood, color: Colors.orange),
            title: Text(item.foodItem, style: const TextStyle(color: Colors.white)),
            subtitle: Text(item.status == 'Claimed' ? "Claimed by ${item.claimedBy}" : "${item.quantity} • Available", style: TextStyle(color: Colors.grey[400], fontSize: 12)),
            trailing: item.status == 'Available' ? ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.orange), onPressed: () => engine.claimDonation(item.id), child: const Text("ACCEPT", style: TextStyle(color: Colors.white))) : Icon(Icons.check_circle, color: isMine ? Colors.green : Colors.grey),
          ),
        );
      })),
    ]);
  }

  Widget _buildCmdTerminal(SimulationEngine engine) {
    return Container(
      padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.5), width: 2)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [const Icon(Icons.terminal, color: Colors.greenAccent, size: 16), const SizedBox(width: 8), Text("SERVER TERMINAL", style: GoogleFonts.firaCode(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold))]),
        const Divider(color: Colors.greenAccent),
        Expanded(child: ListView.builder(reverse: true, itemCount: engine.logs.length, itemBuilder: (ctx, i) => Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Text(engine.logs[engine.logs.length - 1 - i], style: GoogleFonts.firaCode(color: engine.logs[engine.logs.length - 1 - i].contains("ERROR") ? Colors.redAccent : Colors.greenAccent, fontSize: 11)))))
      ]),
    );
  }

  Widget _buildImpactStats(SimulationEngine engine) {
    return Row(children: [_statCard("MEALS", "${engine.mealsSaved}", Colors.orange), const SizedBox(width: 10), _statCard("CO2", "${engine.co2Saved.toInt()}kg", Colors.green)]);
  }

  Widget _statCard(String label, String val, Color c) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10), decoration: BoxDecoration(color: Colors.black87, border: Border.all(color: c), borderRadius: BorderRadius.circular(10)), child: Column(children: [Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)), Text(label, style: TextStyle(color: c, fontSize: 10))]));
  }

  Widget _buildControlPanel(SimulationEngine engine) {
    return Container(padding: const EdgeInsets.all(10), color: Colors.black26, child: Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Active NGO:", style: TextStyle(color: Colors.grey, fontSize: 12)), DropdownButton<int>(value: engine.activeNgoIndex, dropdownColor: Colors.grey[900], style: const TextStyle(color: Colors.cyan), items: List.generate(5, (i) => DropdownMenuItem(value: i, child: Text("NGO #${i+1}"))), onChanged: (v) => setState(() => engine.activeNgoIndex = v!))]),
      SwitchListTile(title: const Text("Simulate DB Crash", style: TextStyle(color: Colors.white, fontSize: 10)), value: engine.forceDbCrash, activeColor: Colors.red, onChanged: (v) => engine.forceDbCrash = v),
    ]));
  }

  InputDecoration _inputDeco(String hint, IconData icon) {
    return InputDecoration(prefixIcon: Icon(icon, color: Colors.grey), hintText: hint, hintStyle: const TextStyle(color: Colors.grey), filled: true, fillColor: Colors.white10, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white24)));
  }
}