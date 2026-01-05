import 'dart:async';
import 'package:frontend/core/app/services/location/position_model.dart';
import 'package:geolocator/geolocator.dart';

class LocationRepository {
  final _controller = StreamController<PositionModel>.broadcast();

  PositionModel? _last;

  Stream<PositionModel> get stream => _controller.stream;

  /// Emit new position to the stream + cache it
  void emit(Position position) {
    final model = PositionModel(position.latitude, position.longitude);
    _last = model;
    _controller.add(model);
  }

  /// Returns last cached location (used by FutureBuilder for initial map position)
  Future<PositionModel> getLastLocation() async {
    if (_last != null) return _last!;

    /// If no cached value yet → try getting device location directly.
    final pos = await Geolocator.getCurrentPosition();
    _last = PositionModel(pos.latitude, pos.longitude);
    return _last!;
  }

  bool get hasValue => _last != null;

  PositionModel? get last => _last;

  void dispose() {
    _controller.close();
  }
}

final locationRepository = LocationRepository();
