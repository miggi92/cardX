import 'package:flutter/material.dart';

enum PackType { club, sport, league }

class PackModel {
  final String id;
  final String name;
  final int price;
  final PackType type;
  final String filterValue;
  final String? logoUrl;
  final List<Color> gradientColors;

  const PackModel({
    required this.id,
    required this.name,
    required this.price,
    required this.type,
    required this.filterValue,
    this.logoUrl,
    required this.gradientColors,
  });
}
