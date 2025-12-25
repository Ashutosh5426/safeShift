import 'package:flutter/material.dart';
import 'package:frontend/core/app/services/location/location_manager.dart';
import 'package:frontend/core/app/services/location/location_repository.dart';
import 'package:frontend/core/app/services/location/position_model.dart';
import 'package:frontend/feature/common/common_app_bar.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'map_controller.dart';

class MapScreen extends StatefulWidget {
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final controller = LiveMapController();
  bool mapReady = false;
  bool isSafeMode = false;

  @override
  void initState() {
    super.initState();
    _checkServiceStatus();

    LocationManager().startForegroundTracking();

    LocationManager().foregroundStream.listen((pos) {
      print("Foreground pos: ${pos.latitude}, ${pos.longitude}");
    });
  }

  Future<void> _checkServiceStatus() async {
    final running = await LocationManager().isServiceRunning();
    if (mounted) {
      setState(() {
        isSafeMode = running;
      });
    }
  }

  Future<void> _toggleSafeMode(bool value) async {
    if (value) {
      await LocationManager().startBackgroundTracking();
    } else {
      await LocationManager().stopBackgroundTracking();
    }
    
    // Give service a moment to update state
    await Future.delayed(const Duration(milliseconds: 500));
    await _checkServiceStatus();
  }

  @override
  void dispose() {
    print("MapScreen: dispose called");
    LocationManager().stopForegroundTracking();
    LocationManager().stopBackgroundTracking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Live Location"),
        actions: [
          Row(
            children: [
              const Text("Safe Mode", style: TextStyle(fontSize: 14)),
              Switch(
                value: isSafeMode,
                onChanged: _toggleSafeMode,
                activeColor: Colors.redAccent,
              ),
              const SizedBox(width: 8),
            ],
          )
        ],
      ),
      body: locationRepository.hasValue
          ? _buildStream(locationRepository.last!)
          : FutureBuilder<PositionModel>(
              future: locationRepository.getLastLocation(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Error getting location"),
                        Text(snapshot.error.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red)),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {});
                          },
                          child: const Text("Retry"),
                        )
                      ],
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return _buildStream(snapshot.data!);
              },
            ),
    );
  }

  Widget _buildStream(PositionModel initial) {
    return StreamBuilder<PositionModel>(
      initialData: initial,
      stream: locationRepository.stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return _buildMap(snapshot.data!);
      },
    );
  }

  Widget _buildMap(PositionModel pos) {
    // Update marker ONLY after controller exists
    if (mapReady) {
      controller.updateUserMarker(pos);
      controller.moveCamera(pos);
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(pos.lat, pos.lng),
        zoom: 16,
      ),
      onMapCreated: (gmController) {
        controller.init(gmController);
        setState(() => mapReady = true);
      },
      markers: {
        if (controller.userMarker != null) controller.userMarker!,
      },
    );
  }
}
