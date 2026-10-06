import 'package:flutter/material.dart';

class ModuleInfo {
  final String id;
  final String name;
  final String description;
  final String category;
  final bool isRequired;
  bool isEnabled;
  final IconData icon;
  final Color iconColor;

  ModuleInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.isRequired,
    required this.isEnabled,
    required this.icon,
    required this.iconColor,
  });
}
