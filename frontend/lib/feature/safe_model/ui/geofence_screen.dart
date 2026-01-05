import 'package:flutter/material.dart';
import 'package:frontend/core/app/services/location/geofence_detector.dart';
import 'package:frontend/core/app/services/location/geofence_storage.dart';
import 'package:frontend/feature/common/common_toast.dart';
import 'package:frontend/core/app/services/location/location_manager.dart';
import 'package:frontend/core/app/services/location/location_repository.dart';
import 'package:frontend/core/constants/colors.dart';

class GeofenceScreen extends StatefulWidget {
  const GeofenceScreen({super.key});

  @override
  State<GeofenceScreen> createState() => _GeofenceScreenState();
}

class _GeofenceScreenState extends State<GeofenceScreen> {
  List<Geofence> _geofences = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGeofences();
  }

  Future<void> _loadGeofences() async {
    setState(() => _isLoading = true);
    final list = await GeofenceStorage.loadGeofences();
    setState(() {
      _geofences = list;
      _isLoading = false;
    });
  }

  Future<void> _addGeofence(String name, double radius) async {
    final pos = locationRepository.last;
    if (pos == null) {
      CommonToast.show(context, "Location not available yet", isError: true);
      return;
    }

    final geofence = Geofence(
      id: name,
      latitude: pos.lat,
      longitude: pos.lng,
      radiusMeters: radius,
    );

    await LocationManager().addGeofence(geofence);
    _loadGeofences();
  }

  Future<void> _removeGeofence(String id) async {
    await LocationManager().removeGeofence(id);
    _loadGeofences();
  }

  void _showAddDialog() {
    final nameController = TextEditingController();
    double radius = 100;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Add Geofence"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Name (ID)"),
              ),
              const SizedBox(height: 16),
              Text("Radius: ${radius.toInt()}m"),
              Slider(
                value: radius,
                min: 50,
                max: 1000,
                divisions: 19,
                label: "${radius.toInt()}m",
                activeColor: AppColors.primaryColor,
                onChanged: (val) => setState(() => radius = val),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  _addGeofence(nameController.text, radius);
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text("Add"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Geofences"),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _geofences.isEmpty
              ? const Center(child: Text("No geofences set"))
              : ListView.builder(
                  itemCount: _geofences.length,
                  itemBuilder: (context, index) {
                    final g = _geofences[index];
                    return Dismissible(
                      key: Key(g.id),
                      background: Container(color: Colors.red),
                      onDismissed: (_) => _removeGeofence(g.id),
                      child: ListTile(
                        leading: const Icon(Icons.location_on,
                            color: AppColors.primaryColor),
                        title: Text(g.id),
                        subtitle: Text(
                            "Lat: ${g.latitude.toStringAsFixed(4)}, Lng: ${g.longitude.toStringAsFixed(4)}\nRadius: ${g.radiusMeters.toInt()}m"),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeGeofence(g.id),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
