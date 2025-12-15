import 'package:latlong2/latlong.dart';

enum EquipmentType { hauler, excavator, dozer, grader, fuel }

enum AssetStatus { active, operating, hold, inactive }

class Asset {
  final String id;
  final String name;
  final EquipmentType type;
  final AssetStatus status;
  final LatLng position;
  final String site;
  final String block;
  final String pit;
  final String? operator;
  final DateTime lastUpdated;

  Asset({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.position,
    required this.site,
    required this.block,
    required this.pit,
    this.operator,
    required this.lastUpdated,
  });

  String get statusText {
    switch (status) {
      case AssetStatus.active:
        return 'Active';
      case AssetStatus.operating:
        return 'Operating';
      case AssetStatus.hold:
        return 'Hold';
      case AssetStatus.inactive:
        return 'Inactive';
    }
  }

  String get typeText {
    switch (type) {
      case EquipmentType.hauler:
        return 'Hauler';
      case EquipmentType.excavator:
        return 'Excavator';
      case EquipmentType.dozer:
        return 'Dozer';
      case EquipmentType.grader:
        return 'Grader';
      case EquipmentType.fuel:
        return 'Fuel';
    }
  }
}

class TaskHistory {
  final String id;
  final DateTime date;
  final String shift;
  final String operator;
  final String activity;
  final String site;
  final String block;
  final String pit;
  final String origin;
  final String destination;

  TaskHistory({
    required this.id,
    required this.date,
    required this.shift,
    required this.operator,
    required this.activity,
    required this.site,
    required this.block,
    required this.pit,
    required this.origin,
    required this.destination,
  });
}

class AssetTrackingPoint {
  final String id;
  final DateTime timestamp;
  final LatLng position;
  // final double speed; // km/h
  final String status;

  const AssetTrackingPoint({
    required this.id,
    required this.timestamp,
    required this.position,
    // required this.speed,
    required this.status,
  });
}
