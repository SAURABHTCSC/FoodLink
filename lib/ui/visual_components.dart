import 'package:flutter/material.dart';
import '../models/simulation_models.dart';

// --- 1. ELECTRICAL GRID PAINTER ---
class NetworkGridPainter extends CustomPainter {
  final List<Offset> ngoPositions;
  final Offset dbPosition;
  final double pulseValue; // 0.0 to 1.0 (Animation progress)
  final bool isBroadcasting;

  NetworkGridPainter({
    required this.ngoPositions,
    required this.dbPosition,
    required this.pulseValue,
    required this.isBroadcasting,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // A. Draw Passive Lines (Dim Connections)
    final passivePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 2;

    for (var pos in ngoPositions) {
      canvas.drawLine(dbPosition, pos, passivePaint);
    }

    // B. Draw Active Electrical Surge (Bright Pulse)
    if (isBroadcasting) {
      final activePaint = Paint()
        ..color = Colors.cyanAccent.withValues(alpha: 0.9 * (1 - pulseValue)) // Fades out at end
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke;

      for (var pos in ngoPositions) {
        // Calculate the segment to draw based on pulseValue
        double dx = pos.dx - dbPosition.dx;
        double dy = pos.dy - dbPosition.dy;

        // Start and end points of the "electricity" packet on the wire
        Offset start = Offset(
            dbPosition.dx + (dx * pulseValue),
            dbPosition.dy + (dy * pulseValue)
        );

        Offset end = Offset(
            dbPosition.dx + (dx * (pulseValue + 0.15)),
            dbPosition.dy + (dy * (pulseValue + 0.15))
        );

        canvas.drawLine(start, end, activePaint);

        // Draw glowing head of the electricity
        canvas.drawCircle(end, 6, Paint()..color = Colors.white);
        canvas.drawCircle(end, 10, Paint()..color = Colors.cyanAccent.withValues(alpha: 0.3));
      }
    }
  }

  @override
  bool shouldRepaint(covariant NetworkGridPainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue || oldDelegate.isBroadcasting != isBroadcasting;
  }
}

// --- 2. NODE WIDGET ---
class NodeWidget extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isSmall;
  final bool isActive; // Used for "Logged In" NGO highlight

  const NodeWidget({
    super.key,
    required this.icon,
    required this.label,
    this.color = Colors.white,
    this.isSmall = false,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: EdgeInsets.all(isSmall ? 15 : 25),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            shape: BoxShape.circle,
            // Active nodes get a bright yellow glow
            border: Border.all(
                color: isActive ? Colors.yellowAccent : color.withValues(alpha: 0.8),
                width: isActive ? 4 : 2
            ),
            boxShadow: [
              BoxShadow(
                  color: (isActive ? Colors.yellowAccent : color).withValues(alpha: 0.4),
                  blurRadius: isActive ? 40 : 20
              )
            ],
          ),
          child: Icon(
              icon,
              color: isActive ? Colors.yellowAccent : color,
              size: isSmall ? 24 : 40
          ),
        ),
        const SizedBox(height: 10),
        Text(
            label,
            style: TextStyle(
                color: Colors.white70,
                fontSize: isSmall ? 10 : 12,
                fontFamily: 'monospace'
            )
        ),
      ],
    );
  }
}

// --- 3. PACKET WIDGET ---
class PacketWidget extends StatelessWidget {
  final DataPacket packet;
  final Offset dbPos;
  final Offset donorPos;
  final List<Offset> ngoPositions;
  final Offset? gaPos; // Optional: Only needed if sending analytics

  const PacketWidget({
    super.key,
    required this.packet,
    required this.dbPos,
    required this.donorPos,
    required this.ngoPositions,
    this.gaPos,
  });

  @override
  Widget build(BuildContext context) {
    double left = 0, top = 0;

    // --- CASE A: Server <-> Donor Flight ---
    if (packet.destination == PacketDestination.server) {
      if (packet.isReturning) {
        // Flight: DB -> Donor (Right to Left)
        double p = (packet.progress - 0.5) * 2;
        left = dbPos.dx - (p * (dbPos.dx - donorPos.dx));
        top = dbPos.dy - (p * (dbPos.dy - donorPos.dy));
      } else {
        // Flight: Donor -> DB (Left to Right)
        double p = packet.progress * 2;
        left = donorPos.dx + (p * (dbPos.dx - donorPos.dx));
        top = donorPos.dy + (p * (dbPos.dy - donorPos.dy));
      }
    }
    // --- CASE B: NGO -> Server (Claim Request) ---
    else if (packet.destination == PacketDestination.ngo_to_server) {
      // Flight: Specific NGO -> DB
      Offset start = ngoPositions[packet.sourceIndex ?? 0];
      double p = packet.progress * 2; // Normalizing 0.0-0.5 to 0.0-1.0

      left = start.dx + (p * (dbPos.dx - start.dx));
      top = start.dy + (p * (dbPos.dy - start.dy));
    }
    // --- CASE C: Server -> Analytics (Google Analytics) ---
    else if (packet.destination == PacketDestination.analytics && gaPos != null) {
      // Flight: DB -> Top Right GA Node
      Offset start = dbPos;
      double p = packet.progress; // Uses full 0.0-1.0 range

      left = start.dx + (p * (gaPos!.dx - start.dx));
      top = start.dy + (p * (gaPos!.dy - start.dy));
    }
    // --- CASE D: Broadcast (Invisible Packet) ---
    else {
      // Broadcasts are handled visually by the NetworkGridPainter lines
      return Container();
    }

    // Error State Indicator
    if (packet.isError) {
      return Positioned(
          left: left - 20, top: top - 20,
          child: const Icon(Icons.error, color: Colors.red, size: 40)
      );
    }

    // Render the Packet
    return Positioned(
      left: left, top: top,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
            color: packet.color,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: packet.color.withValues(alpha: 0.8), blurRadius: 10)
            ]
        ),
        child: Text(
            packet.label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black
            )
        ),
      ),
    );
  }
}