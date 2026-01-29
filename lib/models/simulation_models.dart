import 'package:flutter/material.dart';

enum PacketType { auth, data, broadcast, claim, error, analytics } // Added analytics
enum PacketDestination { server, analytics, ngo_client, ngo_to_server }

class DataPacket {
  final String id;
  final String label;
  final Color color;
  final PacketType type;
  final PacketDestination destination;
  final int? sourceIndex;

  double progress;
  bool isReturning;
  bool isGhost;
  bool isError;
  String? payload;

  DataPacket({
    required this.id,
    required this.label,
    required this.color,
    required this.type,
    this.destination = PacketDestination.server,
    this.sourceIndex,
    this.progress = 0.0,
    this.isReturning = false,
    this.isGhost = false,
    this.isError = false,
    this.payload,
  });
}

class DonationItem {
  final String id;
  final String foodItem;
  final String quantity;
  final String donorName;
  String status;
  String? eta;
  String? claimedBy;

  DonationItem({
    required this.id,
    required this.foodItem,
    required this.quantity,
    required this.donorName,
    this.status = 'Available',
    this.eta,
    this.claimedBy,
  });

  factory DonationItem.fromJson(Map<String, dynamic> json) {
    return DonationItem(
      id: json['id'],
      foodItem: json['food_item'] ?? 'Unknown',
      quantity: json['quantity'] ?? '0',
      donorName: 'Donor',
      status: json['status'] ?? 'Available',
      eta: json['eta'],
      claimedBy: json['claimed_by'],
    );
  }
}