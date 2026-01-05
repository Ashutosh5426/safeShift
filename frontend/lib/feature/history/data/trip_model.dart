import 'dart:convert';

class TripModel {
  final String id;
  final String destinationName;
  final double destinationLat;
  final double destinationLng;
  final DateTime startTime;
  final DateTime? endTime;

  TripModel({
    required this.id,
    required this.destinationName,
    required this.destinationLat,
    required this.destinationLng,
    required this.startTime,
    this.endTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'destinationName': destinationName,
      'destinationLat': destinationLat,
      'destinationLng': destinationLng,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
    };
  }

  factory TripModel.fromMap(Map<String, dynamic> map) {
    return TripModel(
      id: map['id'],
      destinationName: map['destinationName'],
      destinationLat: map['destinationLat'],
      destinationLng: map['destinationLng'],
      startTime: DateTime.parse(map['startTime']),
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory TripModel.fromJson(String source) => TripModel.fromMap(json.decode(source));
}
