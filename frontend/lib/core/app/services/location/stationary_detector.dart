import 'package:geolocator/geolocator.dart';

class StationaryDetector {
  final double radiusMeters;
  final Duration firstAlertDuration;
  final Duration secondAlertDuration;
  final Duration thirdAlertDuration;

  Position? _anchor;
  DateTime? _anchorTime;
  int _alertLevel = 0; // 0: No alert, 1: First sent, 2: Second sent, 3: Third sent

  StationaryDetector({
    this.radiusMeters = 50,
    this.firstAlertDuration = const Duration(minutes: 5),
    this.secondAlertDuration = const Duration(minutes: 6),
    this.thirdAlertDuration = const Duration(minutes: 7),
  });

  bool check(Position current) {
    if (_anchor == null) {
      _anchor = current;
      _anchorTime = DateTime.now();
      _alertLevel = 0;
      return false;
    }

    final dist = Geolocator.distanceBetween(
      _anchor!.latitude,
      _anchor!.longitude,
      current.latitude,
      current.longitude,
    );

    if (dist <= radiusMeters) {
      final diff = DateTime.now().difference(_anchorTime!);
      print("Stationary check: dist=${dist.toStringAsFixed(2)}m, time=${diff.inSeconds}s, level=$_alertLevel");

      if (_alertLevel == 0 && diff >= firstAlertDuration) {
        _alertLevel = 1;
        return true;
      } else if (_alertLevel == 1 && diff >= secondAlertDuration) {
        _alertLevel = 2;
        return true;
      } else if (_alertLevel == 2 && diff >= thirdAlertDuration) {
        _alertLevel = 3;
        return true;
      }
      return false;
    } else {
      print("Stationary check: MOVED dist=${dist.toStringAsFixed(2)}m. Resetting anchor.");
      _anchor = current;
      _anchorTime = DateTime.now();
      _alertLevel = 0;
      return false;
    }
  }
}
