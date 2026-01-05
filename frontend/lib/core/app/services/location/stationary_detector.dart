import 'package:geolocator/geolocator.dart';

class StationaryDetector {
  final double radiusMeters;
  final Duration level1Duration;
  final Duration level2Duration;
  final Duration level3Duration;
  final Duration level4Duration;

  Position? _anchor;
  DateTime? _anchorTime;
  int _alertLevel = 0; // 0: No alert, 1-4: Alert levels

  StationaryDetector({
    this.radiusMeters = 50,
    this.level1Duration = const Duration(minutes: 2),
    this.level2Duration = const Duration(minutes: 3),
    this.level3Duration = const Duration(minutes: 4),
    this.level4Duration = const Duration(minutes: 5),
  });

  void reset() {
    _anchor = null;
    _anchorTime = null;
    _alertLevel = 0;
    print("StationaryDetector: Manually reset.");
  }

  /// Returns the current alert level (0 if no new alert)
  /// If it returns > 0, it means we just crossed a threshold for that level.
  int check(Position current) {
    if (_anchor == null) {
      _anchor = current;
      _anchorTime = DateTime.now();
      _alertLevel = 0;
      return 0;
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

      if (_alertLevel < 1 && diff >= level1Duration) {
        _alertLevel = 1;
        return 1;
      } else if (_alertLevel < 2 && diff >= level2Duration) {
        _alertLevel = 2;
        return 2;
      } else if (_alertLevel < 3 && diff >= level3Duration) {
        _alertLevel = 3;
        return 3;
      } else if (_alertLevel < 4 && diff >= level4Duration) {
        _alertLevel = 4;
        return 4;
      }
      return 0;
    } else {
      print("Stationary check: MOVED dist=${dist.toStringAsFixed(2)}m. Resetting anchor.");
      _anchor = current;
      _anchorTime = DateTime.now();
      _alertLevel = 0;
      return 0;
    }
  }
}
