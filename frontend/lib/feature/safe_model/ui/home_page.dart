import 'dart:async';

import 'package:flutter/material.dart';
import 'package:frontend/feature/common/app_drawer.dart';
import 'package:frontend/core/constants/colors.dart';
import 'package:frontend/feature/history/ui/history_screen.dart';
import 'package:frontend/feature/history/data/history_repository.dart';
import 'package:frontend/feature/history/data/trip_model.dart';
import 'package:uuid/uuid.dart';
import 'package:frontend/core/app/services/location/location_manager.dart';
import 'package:frontend/core/app/services/location/location_repository.dart';
import 'package:frontend/core/app/services/location/position_model.dart';
import 'package:frontend/core/app/services/location/places_service.dart';
import 'package:frontend/feature/common/common_toast.dart';
import 'package:frontend/feature/common/common_app_bar.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:frontend/core/app/services/location/routing_service.dart';
import 'geofence_screen.dart';
import 'map_controller.dart';
import 'package:share_plus/share_plus.dart';
import 'package:frontend/core/app/services/alert_service.dart';
import 'package:frontend/core/shared_preferences/local_storage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final controller = LiveMapController();
  bool mapReady = false;
  bool isSafeMode = false;
  final HistoryRepository _historyRepository = HistoryRepository();

  LatLng? _destination;
  List<LatLng> _routePoints = [];
  bool _isTravelMode = false;
  bool _isLoadingRoute = false;
  bool _isDialogVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initLocationServices();
    
    // Listen for location updates to update camera and marker
    _locationSubscription = locationRepository.stream.listen((pos) {
      if (mounted) {
        if (mapReady) {
          controller.updateUserMarker(pos);
          controller.moveCamera(pos);
        }
        setState(() {}); // Trigger rebuild to show updated marker or switch view
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _initLocationServices();
    }
  }

  Future<void> _initLocationServices() async {
    // Check current service status instead of forcing stop
    await _checkServiceStatus();

    LocationManager().startForegroundTracking();

    LocationManager().foregroundStream.listen((pos) {
      print("Foreground pos: ${pos.latitude}, ${pos.longitude}");
    });

    // Listen for Stationary Alerts
    LocationManager().stationaryAlertStream.listen((level) {
      if (mounted && level > 0 && level <= 4) {
        _showStationaryDialog(level);
      }
    });
  }

  void _showStationaryDialog(int level) {
    // Dismiss any existing dialogs if needed (optional, but good practice)
    // For simplicity, we just show a new one. 
    // In a real app, we might want to manage dialog state to avoid stacking.
    
    // If a dialog is already visible, close it first to show the new one (or update it)
    if (_isDialogVisible && mounted) {
      Navigator.of(context).pop();
      _isDialogVisible = false;
    }

    _isDialogVisible = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(level == 1 ? "Are you okay?" : "Safety Check (Level $level)"),
        content: Text(
          level == 1
              ? "You've been stationary for a while."
              : "Still stationary. SOS will be triggered soon!",
        ),
        actions: [
          TextButton(
            onPressed: () {
              LocationManager().resetStationary();
              Navigator.of(context).pop();
              _isDialogVisible = false;
            },
            child: const Text("I'm Safe"),
          ),
        ],
      ),
    );
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

  Future<void> _onMapTap(LatLng latLng) async {
    if (_isTravelMode) return; // Don't change dest while traveling
    if (locationRepository.last == null) return;

    if (isSafeMode) {
      CommonToast.show(context, "Disable Safe Mode to select a destination.", isError: true);
      return;
    }

    setState(() {
      _destination = latLng;
      _isLoadingRoute = true;
      _routePoints = [];
      // Clear search text initially or set to "Loading..."
      _searchController.text = "Fetching address...";
    });

    // 1. Fetch Address (Reverse Geocoding)
    final address = await _placesService.getAddressFromLatLng(latLng);
    if (mounted && address != null) {
      setState(() {
        _searchController.text = address;
      });
    }

    final origin = LatLng(
      locationRepository.last!.lat,
      locationRepository.last!.lng,
    );
    print("MapScreen: Requesting route...");

    try {
      final route = await RoutingService().getRoute(origin, latLng);
      print("MapScreen: Route received with ${route.length} points");

      if (mounted) {
        setState(() {
          _routePoints = route;
          _isLoadingRoute = false;
        });
      }
    } catch (e) {
      print("MapScreen: Error fetching route: $e");
      if (mounted) {
        setState(() {
          _isLoadingRoute = false;
          _routePoints = [];
        });
        CommonToast.show(context, "Route Error: ${e.toString().replaceAll('Exception: ', '')}", isError: true);
      }
    }
  }

  void _startTravel() {
    if (_destination == null) return;

    if (_routePoints.isEmpty) {
      CommonToast.show(context, "Wait for route to load or try selecting destination again.", isError: true);
      return;
    }

    setState(() => _isTravelMode = true);

    LocationManager().startTravel(_routePoints);

    // Save Trip to History
    final trip = TripModel(
      id: const Uuid().v4(),
      destinationName: _searchController.text.isNotEmpty
          ? _searchController.text
          : "Unknown Destination",
      destinationLat: _destination!.latitude,
      destinationLng: _destination!.longitude,
      startTime: DateTime.now(),
    );
    _historyRepository.saveTrip(trip);

    // Also ensure background tracking is ON for travel
    if (!isSafeMode) {
      _toggleSafeMode(true);
    }
  }

  Future<void> _confirmStopTravel() async {
    final shouldStop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("End Trip?"),
        content: const Text("Are you sure you want to stop navigation?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("End Trip"),
          ),
        ],
      ),
    );

    if (shouldStop == true) {
      _stopTravel();
    }
  }

  Future<void> _confirmDisableSafeMode() async {
    final shouldDisable = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Disable Safe Mode?"),
        content: const Text("Are you sure you want to turn off background tracking?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Turn Off"),
          ),
        ],
      ),
    );

    if (shouldDisable == true) {
      _toggleSafeMode(false);
    }
  }

  void _stopTravel() {
    setState(() {
      _isTravelMode = false;
      _destination = null;
      _routePoints = [];
    });
    LocationManager().stopTravel();
    _toggleSafeMode(false); // Turn off Safe Mode (background tracking)
  }

  void _clearSelection() {
    setState(() {
      _destination = null;
      _routePoints = [];
      _searchController.clear();
      _predictions = [];
    });
  }

  Future<void> _shareLocation() async {
    final pos = locationRepository.last;
    if (pos == null) {
      CommonToast.show(context, "Location not available yet.", isError: true);
      return;
    }

    String link = "https://www.google.com/maps/search/?api=1&query=${pos.lat},${pos.lng}";
    String message = "Here is my current location: $link";

    if (_isTravelMode && _destination != null) {
       message = "I'm traveling! Track my location: $link";
       if (_searchController.text.isNotEmpty) {
         message += "\nDestination: ${_searchController.text}";
       }
    }

    await Share.share(message);
  }

  StreamSubscription<PositionModel>? _locationSubscription;

  @override
  void dispose() {
    print("MapScreen: dispose called");
    WidgetsBinding.instance.removeObserver(this);
    _locationSubscription?.cancel();
    LocationManager().stopForegroundTracking();
    LocationManager().stopBackgroundTracking();
    super.dispose();
  }

  List<Map<String, dynamic>> _predictions = [];
  final TextEditingController _searchController = TextEditingController();
  final PlacesService _placesService = PlacesService();

  void _onSearchChanged(String query) async {
    if (query.isEmpty) {
      setState(() => _predictions = []);
      return;
    }
    final results = await _placesService.getAutocomplete(query);
    if (mounted) {
      setState(() => _predictions = results);
    }
  }

  void _onPredictionSelected(Map<String, dynamic> prediction) async {
    setState(() {
      _predictions = [];
      _searchController.text = prediction['description'];
      FocusScope.of(context).unfocus();
    });

    final latLng = await _placesService.getPlaceDetails(prediction['place_id']);
    if (latLng != null) {
      _onMapTap(latLng); // Reuse existing logic

      // Move camera to new destination
      if (mapReady) {
        controller.moveCamera(PositionModel(latLng.latitude, latLng.longitude));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: _isTravelMode ? "Travel Mode" : "SafeShift",
        showBack: false,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(
              _isTravelMode ? Icons.arrow_back_ios_new : Icons.menu_rounded,
              color: AppColors.primaryColor,
            ),
            onPressed: () {
              if (_isTravelMode) {
                _confirmStopTravel();
              } else {
                Scaffold.of(context).openDrawer();
              }
            },
          ),
        ),
      ),
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          // 1. Full Screen Map
          locationRepository.hasValue
              ? _buildStream(locationRepository.last!)
              : FutureBuilder<PositionModel>(
                  future: locationRepository.getLastLocation(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text("Error: ${snapshot.error}"));
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return _buildStream(snapshot.data!);
                  },
                ),

          // 3. Bottom Panel
          Positioned(bottom: 0, left: 0, right: 0, child: _buildBottomPanel()),
        ],
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            spreadRadius: 2,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),

          if (_isTravelMode) ...[
            // TRAVEL MODE VIEW
            Row(
              children: [
                const Icon(Icons.navigation, color: Colors.blue, size: 30),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Navigating to",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      Text(
                        "Destination", // Could be dynamic if we stored the name
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: _confirmStopTravel,
                ),
              ],
            ),
            const SizedBox(height: 10),
            const LinearProgressIndicator(), // Mock progress
          ] else ...[
            // NORMAL MODE & PRE-TRAVEL MODE

            // Search Bar
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: "Where to?",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _predictions = []);
                        },
                      )
                    : null,
              ),
            ),

            // Predictions List
            if (_predictions.isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxHeight: 150),
                margin: const EdgeInsets.only(top: 10),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _predictions.length,
                  itemBuilder: (context, index) {
                    final pred = _predictions[index];
                    return ListTile(
                      leading: const Icon(
                        Icons.location_on,
                        color: Colors.grey,
                      ),
                      title: Text(pred['description']),
                      onTap: () => _onPredictionSelected(pred),
                    );
                  },
                ),
              ),
            SizedBox(height: 20),

            // Quick Actions (Always visible unless in Travel Mode)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildQuickAction(
                  icon: isSafeMode ? Icons.shield : Icons.shield_outlined,
                  label: isSafeMode ? "Safe Mode ON" : "Safe Mode",
                  color: isSafeMode ? Colors.green : Colors.grey,
                  onTap: () {
                    if (_destination != null) {
                       CommonToast.show(context, "Clear destination to toggle Safe Mode.", isError: true);
                    } else {
                      if (isSafeMode) {
                        _confirmDisableSafeMode();
                      } else {
                        _toggleSafeMode(true);
                      }
                    }
                  },
                ),
                _buildQuickAction(
                  icon: Icons.share_location,
                  label: "Share",
                  color: Colors.blue,
                  onTap: _shareLocation,
                ),
                _buildQuickAction(
                  icon: Icons.grid_view_rounded,
                  label: "More",
                  color: Colors.orange,
                  onTap: _showMoreOptions,
                ),
              ],
            ),

            // Start Travel Button (Only if destination selected)
            if (_destination != null && _predictions.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSafeMode ? null : _startTravel,
                    // Disable if Safe Mode is ON
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSafeMode ? Colors.grey : Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isSafeMode
                          ? "Disable Safe Mode to Travel"
                          : "Start Travel",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
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



  // ... (existing _initLocationServices and other methods)

  Widget _buildMap(PositionModel pos) {
    // Note: Camera updates are now handled in the stream listener
    
    Set<Marker> markers = {
      if (controller.userMarker != null) controller.userMarker!,
    };

    if (_destination != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('dest'),
          position: _destination!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          onTap: _clearSelection,
        ),
      );
    }

    Set<Polyline> polylines = {};
    if (_routePoints.isNotEmpty) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: _routePoints,
          color: Colors.blue,
          width: 5,
        ),
      );
    } else if (_destination != null) {
      // Fallback to straight line if route fetch failed or pending
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route_straight'),
          points: [LatLng(pos.lat, pos.lng), _destination!],
          color: Colors.grey,
          width: 2,
          patterns: [PatternItem.dash(10), PatternItem.gap(10)],
        ),
      );
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
      onTap: _onMapTap,
      markers: markers,
      polylines: polylines,
    );
  }

  void _showMoreOptions() {
    // Capture the parent context (HomePage's context)
    final parentContext = context;
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "More Options",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.history, color: Colors.orange),
                title: const Text("History"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    parentContext, // Use parentContext for navigation
                    MaterialPageRoute(
                      builder: (context) => const HistoryScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.sos, color: Colors.red),
                title: const Text("SOS Alert"),
                onTap: () async {
                  Navigator.pop(context); // Pop the sheet
                  
                  // Use parentContext for Toast since 'context' (sheet) is deactivated
                  CommonToast.show(parentContext, "Sending SOS...", isError: false);
                  
                  final result = await AlertService().sendWhatsAppSOS();
                  
                  if (mounted) {
                     CommonToast.show(parentContext, "SOS Status: $result", isError: false);
                  }
                },
              ),
              // ListTile(
              //   leading: const Icon(Icons.security, color: Colors.blueGrey),
              //   title: const Text("Geofencing"),
              //   onTap: () {
              //     Navigator.pop(context);
              //     Navigator.push(
              //       parentContext,
              //       MaterialPageRoute(
              //         builder: (context) => const GeofenceScreen(),
              //       ),
              //     );
              //   },
              // ),
            ],
          ),
        );
      },
    );
  }
}
